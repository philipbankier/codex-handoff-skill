# Momentum Trader — Design Specification

**Date:** 2026-03-12
**Status:** Approved

## Overview

An event-driven momentum trading system that combines market data, social media sentiment, and NLP-powered geopolitical event detection to trade US equities and crypto. The system operates on two timeframes: fast intraday reaction to geopolitical events and a slower daily/weekly momentum portfolio.

### Key Decisions

- **Asset classes:** US equities + crypto
- **Timeframe:** Hybrid — intraday event reaction + daily/weekly momentum
- **Execution:** Alpaca paper trading (live is a config switch)
- **NLP primary:** GPT-5.2 via Codex CLI (`codex exec --output-schema`)
- **NLP fallback:** Local Ollama multimodal model (pre-installed)
- **Social data:** Apify (Twitter/X + Reddit scrapers)
- **News data:** Finnhub + MarketAux + RSS feeds (all free tier)
- **Macro data:** FRED API (free) + Fear/Greed indices (free)
- **Storage:** Redis Streams (hot) + DuckDB (cold/analytical)
- **Language:** Python core + TypeScript (Next.js dashboard)
- **Target hardware:** M3 MacBook Pro, 36GB RAM

---

## 1. System Architecture

Event-driven microservices connected via Redis Streams. Each service runs independently at its own cadence.

```
DATA LAYER → NLP ENGINE → SIGNAL LAYER → PORTFOLIO/EXECUTION → MONITORING
     ↓            ↓             ↓                ↓                  ↓
  raw.*      events.*       signals.*        orders.*          dashboard
             sentiment.*                     fills.*
                                             regime.*
```

### Layers

1. **Data Collectors** — 8 independent workers ingesting from Apify, Finnhub, MarketAux, RSS, Google Trends, Alpaca, FRED, and Fear/Greed APIs
2. **NLP Engine** — Preprocessor with urgency triage, Codex CLI (primary), Ollama multimodal (fallback)
3. **Signal Generator** — Fast Signal Engine (event-driven) + Momentum Signal Engine (daily/weekly) + Regime Detector
4. **Portfolio Manager** — 5-layer position sizing, ATR trailing stops, correlation-aware limits, drawdown circuit breaker
5. **Executor** — Alpaca order routing (equities + crypto), fill tracking, reconciliation
6. **Dashboard** — Next.js TypeScript app with positions, P&L, signals, sentiment, event log, backtest replay
7. **Storage** — Redis (hot, 24h) → DuckDB (cold, indefinite) via drain worker

---

## 2. Data Collectors

### 2a. Apify Social Media Collector

- **Schedule:** Every 5 minutes
- **Stream:** `raw.social`
- **Twitter/X:** Search cashtags ($SPY, $QQQ, $BTC, $ETH + watchlist), geopolitical keywords (tariff, sanctions, war, fed rate, OPEC), engagement metrics
- **Reddit:** r/wallstreetbets, r/stocks, r/CryptoCurrency, r/geopolitics. Sort by hot + new. Collect title, body, score, comment count
- **Output schema:** Normalized `SocialPost` with text, timestamp, source, engagement metrics

### 2b. Finnhub News + Market Data

- **Schedule:** 60s (news), 15s (prices during market hours)
- **Streams:** `raw.news`, `raw.prices`
- **News:** `/news?category=general` + `/company-news` for watchlist
- **Prices:** `/quote` for equities, `/crypto/candle` for crypto
- **Computed indicators:** RSI(14), EMA(12/26), MACD, Bollinger Bands, ATR(14)

### 2c. MarketAux News

- **Schedule:** Every 2 minutes
- **Stream:** `raw.news`
- **Search by:** Entity names (countries, leaders, institutions)
- **Filter:** Relevance score > 0.7
- **Purpose:** Broader international coverage Finnhub may miss

### 2d. RSS Feed Collector

- **Schedule:** Every 60 seconds
- **Stream:** `raw.news`
- **Sources:** Reuters (World, Business), CNBC (Top, World), White House press releases, USTR (tariffs), Federal Reserve, CoinDesk
- **Library:** `feedparser`
- **Deduplication:** `hash(title + source)` to prevent duplicate stories

### 2e. Google Trends

- **Schedule:** Every 30 minutes (rate limit sensitive)
- **Stream:** `raw.trends`
- **Library:** `pytrends`
- **Keywords:** Watchlist tickers + "stock market crash", "tariff", "sanctions", "recession", "bitcoin crash", "fed rate cut"
- **Purpose:** Confirmation signal, not primary
- **Staleness handling:** If `trend_momentum` data is older than 6 hours, set `trends_weight = 0` and redistribute weight proportionally to the remaining momentum components. Log and alert on this condition. Never silently use stale trend data.

### 2f. Alpaca Price Data + VIX

- **Schedule:** WebSocket streaming (equities during 24/5 window), REST polling 60s (crypto 24/7)
- **Stream:** `raw.prices`
- **Data:** Real-time quotes, daily bars, account positions, P&L
- **VIX:** Fetch CBOE VIX via `yfinance` (`^VIX`) every 60 seconds during market hours, every 15 minutes outside hours. Publish to `raw.prices` with ticker `$VIX`. This is the regime detector's top-weighted input (25%).
- **Note:** Alpaca 24/5 extended hours (Sun 8PM–Fri 8PM ET) enables overnight equity trading

### 2g. FRED Macro Indicators

- **Schedule:** Daily at 4:00 PM ET
- **Stream:** `raw.macro`
- **Library:** `fredapi`
- **Series:** T10Y2Y (yield curve), SAHMREALTIME (recession indicator), UNRATE, CPIAUCSL, DFF (fed funds rate)

### 2h. Fear & Greed Indices

- **Schedule:** Every 4 hours
- **Stream:** `raw.sentiment`
- **Sources:** CNN Fear & Greed Index (equities), Alternative.me Crypto Fear & Greed (free API)
- **Purpose:** Contrarian overlay for position sizing + regime detection

---

## 3. NLP Engine

### 3a. Processing Pipeline

1. **Preprocessor** consumes `raw.social` and `raw.news`
2. **Deduplicates** via content hash
3. **Normalizes** into common schema
4. **Triages** via keyword scan: urgent items (urgent keyword + geopolitical entity co-occurrence) bypass batching, routine items are queued
5. **Urgent items** → immediate single-item Codex CLI call
6. **Routine items** → batched (50-100 items) every 30-60 seconds

### 3b. Urgency Keywords

```
URGENT_KEYWORDS: tariff, sanctions, embargo, war, invasion, missile,
  nuclear, coup, assassination, emergency, breaking, fed rate, rate cut,
  rate hike, default, bailout, crashed, halted, circuit breaker, black swan

GEOPOLITICAL_ENTITIES: China, Russia, Iran, Taiwan, Ukraine, NATO,
  OPEC, EU, Treasury, Pentagon, White House, Federal Reserve, SEC, USTR
```

Urgent = any urgent keyword + any geopolitical entity in the same item.

### 3c. Codex CLI Integration (Primary)

**Primary invocation (with `--output-schema`):**

```bash
codex exec --full-auto -s read-only \
  --output-schema config/schemas/event_output.json \
  -o /tmp/codex-result-{timestamp}.json \
  < /tmp/codex-batch-{timestamp}.md
```

**Fallback invocation (if `--output-schema` is unsupported in installed version):**

```bash
codex exec --full-auto -s read-only \
  --output-last-message \
  < /tmp/codex-batch-{timestamp}.md | python -m src.nlp.schema_validator
```

- On startup, the NLP engine runs `codex --version` and tests `--output-schema` with a trivial prompt. If the flag is unsupported, it falls back to prompt-engineered JSON with a post-hoc schema validator (`jsonschema` library against `event_output.json`). Invalid JSON triggers a retry (once) then Ollama fallback.
- `-s read-only` sandbox prevents filesystem modifications
- `-o` writes result to file for reliable parsing (when `--output-schema` is available)
- Timeout: 30 seconds, then fallback to Ollama
- **Required Codex CLI version:** >= 0.77.0 (pin in `pyproject.toml` as a documented dependency)

**Prompt structure:** System prompt defines the analyst role and includes the full JSON Schema inline (ensuring structured output even without `--output-schema`). User prompt contains the batch of items as JSON. Requested output: event_type, severity (1-10), sentiment (-1.0 to 1.0), affected_assets, affected_sectors, direction (bullish/bearish/neutral), confidence (0-1), reasoning.

### 3d. Ollama Fallback

- Activated when Codex CLI fails, times out, or is rate-limited
- Same prompt structure, sent to `http://localhost:11434/api/chat` with `format: "json"`
- Model name configurable in `config.yaml` (uses whatever is already installed)
- Supports image input for chart/infographic analysis (multimodal)

### 3e. Image Analysis Pipeline

- When Apify scrapes posts with images: store image URLs
- Download images in parallel with text analysis
- Send to Ollama multimodal model with prompt: "Describe any financial charts, data, or information in this image"
- Merge extracted information with text sentiment score

### 3f. Output Streams

- `events.geopolitical`: event_id, timestamp, source, event_type, severity, affected_assets, affected_sectors, reasoning
- `sentiment.scored`: item_id, timestamp, source, asset/ticker, sentiment (-1 to 1), direction, confidence, engagement_weight

**Engagement weight** (source-type dependent):
- **Social media (Twitter/Reddit):** `log(1 + likes + 2*retweets + 0.5*replies)` — prevents single viral posts from overwhelming signal while still respecting social proof.
- **News articles (Finnhub, MarketAux, RSS):** Fixed credibility score by source tier. Tier 1 (Reuters, Bloomberg, WSJ) = 2.0, Tier 2 (CNBC, MarketWatch, FT) = 1.5, Tier 3 (all other sources) = 1.0. Government sources (White House, Fed, USTR) = 3.0 (highest weight — these are primary sources, not analysis).
- All engagement weights are normalized to a 0-1 scale before the engagement-weighted mean, ensuring news and social items contribute proportionally.

---

## 4. Signal Generation

### 4a. Fast Signal Engine (Event-Driven)

- **Consumes:** `events.geopolitical`, `sentiment.scored`
- **Publishes to:** `signals.fast`
- **Always listening** — reacts within minutes

**Trigger conditions (ALL required):**
1. `event.severity >= 7`
2. `event.confidence >= 0.7`
3. At least 2 corroborating sources within corroboration window (see below)

**Event-to-action mapping:**

| Event Type | Bearish Action | Bullish Action |
|---|---|---|
| tariff | Short affected sectors, long safe havens (GLD, BTC) | Long affected beneficiaries |
| sanctions | Short affected country ETFs, long competitors | Long replacement suppliers |
| military | Long defense (ITA), oil; short broad market | — |
| monetary_policy | Short growth, long TLT | Long growth/tech, long BTC |
| trade_deal | — | Long affected sectors |
| market_shock | Reduce all positions, increase cash | — |

**Corroboration:** Rolling window anchored to the *first-seen* event of a given `event_type`. Window sizes vary by source latency:
- News sources (Finnhub, MarketAux, RSS): 5-minute window (all poll at <= 2 min intervals)
- If the first source is Apify (social media): 10-minute window (Apify polls every 5 min, so a second source needs time to arrive)
- If only 1 source fires within the window: do NOT discard. Instead, downgrade to `conviction *= 0.5` and log "unconfirmed single-source event." This prevents silently dropping valid events when a second source is slow.
- Require >= 2 unique sources for full conviction. Aggregate severity = mean, sentiment = engagement-weighted mean.

**Conviction formula:**
- Multi-source (>= 2 sources): `conviction = severity/10 * confidence * min(source_count/3, 1.0)` — caps at 3 sources, scales linearly.
- Single-source (corroboration window expired with 1 source): `conviction = severity/10 * confidence * 0.5` — the `source_count` factor is replaced by a flat 0.5 modifier, not compounded with it. This ensures high-severity single-source events (e.g., severity 9, confidence 0.9 = conviction 0.405) remain below the full-conviction threshold but above the discard threshold in Section 4d.

**Signal output:** signal_id, timestamp, strategy: "fast", action, assets, conviction, event_context, ttl: 4h

### 4b. Momentum Signal Engine (Scheduled)

- **Consumes:** `raw.prices`, `sentiment.scored`, `raw.trends`
- **Publishes to:** `signals.momentum`
- **Schedule:** Daily 5:00 PM ET (equities), midnight UTC (crypto)

**Composite momentum score per asset:**

```
momentum_score = (
    price_weight    * price_momentum      +
    sentiment_weight * sentiment_momentum  +
    volume_weight   * volume_momentum      +
    social_weight   * social_momentum      +
    trends_weight   * trend_momentum
)
```

Default weights: price 0.30, sentiment 0.25, volume 0.20, social 0.15, trends 0.10. All configurable in `config.yaml`.

**Component definitions:**
- `price_momentum`: normalize(0.5 * returns_5d + 0.3 * returns_20d + 0.2 * RSI_percentile)
- `sentiment_momentum`: normalize(rolling_3d_sentiment - rolling_14d_sentiment) — measures sentiment *acceleration*, not level
- `volume_momentum`: normalize(volume_5d_avg / volume_20d_avg)
- `social_momentum`: normalize(mention_count_24h / mention_count_7d_avg)
- `trend_momentum`: normalize(google_trends_current / google_trends_4w_avg)

**Ranking:** Score all assets → rank descending → top quintile = LONG, bottom quintile = SHORT (if enabled), middle = no action.

**Signal output:** signal_id, timestamp, strategy: "momentum", action, asset, momentum_score, component_scores, rank, quintile, ttl: 7d

**Regime-conditional TTL:** Momentum signals are invalidated immediately on any regime transition (e.g., RISK_ON → RISK_OFF). On regime change, all outstanding momentum signals are purged and a forced re-evaluation runs within 5 minutes using the new regime context. The 7-day TTL only applies if the regime remains unchanged.

### 4c. Regime Detector

- **Consumes:** `raw.macro`, `raw.sentiment`, `raw.prices` (including `$VIX` from Section 2f)
- **Publishes to:** `regime.current`
- **Schedule:** Daily 4:00 PM ET + on FRED data updates
- **Dependency:** Momentum Signal Engine (Section 4b) reads the latest value from `regime.current` as of its run time (5:00 PM ET). If `regime.current` has not been updated today (e.g., FRED unavailable), the previous day's regime persists and a warning is logged.

**Regime score:**

```
regime_score = (
    0.25 * vix_signal         +  // VIX > 30 = -1, < 15 = +1, else scaled
    0.20 * yield_curve_signal +  // inverted = -1, steep = +1
    0.20 * sahm_signal        +  // > 0.5 = -1, else +1
    0.15 * fear_greed_signal  +  // 0-25 = -1, 75-100 = +1
    0.10 * spy_trend_signal   +  // below 200d MA = -1, above = +1
    0.10 * cpi_trend_signal      // rising = -0.5, falling = +0.5
)
```

**Classification:** > 0.3 = RISK_ON, -0.3 to 0.3 = NEUTRAL, < -0.3 = RISK_OFF

### 4d. Signal Conflict Resolution

1. Fast conviction > 0.8 → ALWAYS takes precedence
2. Fast conviction 0.5-0.8 → blended (agree = increase size, disagree = fast direction at 50% size)
3. Fast conviction < 0.3 → discarded (threshold lowered from 0.5 to accommodate single-source events which max out around 0.45)
4. `market_shock` severity >= 9 → global risk-off, reduce ALL positions by configurable % (default 50%)

---

## 5. Risk Management & Portfolio Engine

### 5a. Position Sizing (5 Layers)

**Layer 1 — Half-Kelly base:**
- `kelly_pct = W - ((1 - W) / R)`, use `kelly_pct / 2`
- W = rolling 60-trade win rate (round-trip: entry + exit = 1 trade), R = avg_win / avg_loss
- **Cold start:** Until 60 trades have been recorded, use fixed fractional sizing: 1% of portfolio per position. This prevents NaN/negative Kelly values on a fresh deployment. The transition from fixed to Kelly is automatic once the 60-trade threshold is reached.

**Layer 2 — Volatility scaling:**
- `vol_adjusted = base * (target_vol / asset_ATR_14d)`
- Target daily vol: 1.5% (configurable)

**Layer 3 — Regime adjustment:**
- RISK_ON: 1.0x | NEUTRAL: 0.75x | RISK_OFF: 0.5x longs, 1.25x shorts

**Layer 4 — Correlation clamp:**
- Rolling 30-day correlation matrix
- Assets with correlation > 0.7 form clusters
- Max allocation per cluster: 25% of portfolio

**Layer 5 — Hard limits:**
- Max single position: 5%
- Max sector exposure: 25%
- Max total exposure: 150% gross (sum of absolute notional values of all positions / total account equity). Measured across both equities and crypto in USD terms. Crypto positions count at 1:1 weight. This limit applies at all times regardless of market hours.
- Max crypto-only exposure: 50% of portfolio (separate sub-limit since crypto is higher volatility)
- Min cash reserve: 10%

### 5b. Exit Management

**ATR Trailing Stop (primary):**
- Fast positions: 2.0 x ATR(14) trailing distance
- Momentum positions: 2.5 x ATR(14)
- Ratchets up only (longs), recalculated every price update

**Time-Based Expiry:**
- Fast: force-close at TTL (default 4h)
- Momentum: close at next rebalance if not in new top quintile

**Event-Driven Exit:**
- `market_shock` severity >= 9: reduce ALL by 50%
- Contradicting fast signal (conviction > 0.8): close immediately
- Regime change to RISK_OFF: tighten all stops to 1.5 x ATR

Priority: Event-driven > ATR trailing > Time-based

### 5c. Drawdown Circuit Breaker

| Drawdown | Action |
|---|---|
| -5% (YELLOW) | Reduce all new position sizes by 50%. Alert. |
| -10% (ORANGE) | Close all positions. Pause 24h. Alert. |
| -15% (RED) | Close all. Full halt until manual restart. Urgent alert. |

Peak equity resets only after new all-time high sustained for 5 consecutive trading days.

---

## 6. Execution Layer

### 6a. Order Routing

| Asset Type | Route | Order Types |
|---|---|---|
| US Equity (regular hours) | Alpaca Trading API | Market or limit |
| US Equity (extended 24/5) | Alpaca Trading API | Limit only (Alpaca requirement) |
| Crypto (24/7) | Alpaca Crypto API | Market or limit |

**Pre-submission validation:**
1. Circuit breaker status (reject if ORANGE/RED)
2. Position size within hard limits
3. Buying power available
4. Asset tradeable (not halted)
5. Extended hours: convert market → limit (last quote + 0.1% buffer)

**Order types:** Entries = limit orders. Trailing stops = Alpaca native where supported, else simulated. Emergency exits = market orders.

**Paper/Live:** Single env var `TRADING_MODE=paper|live`. Different base URLs, identical code.

### 6b. Fill Tracking

- Alpaca WebSocket for real-time fill updates
- Slippage monitoring (fill price vs expected)
- Partial fill handling: if fill ratio < 50% after 60 seconds, cancel remainder and treat the partial as the full position (counts against hard limits at filled quantity). If fill ratio >= 50%, hold and treat as complete at filled size. After accepting a partial fill as complete, no top-up or replacement order is issued for the remaining quantity of that signal. Log all partial fills with expected vs actual quantity.
- 5-minute reconciliation against Alpaca account state

### 6c. Alerting

| Event | Severity | Delivery |
|---|---|---|
| Geopolitical event (>= 7) | HIGH | Immediate webhook |
| Position opened/closed | INFO | Batched (5 min) |
| Drawdown threshold | CRITICAL | Immediate webhook |
| System error / service down | CRITICAL | Immediate webhook |
| Daily P&L summary | INFO | Scheduled (EOD) |
| Regime change | MEDIUM | Immediate webhook |
| Trailing stop triggered | INFO | Immediate webhook |

Transport: HTTP POST to configurable webhook URLs.

---

## 7. Storage & Backtesting

### 7a. Two-Tier Storage

**Redis (hot):** Real-time message passing. 48-hour retention (safety margin over the 24h operational window). All stream data + current positions, active signals, correlation cache.

**Circuit breaker state:** Persisted to DuckDB **immediately on every state change** (not via the drain worker's 60s batch). On system startup, the circuit breaker reads its state from DuckDB before allowing any orders. This ensures a Redis restart or system crash cannot silently reset a RED halt.

**DuckDB (cold):** `data/momentum_trader.duckdb`. Indefinite retention.

**Core table schemas:**

| Table | Key Columns |
|---|---|
| `raw_prices` | timestamp, date (derived from timestamp, used as partition key), ticker, open, high, low, close, volume, rsi_14, ema_12, ema_26, macd, bb_upper, bb_lower, atr_14. Partitioned by `date`. |
| `raw_news` | id, timestamp, headline, summary, source, source_tier, related_tickers[], url |
| `raw_social` | id, timestamp, text, source (twitter/reddit), subreddit, likes, retweets, replies, engagement_weight |
| `events` | event_id, timestamp, source_item_ids[], event_type, severity, affected_assets[], affected_sectors[], direction, confidence, reasoning, nlp_model_version |
| `sentiment_scores` | item_id, timestamp, source, ticker, sentiment, direction, confidence, engagement_weight, nlp_model_version |
| `signals` | signal_id, timestamp, strategy (fast/momentum), action, assets[], conviction, momentum_score, component_scores (JSON), rank, quintile, ttl, regime_at_creation |
| `orders` | order_id, signal_id, timestamp, ticker, side, qty, order_type, limit_price, status |
| `fills` | fill_id, order_id, timestamp, ticker, side, qty, fill_price, expected_price, slippage |
| `portfolio_snapshots` | timestamp (hourly), total_equity, cash, positions (JSON), unrealized_pnl, drawdown_from_peak |
| `regime_history` | timestamp, regime, regime_score, component_scores (JSON) |
| `macro_indicators` | timestamp, series_id, value |
| `fear_greed` | timestamp, source (cnn/crypto), value |
| `circuit_breaker_state` | timestamp, level (GREEN/YELLOW/ORANGE/RED), peak_equity, current_drawdown_pct |

**NLP output versioning:** The `events` and `sentiment_scores` tables include `nlp_model_version` (e.g., "gpt-5.2-codex" or "llava:13b") to enable reproducible backtests. The backtest replay defaults to using stored NLP output and only optionally re-runs live NLP when explicitly requested.

**Drain worker:** Continuous (every 60s), reads Redis Streams → appends to DuckDB. Monitoring: tracks drain lag (Redis stream length vs last consumed offset). Alerts if lag exceeds 10 minutes. Recovery: if drain worker was down, Redis 48h retention provides buffer to catch up.

### 7b. Backtesting

**Mode 1 — VectorBT (parameter sweep):** Test thousands of parameter combos (momentum weights, ATR multipliers, regime thresholds) in seconds via NumPy/Numba acceleration. Input from DuckDB → pandas.

**Mode 2 — Event Replay (full simulation):** Query DuckDB for date range → replay events chronologically through all engines → simulated executor (no real orders) → equity curve + trade log + benchmark comparison (SPY, BTC, 60/40).

Key feature: can optionally re-run NLP with current model against historical news to test if improved models would have caught events the old model missed. By default, replays use the stored NLP output (with `nlp_model_version` tag) for reproducibility. Re-running live NLP must be explicitly requested and produces a separate tagged result set.

---

## 8. Dashboard (Next.js / TypeScript)

### Pages

- **Main:** Portfolio overview, equity curve, daily P&L, current regime
- **Signals:** Live feed of fast + momentum signals with conviction scores
- **Portfolio:** Current positions, unrealized P&L, sector exposure, correlation heatmap
- **Sentiment:** Per-asset sentiment timeline, engagement-weighted heatmap
- **Events:** Geopolitical event log with severity, affected assets, actions taken
- **Backtest:** Replay view — select date range, watch system decisions unfold
- **Settings:** Config editor for tuning parameters without code changes

### API

Python backend exposes REST endpoints reading from Redis (live) and DuckDB (historical). Dashboard polls + WebSocket for real-time updates.

**Authentication:** Dashboard API requires a bearer token (shared secret from `.env` as `DASHBOARD_API_TOKEN`). The API binds to `127.0.0.1` by default (localhost only). The Settings page (which has write access to `config.yaml`) requires the token on every request. If deployed on a network, TLS termination is the operator's responsibility.

---

## 9. Project Structure

```
momentum-trader/
├── config/
│   ├── config.yaml
│   ├── watchlist.yaml
│   ├── schemas/
│   │   ├── event_output.json
│   │   └── sentiment_output.json
│   └── .env.example
├── src/
│   ├── collectors/        # 8 collector services
│   ├── nlp/               # preprocessor, codex, ollama, image analysis
│   ├── signals/           # fast, momentum, regime, conflict resolver
│   ├── portfolio/         # sizing, correlation, exits, circuit breaker
│   ├── execution/         # executor, fill tracker, alerting
│   ├── storage/           # redis helpers, duckdb store, drain worker
│   ├── backtest/          # vectorbt sweep, event replay, benchmarks
│   └── common/            # config loader, pydantic models, logging
├── dashboard/             # Next.js TypeScript app
├── data/                  # DuckDB file (gitignored)
├── docker-compose.yml     # Redis + all Python services + dashboard
├── Procfile               # Alternative orchestration
└── pyproject.toml
```

### Service Map

| # | Container Name | Source Module | Description |
|---|---|---|---|
| 1 | `redis` | (image) | Redis 7 Alpine |
| 2 | `collector-apify` | `src.collectors.apify_social` | Twitter + Reddit via Apify |
| 3 | `collector-finnhub` | `src.collectors.finnhub_news` | News + market data |
| 4 | `collector-marketaux` | `src.collectors.marketaux_news` | Broad news coverage |
| 5 | `collector-rss` | `src.collectors.rss_feeds` | RSS feed aggregation |
| 6 | `collector-trends` | `src.collectors.google_trends` | Google Trends |
| 7 | `collector-prices` | `src.collectors.alpaca_prices` | Alpaca prices + VIX |
| 8 | `collector-fred` | `src.collectors.fred_macro` | FRED economic data |
| 9 | `collector-fear-greed` | `src.collectors.fear_greed` | Fear & Greed indices |
| 10 | `nlp-engine` | `src.nlp.preprocessor` | Preprocess + triage + dispatch to Codex/Ollama |
| 11 | `signal-fast` | `src.signals.fast_signal` | Event-driven fast signals |
| 12 | `signal-momentum` | `src.signals.momentum_signal` | Daily/weekly momentum scoring |
| 13 | `regime-detector` | `src.signals.regime_detector` | Macro regime classification |
| 14 | `portfolio-manager` | `src.portfolio.position_sizer` | Sizing + correlation + circuit breaker |
| 15 | `executor` | `src.execution.executor` | Order routing + fill tracking + alerting |
| 16 | `drain-worker` | `src.storage.drain_worker` | Redis → DuckDB continuous sync |
| 17 | `api-server` | `src.api.server` | REST + WebSocket backend for dashboard |
| 18 | `dashboard` | `dashboard/` (Next.js) | Web UI |
```

---

## 10. Configuration

All tunable parameters in `config.yaml`:

- Trading mode (paper/live), watchlist, momentum weights, rebalance schedule
- Fast signal thresholds (severity, confidence, corroboration window, TTL)
- Risk limits (position max, sector max, exposure max, cash reserve, Kelly fraction)
- Drawdown thresholds and pause durations
- ATR trailing stop multipliers and periods
- Regime detector weights and thresholds
- NLP settings (Codex model, Ollama model, batch size, timeout, urgent keywords)
- Alert webhook URLs and schedules
- Apify settings (API key, actors, poll intervals, subreddits, Twitter queries)

API keys in `.env` (gitignored): `APIFY_API_KEY`, `ALPACA_API_KEY`, `ALPACA_SECRET_KEY`, `FINNHUB_API_KEY`, `MARKETAUX_API_KEY`, `FRED_API_KEY`, `DASHBOARD_API_TOKEN`
