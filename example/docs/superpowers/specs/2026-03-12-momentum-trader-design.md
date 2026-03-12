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

### 2f. Alpaca Price Data

- **Schedule:** WebSocket streaming (equities during 24/5 window), REST polling 60s (crypto 24/7)
- **Stream:** `raw.prices`
- **Data:** Real-time quotes, daily bars, account positions, P&L
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

```bash
codex exec --full-auto -s read-only \
  --output-schema config/schemas/event_output.json \
  -o /tmp/codex-result-{timestamp}.json \
  < /tmp/codex-batch-{timestamp}.md
```

- `--output-schema` enforces structured JSON output matching our event/sentiment schema
- `-s read-only` sandbox prevents filesystem modifications
- `-o` writes result to file for reliable parsing
- Timeout: 30 seconds, then fallback to Ollama

**Prompt structure:** System prompt defines the analyst role. User prompt contains the batch of items as JSON. Requested output: event_type, severity (1-10), sentiment (-1.0 to 1.0), affected_assets, affected_sectors, direction (bullish/bearish/neutral), confidence (0-1), reasoning.

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

**Engagement weight:** `log(1 + likes + 2*retweets + 0.5*replies)` — prevents single viral posts from overwhelming signal while still respecting social proof.

---

## 4. Signal Generation

### 4a. Fast Signal Engine (Event-Driven)

- **Consumes:** `events.geopolitical`, `sentiment.scored`
- **Publishes to:** `signals.fast`
- **Always listening** — reacts within minutes

**Trigger conditions (ALL required):**
1. `event.severity >= 7`
2. `event.confidence >= 0.7`
3. At least 2 corroborating sources within 5-minute window

**Event-to-action mapping:**

| Event Type | Bearish Action | Bullish Action |
|---|---|---|
| tariff | Short affected sectors, long safe havens (GLD, BTC) | Long affected beneficiaries |
| sanctions | Short affected country ETFs, long competitors | Long replacement suppliers |
| military | Long defense (ITA), oil; short broad market | — |
| monetary_policy | Short growth, long TLT | Long growth/tech, long BTC |
| trade_deal | — | Long affected sectors |
| market_shock | Reduce all positions, increase cash | — |

**Corroboration:** Collect matching-type events within 5-minute rolling window. Require >= 2 unique sources. Aggregate severity = mean, sentiment = engagement-weighted mean.

**Signal output:** signal_id, timestamp, strategy: "fast", action, assets, conviction (severity/10 * confidence * source_count/5), event_context, ttl: 4h

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

### 4c. Regime Detector

- **Consumes:** `raw.macro`, `raw.sentiment`, `raw.prices`
- **Publishes to:** `regime.current`
- **Schedule:** Daily 4:00 PM ET + on FRED data updates

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
3. Fast conviction < 0.5 → discarded
4. `market_shock` severity >= 9 → global risk-off, reduce ALL positions by configurable % (default 50%)

---

## 5. Risk Management & Portfolio Engine

### 5a. Position Sizing (5 Layers)

**Layer 1 — Half-Kelly base:**
- `kelly_pct = W - ((1 - W) / R)`, use `kelly_pct / 2`
- W = rolling 60-trade win rate, R = avg_win / avg_loss

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
- Max total exposure: 150%
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
- Partial fill handling (resubmit or cancel)
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

**Redis (hot):** Real-time message passing. 24-hour retention. All stream data + current positions, active signals, correlation cache, circuit breaker state.

**DuckDB (cold):** `data/momentum_trader.duckdb`. Indefinite retention. Tables: raw_prices, raw_news, raw_social, events, sentiment_scores, signals, orders, fills, portfolio_snapshots, regime_history, macro_indicators, fear_greed.

**Drain worker:** Continuous (every 60s), reads Redis Streams → appends to DuckDB.

### 7b. Backtesting

**Mode 1 — VectorBT (parameter sweep):** Test thousands of parameter combos (momentum weights, ATR multipliers, regime thresholds) in seconds via NumPy/Numba acceleration. Input from DuckDB → pandas.

**Mode 2 — Event Replay (full simulation):** Query DuckDB for date range → replay events chronologically through all engines → simulated executor (no real orders) → equity curve + trade log + benchmark comparison (SPY, BTC, 60/40).

Key feature: can re-run NLP with current model against historical news to test if improved models would have caught events the old model missed.

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
├── docker-compose.yml     # Redis + 17 Python services + dashboard
├── Procfile               # Alternative orchestration
└── pyproject.toml
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

API keys in `.env` (gitignored): `APIFY_API_KEY`, `ALPACA_API_KEY`, `ALPACA_SECRET_KEY`, `FINNHUB_API_KEY`, `MARKETAUX_API_KEY`, `FRED_API_KEY`
