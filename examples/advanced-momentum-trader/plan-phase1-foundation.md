# Momentum Trader — Plan 1: Foundation

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the project, config system, Pydantic data models, Redis Streams helpers, and DuckDB storage layer — the foundation every other subsystem depends on.

**Architecture:** A Python monorepo with independent service processes communicating via Redis Streams. DuckDB provides analytical storage. Config is loaded from YAML + `.env`. All data structures are defined as Pydantic models for validation across service boundaries.

**Tech Stack:** Python 3.12+, Pydantic v2, Redis (redis-py with streams), DuckDB (duckdb-python), PyYAML, python-dotenv, pytest, uv (package manager)

**Spec:** `docs/superpowers/specs/2026-03-12-momentum-trader-design.md`

**Plan series:**
- **Plan 1: Foundation** ← you are here
- Plan 2: Data Collectors
- Plan 3: NLP Engine
- Plan 4: Signal Generation
- Plan 5: Portfolio & Execution
- Plan 6: Dashboard
- Plan 7: Backtesting

---

## Chunk 1: Project Scaffolding & Config

### Task 1: Initialize project with uv

**Files:**
- Create: `pyproject.toml`
- Create: `.gitignore`
- Create: `.env.example`
- Create: `config/config.yaml`
- Create: `config/watchlist.yaml`

- [ ] **Step 1: Initialize the project with uv**

```bash
cd momentum-trader
uv init momentum-trader
cd momentum-trader
```

- [ ] **Step 2: Create `.gitignore`**

```gitignore
# Python
__pycache__/
*.pyc
.venv/
dist/

# Environment
.env

# Data
data/*.duckdb
data/*.duckdb.wal

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
```

- [ ] **Step 3: Update `pyproject.toml` with dependencies**

```toml
[project]
name = "momentum-trader"
version = "0.1.0"
description = "Event-driven momentum trading system with geopolitical NLP"
requires-python = ">=3.12"
dependencies = [
    "pydantic>=2.0",
    "redis>=5.0",
    "duckdb>=1.0",
    "pyyaml>=6.0",
    "python-dotenv>=1.0",
    "httpx>=0.27",
    "jsonschema>=4.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23",
    "fakeredis>=2.21",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]
```

- [ ] **Step 4: Install dependencies**

```bash
uv sync --all-extras
```

- [ ] **Step 5: Create `.env.example`**

```env
# Alpaca
ALPACA_API_KEY=your_alpaca_api_key
ALPACA_SECRET_KEY=your_alpaca_secret_key
TRADING_MODE=paper

# Data APIs
APIFY_API_KEY=your_apify_api_key
FINNHUB_API_KEY=your_finnhub_api_key
MARKETAUX_API_KEY=your_marketaux_api_key
FRED_API_KEY=your_fred_api_key

# Dashboard
DASHBOARD_API_TOKEN=your_dashboard_token

# Redis
REDIS_URL=redis://localhost:6379
```

- [ ] **Step 6: Create `config/config.yaml`**

```yaml
trading:
  mode: paper  # paper | live
  base_currency: USD

momentum:
  weights:
    price: 0.30
    sentiment: 0.25
    volume: 0.20
    social: 0.15
    trends: 0.10
  rebalance_schedule: daily_5pm_et
  quintile_threshold: 0.20

fast_signal:
  min_severity: 7
  min_confidence: 0.7
  corroboration_window_news_minutes: 5
  corroboration_window_social_minutes: 10
  min_sources: 2
  ttl_hours: 4

risk:
  position_max_pct: 0.05
  sector_max_pct: 0.25
  total_exposure_max_pct: 1.50
  crypto_exposure_max_pct: 0.50
  cash_reserve_min_pct: 0.10
  target_daily_vol: 0.015
  kelly_fraction: 0.5
  kelly_min_trades: 60
  cold_start_position_pct: 0.01
  correlation_cluster_threshold: 0.7
  correlation_cluster_max_pct: 0.25
  drawdown_yellow_pct: -0.05
  drawdown_orange_pct: -0.10
  drawdown_red_pct: -0.15
  orange_pause_hours: 24
  peak_reset_consecutive_days: 5

exits:
  fast_atr_multiplier: 2.0
  momentum_atr_multiplier: 2.5
  risk_off_atr_multiplier: 1.5
  atr_period: 14

regime:
  weights:
    vix: 0.25
    yield_curve: 0.20
    sahm: 0.20
    fear_greed: 0.15
    spy_trend: 0.10
    cpi_trend: 0.10
  risk_on_threshold: 0.3
  risk_off_threshold: -0.3

nlp:
  codex_timeout_seconds: 30
  ollama_model: llava:13b
  ollama_url: "http://localhost:11434"
  batch_size: 75
  urgent_keywords:
    - tariff
    - sanctions
    - embargo
    - war
    - invasion
    - missile
    - nuclear
    - coup
    - assassination
    - emergency
    - breaking
    - fed rate
    - rate cut
    - rate hike
    - default
    - bailout
    - crashed
    - halted
    - circuit breaker
    - black swan
  geopolitical_entities:
    - China
    - Russia
    - Iran
    - Taiwan
    - Ukraine
    - NATO
    - OPEC
    - EU
    - Treasury
    - Pentagon
    - White House
    - Federal Reserve
    - SEC
    - USTR

alerts:
  webhook_urls: []
  daily_summary_time: "17:30"
  batch_interval_seconds: 300

apify:
  twitter_actor: scrapers/twitter
  reddit_actor: trudax/reddit-scraper
  poll_interval_minutes: 5
  subreddits:
    - wallstreetbets
    - stocks
    - CryptoCurrency
    - geopolitics
  twitter_queries:
    - "$SPY"
    - "$QQQ"
    - "$BTC"
    - "$ETH"
    - tariff
    - sanctions
    - fed rate

collectors:
  finnhub_news_interval_seconds: 60
  finnhub_price_interval_seconds: 15
  marketaux_interval_seconds: 120
  rss_interval_seconds: 60
  google_trends_interval_minutes: 30
  google_trends_staleness_hours: 6
  fred_schedule: "16:00"
  fear_greed_interval_hours: 4
  vix_market_hours_interval_seconds: 60
  vix_off_hours_interval_seconds: 900

storage:
  duckdb_path: data/momentum_trader.duckdb
  redis_stream_retention_hours: 48
  drain_interval_seconds: 60
  drain_lag_alert_minutes: 10
```

- [ ] **Step 7: Create `config/watchlist.yaml`**

```yaml
equities:
  - SPY
  - QQQ
  - AAPL
  - MSFT
  - GOOGL
  - AMZN
  - NVDA
  - META
  - ITA
  - GLD
  - TLT
  - XLE

crypto:
  - BTC/USD
  - ETH/USD
  - SOL/USD

# Sector mapping for exposure limits
sectors:
  tech: [AAPL, MSFT, GOOGL, AMZN, NVDA, META]
  defense: [ITA]
  commodities: [GLD, XLE]
  bonds: [TLT]
  index: [SPY, QQQ]
  crypto: [BTC/USD, ETH/USD, SOL/USD]
```

- [ ] **Step 8: Create directory structure**

```bash
mkdir -p src/{collectors,nlp,signals,portfolio,execution,storage,backtest,common,api}
mkdir -p tests/{collectors,nlp,signals,portfolio,execution,storage,backtest,common,api}
mkdir -p config/schemas
mkdir -p data
touch src/__init__.py src/collectors/__init__.py src/nlp/__init__.py
touch src/signals/__init__.py src/portfolio/__init__.py src/execution/__init__.py
touch src/storage/__init__.py src/backtest/__init__.py src/common/__init__.py
touch src/api/__init__.py
touch tests/__init__.py tests/collectors/__init__.py tests/nlp/__init__.py
touch tests/signals/__init__.py tests/portfolio/__init__.py tests/execution/__init__.py
touch tests/storage/__init__.py tests/backtest/__init__.py tests/common/__init__.py
touch tests/api/__init__.py
```

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: scaffold momentum-trader project with config and dependencies"
```

---

### Task 2: Config Loader

**Files:**
- Create: `src/common/config.py`
- Test: `tests/common/test_config.py`

- [ ] **Step 1: Write the failing test**

Create `tests/common/test_config.py`:

```python
import os
from pathlib import Path
import pytest


def test_load_config_from_yaml(tmp_path):
    """Config loads from a YAML file and provides typed access."""
    yaml_content = """
trading:
  mode: paper
  base_currency: USD
risk:
  position_max_pct: 0.05
  kelly_fraction: 0.5
  kelly_min_trades: 60
  cold_start_position_pct: 0.01
"""
    config_file = tmp_path / "config.yaml"
    config_file.write_text(yaml_content)

    from src.common.config import load_config

    cfg = load_config(config_path=config_file)
    assert cfg["trading"]["mode"] == "paper"
    assert cfg["risk"]["position_max_pct"] == 0.05
    assert cfg["risk"]["kelly_fraction"] == 0.5


def test_load_config_missing_file():
    """Config raises FileNotFoundError for missing file."""
    from src.common.config import load_config

    with pytest.raises(FileNotFoundError):
        load_config(config_path=Path("/nonexistent/config.yaml"))


def test_load_watchlist(tmp_path):
    """Watchlist loads tickers and sector mapping."""
    yaml_content = """
equities:
  - SPY
  - AAPL
crypto:
  - BTC/USD
sectors:
  tech: [AAPL]
  index: [SPY]
  crypto: [BTC/USD]
"""
    watchlist_file = tmp_path / "watchlist.yaml"
    watchlist_file.write_text(yaml_content)

    from src.common.config import load_watchlist

    wl = load_watchlist(watchlist_path=watchlist_file)
    assert wl["equities"] == ["SPY", "AAPL"]
    assert wl["crypto"] == ["BTC/USD"]
    assert "tech" in wl["sectors"]


def test_load_env_vars(tmp_path, monkeypatch):
    """Environment variables are accessible after loading .env."""
    env_content = "ALPACA_API_KEY=test_key_123\nTRADING_MODE=paper\n"
    env_file = tmp_path / ".env"
    env_file.write_text(env_content)

    from src.common.config import load_env

    load_env(env_path=env_file)
    assert os.environ.get("ALPACA_API_KEY") == "test_key_123"


def test_get_nested_config_value(tmp_path):
    """get_config_value retrieves nested values with dot notation."""
    yaml_content = """
risk:
  position_max_pct: 0.05
  drawdown_yellow_pct: -0.05
"""
    config_file = tmp_path / "config.yaml"
    config_file.write_text(yaml_content)

    from src.common.config import load_config, get_config_value

    cfg = load_config(config_path=config_file)
    assert get_config_value(cfg, "risk.position_max_pct") == 0.05
    assert get_config_value(cfg, "risk.missing_key", default=0.1) == 0.1
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest tests/common/test_config.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'src.common.config'`

- [ ] **Step 3: Write minimal implementation**

Create `src/common/config.py`:

```python
"""Configuration loader for momentum-trader.

Loads YAML config, watchlist, and .env files.
"""

import os
from pathlib import Path
from typing import Any

import yaml
from dotenv import load_dotenv


def load_config(config_path: Path | None = None) -> dict[str, Any]:
    """Load config from YAML file.

    Args:
        config_path: Path to config.yaml. Defaults to config/config.yaml.

    Returns:
        Parsed config dictionary.

    Raises:
        FileNotFoundError: If config file does not exist.
    """
    if config_path is None:
        config_path = Path("config/config.yaml")
    if not config_path.exists():
        raise FileNotFoundError(f"Config file not found: {config_path}")
    with open(config_path) as f:
        return yaml.safe_load(f)


def load_watchlist(watchlist_path: Path | None = None) -> dict[str, Any]:
    """Load watchlist from YAML file.

    Args:
        watchlist_path: Path to watchlist.yaml. Defaults to config/watchlist.yaml.

    Returns:
        Parsed watchlist dictionary with equities, crypto, and sectors.

    Raises:
        FileNotFoundError: If watchlist file does not exist.
    """
    if watchlist_path is None:
        watchlist_path = Path("config/watchlist.yaml")
    if not watchlist_path.exists():
        raise FileNotFoundError(f"Watchlist file not found: {watchlist_path}")
    with open(watchlist_path) as f:
        return yaml.safe_load(f)


def load_env(env_path: Path | None = None) -> None:
    """Load environment variables from .env file.

    Args:
        env_path: Path to .env file. Defaults to .env in project root.
    """
    if env_path is None:
        env_path = Path(".env")
    load_dotenv(env_path, override=True)


def get_config_value(config: dict[str, Any], key: str, default: Any = None) -> Any:
    """Get a nested config value using dot notation.

    Args:
        config: Config dictionary.
        key: Dot-separated key path (e.g., "risk.position_max_pct").
        default: Default value if key not found.

    Returns:
        The config value, or default if not found.
    """
    parts = key.split(".")
    current = config
    for part in parts:
        if not isinstance(current, dict) or part not in current:
            return default
        current = current[part]
    return current
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest tests/common/test_config.py -v`
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/common/config.py tests/common/test_config.py
git commit -m "feat: add config loader with YAML, watchlist, and .env support"
```

---

### Task 3: Structured Logging

**Files:**
- Create: `src/common/logging.py`
- Test: `tests/common/test_logging.py`

- [ ] **Step 1: Write the failing test**

Create `tests/common/test_logging.py`:

```python
import json
import logging


def test_get_logger_returns_named_logger():
    """get_logger returns a logger with the given name."""
    from src.common.logging import get_logger

    logger = get_logger("test.module")
    assert logger.name == "test.module"
    assert isinstance(logger, logging.Logger)


def test_structured_log_format(capsys):
    """Logger outputs structured JSON lines."""
    from src.common.logging import get_logger, setup_logging

    setup_logging(level="DEBUG")
    logger = get_logger("test.structured")
    logger.info("test message", extra={"service": "collector", "ticker": "AAPL"})

    captured = capsys.readouterr()
    line = captured.err.strip().split("\n")[-1]
    data = json.loads(line)
    assert data["message"] == "test message"
    assert data["service"] == "collector"
    assert data["ticker"] == "AAPL"
    assert "timestamp" in data
    assert data["level"] == "INFO"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest tests/common/test_logging.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: Write minimal implementation**

Create `src/common/logging.py`:

```python
"""Structured JSON logging for momentum-trader services."""

import json
import logging
import sys
from datetime import datetime, timezone


class JSONFormatter(logging.Formatter):
    """Formats log records as single-line JSON."""

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        # Merge any extra fields passed via extra={}
        for key in record.__dict__:
            if key not in logging.LogRecord(
                "", 0, "", 0, "", (), None
            ).__dict__ and key not in ("message", "args"):
                log_entry[key] = record.__dict__[key]
        return json.dumps(log_entry, default=str)


def setup_logging(level: str = "INFO") -> None:
    """Configure root logger with JSON formatter on stderr.

    Safe to call multiple times — clears and reconfigures handlers each time.
    """
    handler = logging.StreamHandler(sys.stderr)
    handler.setFormatter(JSONFormatter())
    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(getattr(logging, level.upper()))


def get_logger(name: str) -> logging.Logger:
    """Get a named logger.

    Args:
        name: Logger name, typically __name__ or service identifier.

    Returns:
        Configured logger instance.
    """
    return logging.getLogger(name)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest tests/common/test_logging.py -v`
Expected: All 2 tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/common/logging.py tests/common/test_logging.py
git commit -m "feat: add structured JSON logging"
```

---

## Chunk 2: Pydantic Data Models

### Task 4: Core Data Models

**Files:**
- Create: `src/common/models.py`
- Test: `tests/common/test_models.py`

These Pydantic models define every data structure that crosses service boundaries via Redis Streams. They are the contract between services.

- [ ] **Step 1: Write the failing tests**

Create `tests/common/test_models.py`:

```python
import math
from datetime import datetime, timezone

import pytest
from pydantic import ValidationError


def test_social_post_valid():
    """SocialPost validates with all required fields."""
    from src.common.models import SocialPost

    post = SocialPost(
        id="tw_123",
        timestamp=datetime.now(timezone.utc),
        text="$AAPL is mooning",
        source="twitter",
        likes=100,
        retweets=50,
        replies=10,
    )
    assert post.source == "twitter"
    assert post.likes == 100


def test_social_post_engagement_weight():
    """SocialPost computes engagement weight as log(1 + likes + 2*retweets + 0.5*replies)."""
    from src.common.models import SocialPost

    post = SocialPost(
        id="tw_1",
        timestamp=datetime.now(timezone.utc),
        text="test",
        source="twitter",
        likes=100,
        retweets=50,
        replies=10,
    )
    expected = math.log(1 + 100 + 2 * 50 + 0.5 * 10)
    assert abs(post.engagement_weight - expected) < 0.001


def test_news_item_valid():
    """NewsItem validates and assigns source tier."""
    from src.common.models import NewsItem

    item = NewsItem(
        id="fh_456",
        timestamp=datetime.now(timezone.utc),
        headline="Fed raises rates",
        summary="The Federal Reserve raised rates by 25bps",
        source="Reuters",
        related_tickers=["SPY", "TLT"],
        url="https://reuters.com/article/123",
    )
    assert item.source_tier == 1
    assert item.engagement_weight == 2.0


def test_news_item_government_source():
    """Government sources get tier 0 and weight 3.0."""
    from src.common.models import NewsItem

    item = NewsItem(
        id="gov_1",
        timestamp=datetime.now(timezone.utc),
        headline="USTR announces new tariffs",
        summary="New tariffs on Chinese goods",
        source="USTR",
        related_tickers=["SPY"],
        url="https://ustr.gov/press/123",
    )
    assert item.source_tier == 0
    assert item.engagement_weight == 3.0


def test_geopolitical_event_valid():
    """GeopoliticalEvent validates event_type enum."""
    from src.common.models import GeopoliticalEvent

    event = GeopoliticalEvent(
        event_id="evt_1",
        timestamp=datetime.now(timezone.utc),
        source_item_ids=["fh_456"],
        event_type="tariff",
        severity=8,
        affected_assets=["SPY", "QQQ"],
        affected_sectors=["tech"],
        direction="bearish",
        confidence=0.85,
        reasoning="New tariffs on Chinese tech imports",
        nlp_model_version="gpt-5.2-codex",
    )
    assert event.severity == 8
    assert event.direction == "bearish"


def test_geopolitical_event_severity_bounds():
    """Severity must be between 1 and 10."""
    from src.common.models import GeopoliticalEvent

    with pytest.raises(ValidationError):
        GeopoliticalEvent(
            event_id="evt_2",
            timestamp=datetime.now(timezone.utc),
            source_item_ids=[],
            event_type="tariff",
            severity=11,
            affected_assets=[],
            affected_sectors=[],
            direction="bearish",
            confidence=0.5,
            reasoning="test",
            nlp_model_version="test",
        )


def test_sentiment_score_valid():
    """SentimentScore validates sentiment range."""
    from src.common.models import SentimentScore

    score = SentimentScore(
        item_id="tw_1",
        timestamp=datetime.now(timezone.utc),
        source="twitter",
        ticker="AAPL",
        sentiment=0.75,
        direction="bullish",
        confidence=0.9,
        engagement_weight=0.8,
        nlp_model_version="gpt-5.2-codex",
    )
    assert score.sentiment == 0.75


def test_sentiment_score_out_of_range():
    """Sentiment must be between -1.0 and 1.0."""
    from src.common.models import SentimentScore

    with pytest.raises(ValidationError):
        SentimentScore(
            item_id="tw_2",
            timestamp=datetime.now(timezone.utc),
            source="twitter",
            ticker="AAPL",
            sentiment=1.5,
            direction="bullish",
            confidence=0.9,
            engagement_weight=0.5,
            nlp_model_version="test",
        )


def test_trade_signal_valid():
    """TradeSignal validates with strategy enum."""
    from src.common.models import TradeSignal

    signal = TradeSignal(
        signal_id="sig_1",
        timestamp=datetime.now(timezone.utc),
        strategy="fast",
        action="long",
        assets=["AAPL"],
        conviction=0.85,
        ttl_hours=4,
    )
    assert signal.strategy == "fast"
    assert signal.conviction == 0.85


def test_trade_signal_conviction_bounds():
    """Conviction must be between 0.0 and 1.0."""
    from src.common.models import TradeSignal

    with pytest.raises(ValidationError):
        TradeSignal(
            signal_id="sig_2",
            timestamp=datetime.now(timezone.utc),
            strategy="fast",
            action="long",
            assets=["AAPL"],
            conviction=1.5,
            ttl_hours=4,
        )


def test_order_valid():
    """Order validates with all required fields."""
    from src.common.models import Order

    order = Order(
        order_id="ord_1",
        signal_id="sig_1",
        timestamp=datetime.now(timezone.utc),
        ticker="AAPL",
        side="buy",
        qty=10.0,
        order_type="limit",
        limit_price=150.50,
        status="pending",
    )
    assert order.side == "buy"
    assert order.qty == 10.0


def test_regime_state_valid():
    """RegimeState validates regime enum."""
    from src.common.models import RegimeState

    state = RegimeState(
        timestamp=datetime.now(timezone.utc),
        regime="RISK_ON",
        regime_score=0.5,
        components={"vix": 0.8, "yield_curve": 0.3},
    )
    assert state.regime == "RISK_ON"


def test_circuit_breaker_state_valid():
    """CircuitBreakerState validates level enum."""
    from src.common.models import CircuitBreakerState

    state = CircuitBreakerState(
        timestamp=datetime.now(timezone.utc),
        level="GREEN",
        peak_equity=100000.0,
        current_drawdown_pct=0.0,
    )
    assert state.level == "GREEN"


def test_trade_signal_invalidation():
    """TradeSignal supports invalidation fields for regime changes."""
    from src.common.models import TradeSignal

    signal = TradeSignal(
        signal_id="sig_inv",
        timestamp=datetime.now(timezone.utc),
        strategy="momentum",
        action="long",
        assets=["AAPL"],
        conviction=0.7,
        ttl_hours=168,
    )
    assert signal.invalidated is False
    assert signal.invalidated_at is None


def test_fill_valid():
    """Fill validates with slippage calculation."""
    from src.common.models import Fill

    fill = Fill(
        fill_id="fill_1",
        order_id="ord_1",
        timestamp=datetime.now(timezone.utc),
        ticker="AAPL",
        side="buy",
        qty=10.0,
        fill_price=151.0,
        expected_price=150.5,
        slippage=0.50,
    )
    assert fill.fill_price == 151.0
    assert fill.slippage == 0.50


def test_portfolio_snapshot_valid():
    """PortfolioSnapshot validates."""
    from src.common.models import PortfolioSnapshot

    snap = PortfolioSnapshot(
        timestamp=datetime.now(timezone.utc),
        total_equity=100000.0,
        cash=10000.0,
        positions={"AAPL": {"qty": 10, "avg_price": 150.0}},
        unrealized_pnl=500.0,
        drawdown_from_peak=-0.02,
    )
    assert snap.total_equity == 100000.0


def test_macro_indicator_valid():
    """MacroIndicator validates FRED data point."""
    from src.common.models import MacroIndicator

    ind = MacroIndicator(
        series_id="T10Y2Y",
        timestamp=datetime.now(timezone.utc),
        value=0.45,
    )
    assert ind.series_id == "T10Y2Y"


def test_fear_greed_index_valid():
    """FearGreedIndex validates range 0-100."""
    from src.common.models import FearGreedIndex

    fg = FearGreedIndex(
        timestamp=datetime.now(timezone.utc),
        source="crypto",
        value=25.0,
    )
    assert fg.source == "crypto"
    assert fg.value == 25.0


def test_fear_greed_index_out_of_range():
    """FearGreedIndex rejects values outside 0-100."""
    from src.common.models import FearGreedIndex

    with pytest.raises(ValidationError):
        FearGreedIndex(
            timestamp=datetime.now(timezone.utc),
            source="cnn",
            value=150.0,
        )
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uv run pytest tests/common/test_models.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: Write implementation**

Create `src/common/models.py`:

```python
"""Pydantic data models for all cross-service data structures.

These models define the contract between services communicating via Redis Streams.
Every message published to or consumed from a stream is validated through one of
these models.
"""

import math
from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field, computed_field


# --- Source tier mapping for news engagement weight ---

_GOVERNMENT_SOURCES = {"White House", "Federal Reserve", "USTR", "SEC", "Treasury", "Pentagon"}
_TIER_1_SOURCES = {"Reuters", "Bloomberg", "WSJ", "Wall Street Journal"}
_TIER_2_SOURCES = {"CNBC", "MarketWatch", "Financial Times", "FT", "Seeking Alpha", "AP"}


def _source_tier(source: str) -> int:
    """Return source credibility tier: 0=government, 1=tier1, 2=tier2, 3=other."""
    if source in _GOVERNMENT_SOURCES:
        return 0
    if source in _TIER_1_SOURCES:
        return 1
    if source in _TIER_2_SOURCES:
        return 2
    return 3


_TIER_WEIGHTS = {0: 3.0, 1: 2.0, 2: 1.5, 3: 1.0}


# --- Data models ---


class SocialPost(BaseModel):
    """A social media post from Twitter/X or Reddit."""

    id: str
    timestamp: datetime
    text: str
    source: Literal["twitter", "reddit"]
    subreddit: str | None = None
    likes: int = 0
    retweets: int = 0
    replies: int = 0
    score: int | None = None  # Reddit score
    comment_count: int | None = None
    image_urls: list[str] = Field(default_factory=list)

    @computed_field
    @property
    def engagement_weight(self) -> float:
        """log(1 + likes + 2*retweets + 0.5*replies)."""
        return math.log(1 + self.likes + 2 * self.retweets + 0.5 * self.replies)


class NewsItem(BaseModel):
    """A news article from Finnhub, MarketAux, or RSS."""

    id: str
    timestamp: datetime
    headline: str
    summary: str = ""
    source: str
    related_tickers: list[str] = Field(default_factory=list)
    url: str = ""

    @computed_field
    @property
    def source_tier(self) -> int:
        """Source credibility tier: 0=government, 1=tier1, 2=tier2, 3=other."""
        return _source_tier(self.source)

    @computed_field
    @property
    def engagement_weight(self) -> float:
        """Fixed credibility weight based on source tier."""
        return _TIER_WEIGHTS[self.source_tier]


class GeopoliticalEvent(BaseModel):
    """A classified geopolitical event from the NLP engine."""

    event_id: str
    timestamp: datetime
    source_item_ids: list[str]
    event_type: Literal[
        "tariff", "sanctions", "military", "monetary_policy",
        "election", "trade_deal", "regulatory", "natural_disaster",
        "market_shock", "none",
    ]
    severity: int = Field(ge=1, le=10)
    affected_assets: list[str]
    affected_sectors: list[str]
    direction: Literal["bullish", "bearish", "neutral"]
    confidence: float = Field(ge=0.0, le=1.0)
    reasoning: str
    nlp_model_version: str


class SentimentScore(BaseModel):
    """A sentiment score for a specific asset from the NLP engine."""

    item_id: str
    timestamp: datetime
    source: str
    ticker: str
    sentiment: float = Field(ge=-1.0, le=1.0)
    direction: Literal["bullish", "bearish", "neutral"]
    confidence: float = Field(ge=0.0, le=1.0)
    engagement_weight: float
    nlp_model_version: str


class TradeSignal(BaseModel):
    """A trade signal from the fast or momentum signal engine."""

    signal_id: str
    timestamp: datetime
    strategy: Literal["fast", "momentum"]
    action: Literal["long", "short", "close", "reduce", "hold"]
    assets: list[str]
    conviction: float = Field(ge=0.0, le=1.0)
    ttl_hours: float
    event_context: dict[str, Any] | None = None
    momentum_score: float | None = None
    component_scores: dict[str, float] | None = None
    rank: int | None = None
    quintile: int | None = None
    regime_at_creation: str | None = None
    invalidated: bool = False
    invalidated_at: datetime | None = None
    invalidated_reason: str | None = None  # e.g., "regime_change"


class Order(BaseModel):
    """A trade order submitted to the executor."""

    order_id: str
    signal_id: str
    timestamp: datetime
    ticker: str
    side: Literal["buy", "sell"]
    qty: float
    order_type: Literal["market", "limit", "trailing_stop"]
    limit_price: float | None = None
    status: Literal["pending", "submitted", "filled", "partial", "cancelled", "rejected"]


class Fill(BaseModel):
    """A confirmed fill from the broker."""

    fill_id: str
    order_id: str
    timestamp: datetime
    ticker: str
    side: Literal["buy", "sell"]
    qty: float
    fill_price: float
    expected_price: float
    slippage: float = 0.0


class RegimeState(BaseModel):
    """Current macro regime classification."""

    timestamp: datetime
    regime: Literal["RISK_ON", "NEUTRAL", "RISK_OFF"]
    regime_score: float = Field(ge=-1.0, le=1.0)
    components: dict[str, float]


class CircuitBreakerState(BaseModel):
    """Current circuit breaker state."""

    timestamp: datetime
    level: Literal["GREEN", "YELLOW", "ORANGE", "RED"]
    peak_equity: float
    current_drawdown_pct: float
    pause_until: datetime | None = None


class PortfolioSnapshot(BaseModel):
    """Hourly portfolio state snapshot."""

    timestamp: datetime
    total_equity: float
    cash: float
    positions: dict[str, Any]
    unrealized_pnl: float
    drawdown_from_peak: float


class MacroIndicator(BaseModel):
    """An economic indicator data point from FRED."""

    series_id: str
    timestamp: datetime
    value: float


class FearGreedIndex(BaseModel):
    """Fear & Greed index reading."""

    timestamp: datetime
    source: Literal["cnn", "crypto"]
    value: float = Field(ge=0.0, le=100.0)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest tests/common/test_models.py -v`
Expected: All 19 tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/common/models.py tests/common/test_models.py
git commit -m "feat: add Pydantic data models for all cross-service structures"
```

---

## Chunk 3: Redis Streams Helpers

### Task 5: Redis Stream Publisher and Consumer

**Files:**
- Create: `src/storage/redis_streams.py`
- Test: `tests/storage/test_redis_streams.py`

This module provides publish/consume helpers that every service uses to communicate via Redis Streams. We use `fakeredis` for testing so no Redis server is needed during tests.

- [ ] **Step 1: Write the failing tests**

Create `tests/storage/test_redis_streams.py`:

```python
import json
from datetime import datetime, timezone

import pytest

from src.common.models import SocialPost, NewsItem


@pytest.fixture
def fake_redis():
    """Create a fakeredis client for testing."""
    import fakeredis

    return fakeredis.FakeRedis(decode_responses=True)


def test_publish_and_consume_social_post(fake_redis):
    """Publish a SocialPost and consume it from the stream."""
    from src.storage.redis_streams import StreamPublisher, StreamConsumer

    pub = StreamPublisher(fake_redis)
    con = StreamConsumer(fake_redis, streams=["raw.social"], group="test-group", consumer="test-1")
    con.ensure_groups()

    post = SocialPost(
        id="tw_1",
        timestamp=datetime.now(timezone.utc),
        text="$AAPL going up",
        source="twitter",
        likes=100,
        retweets=50,
        replies=10,
    )

    pub.publish("raw.social", post)

    messages = con.consume(count=10, block_ms=100)
    assert len(messages) == 1
    stream, msg_id, data = messages[0]
    assert stream == "raw.social"
    assert data["id"] == "tw_1"
    assert data["source"] == "twitter"


def test_publish_preserves_model_fields(fake_redis):
    """Published data can be deserialized back into the model."""
    from src.storage.redis_streams import StreamPublisher, StreamConsumer

    pub = StreamPublisher(fake_redis)
    con = StreamConsumer(fake_redis, streams=["raw.news"], group="test-group", consumer="test-1")
    con.ensure_groups()

    item = NewsItem(
        id="fh_1",
        timestamp=datetime(2026, 3, 12, 12, 0, 0, tzinfo=timezone.utc),
        headline="Fed raises rates",
        summary="25bps hike",
        source="Reuters",
        related_tickers=["SPY", "TLT"],
        url="https://example.com",
    )

    pub.publish("raw.news", item)

    messages = con.consume(count=10, block_ms=100)
    assert len(messages) == 1
    _, _, data = messages[0]
    restored = NewsItem.model_validate_json(data["payload"])
    assert restored.headline == "Fed raises rates"
    assert restored.source_tier == 1
    assert restored.engagement_weight == 2.0
    assert restored.related_tickers == ["SPY", "TLT"]


def test_consume_empty_stream(fake_redis):
    """Consuming from an empty stream returns empty list."""
    from src.storage.redis_streams import StreamConsumer

    con = StreamConsumer(fake_redis, streams=["raw.empty"], group="test-group", consumer="test-1")
    con.ensure_groups()

    messages = con.consume(count=10, block_ms=100)
    assert messages == []


def test_ack_message(fake_redis):
    """Acknowledged messages are not re-delivered."""
    from src.storage.redis_streams import StreamPublisher, StreamConsumer

    pub = StreamPublisher(fake_redis)
    con = StreamConsumer(fake_redis, streams=["raw.social"], group="test-group", consumer="test-1")
    con.ensure_groups()

    post = SocialPost(
        id="tw_ack",
        timestamp=datetime.now(timezone.utc),
        text="test ack",
        source="twitter",
    )
    pub.publish("raw.social", post)

    messages = con.consume(count=10, block_ms=100)
    assert len(messages) == 1
    _, msg_id, _ = messages[0]

    con.ack("raw.social", msg_id)

    # Consuming again should return nothing (message was ack'd)
    messages2 = con.consume(count=10, block_ms=100)
    assert len(messages2) == 0


def test_publish_raw_dict(fake_redis):
    """Can publish a raw dict (for non-model data like trends)."""
    from src.storage.redis_streams import StreamPublisher, StreamConsumer

    pub = StreamPublisher(fake_redis)
    con = StreamConsumer(fake_redis, streams=["raw.trends"], group="test-group", consumer="test-1")
    con.ensure_groups()

    pub.publish_raw("raw.trends", {"keyword": "tariff", "interest": 85, "timestamp": "2026-03-12T12:00:00Z"})

    messages = con.consume(count=10, block_ms=100)
    assert len(messages) == 1
    _, _, data = messages[0]
    assert data["keyword"] == "tariff"
    assert data["interest"] == "85"  # Redis stores as strings
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uv run pytest tests/storage/test_redis_streams.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: Write implementation**

Create `src/storage/redis_streams.py`:

```python
"""Redis Streams publish/consume helpers.

Every service uses these helpers to communicate via Redis Streams.
Models are serialized to JSON for transport.
"""

from typing import Any

from pydantic import BaseModel
from redis import Redis


class StreamPublisher:
    """Publishes Pydantic models or raw dicts to Redis Streams."""

    def __init__(self, redis: Redis, maxlen: int | None = 100_000):
        """Initialize publisher.

        Args:
            redis: Redis client.
            maxlen: Approximate max stream length (caps memory usage).
                    Default 100K entries (~48h at typical throughput).
                    Set to None for unlimited.
        """
        self._redis = redis
        self._maxlen = maxlen

    def publish(self, stream: str, model: BaseModel) -> str:
        """Publish a Pydantic model to a stream.

        The model is serialized to JSON and stored in a 'payload' field,
        plus top-level 'id' and 'type' fields for quick filtering.

        Args:
            stream: Redis stream name (e.g., "raw.social").
            model: Pydantic model instance to publish.

        Returns:
            The Redis message ID.
        """
        data = {
            "payload": model.model_dump_json(),
            "type": type(model).__name__,
        }
        # Add 'id' field if the model has one
        if hasattr(model, "id"):
            data["id"] = str(getattr(model, "id"))
        elif hasattr(model, "event_id"):
            data["id"] = str(model.event_id)
        elif hasattr(model, "signal_id"):
            data["id"] = str(model.signal_id)

        # Copy source field if present for filtering
        if hasattr(model, "source"):
            data["source"] = str(getattr(model, "source"))

        kwargs = {}
        if self._maxlen is not None:
            kwargs["maxlen"] = self._maxlen
            kwargs["approximate"] = True
        return self._redis.xadd(stream, data, **kwargs)

    def publish_raw(self, stream: str, data: dict[str, Any]) -> str:
        """Publish a raw dictionary to a stream.

        Args:
            stream: Redis stream name.
            data: Dictionary of string-serializable values.

        Returns:
            The Redis message ID.
        """
        # Redis requires string values
        str_data = {k: str(v) for k, v in data.items()}
        kwargs = {}
        if self._maxlen is not None:
            kwargs["maxlen"] = self._maxlen
            kwargs["approximate"] = True
        return self._redis.xadd(stream, str_data, **kwargs)


class StreamConsumer:
    """Consumes messages from Redis Streams using consumer groups."""

    def __init__(
        self,
        redis: Redis,
        streams: list[str],
        group: str,
        consumer: str,
    ):
        self._redis = redis
        self._streams = streams
        self._group = group
        self._consumer = consumer

    def ensure_groups(self) -> None:
        """Create consumer groups for all streams (idempotent)."""
        for stream in self._streams:
            try:
                self._redis.xgroup_create(
                    stream, self._group, id="0", mkstream=True
                )
            except Exception:
                # Group already exists
                pass

    def consume(
        self, count: int = 10, block_ms: int = 1000
    ) -> list[tuple[str, str, dict[str, str]]]:
        """Read new messages from all streams.

        Args:
            count: Max messages to read per stream.
            block_ms: Max time to block waiting for messages.

        Returns:
            List of (stream_name, message_id, data_dict) tuples.
        """
        stream_ids = {s: ">" for s in self._streams}
        results = self._redis.xreadgroup(
            self._group,
            self._consumer,
            stream_ids,
            count=count,
            block=block_ms,
        )
        if not results:
            return []

        messages = []
        for stream_data in results:
            stream_name = stream_data[0]
            if isinstance(stream_name, bytes):
                stream_name = stream_name.decode()
            for msg_id, data in stream_data[1]:
                if isinstance(msg_id, bytes):
                    msg_id = msg_id.decode()
                if isinstance(data, dict):
                    decoded = {}
                    for k, v in data.items():
                        key = k.decode() if isinstance(k, bytes) else k
                        val = v.decode() if isinstance(v, bytes) else v
                        decoded[key] = val
                    data = decoded
                messages.append((stream_name, msg_id, data))
        return messages

    def ack(self, stream: str, message_id: str) -> None:
        """Acknowledge a message as processed.

        Args:
            stream: Stream name.
            message_id: Message ID to acknowledge.
        """
        self._redis.xack(stream, self._group, message_id)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest tests/storage/test_redis_streams.py -v`
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/storage/redis_streams.py tests/storage/test_redis_streams.py
git commit -m "feat: add Redis Streams publish/consume helpers"
```

---

## Chunk 4: DuckDB Storage Layer

### Task 6: DuckDB Schema and Store

**Files:**
- Create: `src/storage/duckdb_store.py`
- Test: `tests/storage/test_duckdb_store.py`

- [ ] **Step 1: Write the failing tests**

Create `tests/storage/test_duckdb_store.py`:

```python
from datetime import datetime, timezone

import pytest


@pytest.fixture
def db(tmp_path):
    """Create a DuckDB store with in-memory database for testing."""
    from src.storage.duckdb_store import DuckDBStore

    store = DuckDBStore(db_path=str(tmp_path / "test.duckdb"))
    store.initialize()
    yield store
    store.close()


def test_initialize_creates_tables(db):
    """All expected tables are created on initialize."""
    tables = db.list_tables()
    expected = [
        "raw_prices", "raw_news", "raw_social", "events",
        "sentiment_scores", "signals", "orders", "fills",
        "portfolio_snapshots", "regime_history", "macro_indicators",
        "fear_greed", "circuit_breaker_state",
    ]
    for table in expected:
        assert table in tables, f"Missing table: {table}"


def test_insert_and_query_raw_prices(db):
    """Insert price data and query it back."""
    db.insert_raw_price(
        timestamp=datetime(2026, 3, 12, 12, 0, 0, tzinfo=timezone.utc),
        ticker="AAPL",
        open=150.0, high=155.0, low=149.0, close=154.0,
        volume=1000000,
        rsi_14=65.0, ema_12=152.0, ema_26=150.0,
        macd=2.0, bb_upper=158.0, bb_lower=146.0, atr_14=3.5,
    )

    rows = db.query("SELECT * FROM raw_prices WHERE ticker = 'AAPL'")
    assert len(rows) == 1
    assert rows[0]["close"] == 154.0
    assert rows[0]["ticker"] == "AAPL"


def test_insert_circuit_breaker_state(db):
    """Circuit breaker state is persisted immediately."""
    from src.common.models import CircuitBreakerState

    state = CircuitBreakerState(
        timestamp=datetime.now(timezone.utc),
        level="RED",
        peak_equity=100000.0,
        current_drawdown_pct=-0.15,
    )
    db.save_circuit_breaker_state(state)

    loaded = db.load_circuit_breaker_state()
    assert loaded is not None
    assert loaded.level == "RED"
    assert loaded.peak_equity == 100000.0


def test_load_circuit_breaker_state_empty(db):
    """Loading from empty table returns None."""
    loaded = db.load_circuit_breaker_state()
    assert loaded is None


def test_insert_event(db):
    """Insert a geopolitical event and query it back."""
    from src.common.models import GeopoliticalEvent

    event = GeopoliticalEvent(
        event_id="evt_1",
        timestamp=datetime(2026, 3, 12, 14, 0, 0, tzinfo=timezone.utc),
        source_item_ids=["fh_1", "tw_1"],
        event_type="tariff",
        severity=8,
        affected_assets=["SPY", "QQQ"],
        affected_sectors=["tech"],
        direction="bearish",
        confidence=0.85,
        reasoning="New tariffs announced",
        nlp_model_version="gpt-5.2-codex",
    )
    db.insert_event(event)

    rows = db.query("SELECT * FROM events WHERE event_id = 'evt_1'")
    assert len(rows) == 1
    assert rows[0]["severity"] == 8
    assert rows[0]["event_type"] == "tariff"


def test_insert_signal(db):
    """Insert a trade signal and query it back."""
    from src.common.models import TradeSignal

    signal = TradeSignal(
        signal_id="sig_1",
        timestamp=datetime.now(timezone.utc),
        strategy="fast",
        action="long",
        assets=["AAPL"],
        conviction=0.85,
        ttl_hours=4,
        regime_at_creation="RISK_ON",
    )
    db.insert_signal(signal)

    rows = db.query("SELECT * FROM signals WHERE signal_id = 'sig_1'")
    assert len(rows) == 1
    assert rows[0]["strategy"] == "fast"
    assert rows[0]["conviction"] == 0.85
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uv run pytest tests/storage/test_duckdb_store.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: Write implementation**

Create `src/storage/duckdb_store.py`:

```python
"""DuckDB analytical storage layer.

Provides persistent storage for all historical data, backtesting,
and analytics. Circuit breaker state is persisted immediately
on every state change (not via the drain worker).
"""

import json
from datetime import datetime

import duckdb

from src.common.models import (
    CircuitBreakerState,
    GeopoliticalEvent,
    TradeSignal,
)


class DuckDBStore:
    """Manages DuckDB connection and schema."""

    def __init__(self, db_path: str = "data/momentum_trader.duckdb"):
        self._db_path = db_path
        self._conn: duckdb.DuckDBPyConnection | None = None

    def initialize(self) -> None:
        """Open connection and create all tables if they don't exist."""
        self._conn = duckdb.connect(self._db_path)
        self._create_tables()

    def close(self) -> None:
        """Close the database connection."""
        if self._conn:
            self._conn.close()
            self._conn = None

    @property
    def conn(self) -> duckdb.DuckDBPyConnection:
        if self._conn is None:
            raise RuntimeError("DuckDBStore not initialized. Call initialize() first.")
        return self._conn

    def _create_tables(self) -> None:
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS raw_prices (
                timestamp TIMESTAMPTZ NOT NULL,
                date DATE NOT NULL,
                ticker VARCHAR NOT NULL,
                open DOUBLE, high DOUBLE, low DOUBLE, close DOUBLE,
                volume BIGINT,
                rsi_14 DOUBLE, ema_12 DOUBLE, ema_26 DOUBLE,
                macd DOUBLE, bb_upper DOUBLE, bb_lower DOUBLE, atr_14 DOUBLE,
                PRIMARY KEY (timestamp, ticker)
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS raw_news (
                id VARCHAR PRIMARY KEY,
                timestamp TIMESTAMPTZ NOT NULL,
                headline VARCHAR NOT NULL,
                summary VARCHAR,
                source VARCHAR NOT NULL,
                source_tier INTEGER,
                related_tickers JSON,
                url VARCHAR
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS raw_social (
                id VARCHAR PRIMARY KEY,
                timestamp TIMESTAMPTZ NOT NULL,
                text VARCHAR NOT NULL,
                source VARCHAR NOT NULL,
                subreddit VARCHAR,
                likes INTEGER DEFAULT 0,
                retweets INTEGER DEFAULT 0,
                replies INTEGER DEFAULT 0,
                engagement_weight DOUBLE
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS events (
                event_id VARCHAR PRIMARY KEY,
                timestamp TIMESTAMPTZ NOT NULL,
                source_item_ids JSON,
                event_type VARCHAR NOT NULL,
                severity INTEGER NOT NULL,
                affected_assets JSON,
                affected_sectors JSON,
                direction VARCHAR NOT NULL,
                confidence DOUBLE,
                reasoning VARCHAR,
                nlp_model_version VARCHAR
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS sentiment_scores (
                item_id VARCHAR,
                timestamp TIMESTAMPTZ NOT NULL,
                source VARCHAR,
                ticker VARCHAR NOT NULL,
                sentiment DOUBLE,
                direction VARCHAR,
                confidence DOUBLE,
                engagement_weight DOUBLE,
                nlp_model_version VARCHAR
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS signals (
                signal_id VARCHAR PRIMARY KEY,
                timestamp TIMESTAMPTZ NOT NULL,
                strategy VARCHAR NOT NULL,
                action VARCHAR NOT NULL,
                assets JSON,
                conviction DOUBLE,
                momentum_score DOUBLE,
                component_scores JSON,
                rank INTEGER,
                quintile INTEGER,
                ttl_hours DOUBLE,
                regime_at_creation VARCHAR
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS orders (
                order_id VARCHAR PRIMARY KEY,
                signal_id VARCHAR,
                timestamp TIMESTAMPTZ NOT NULL,
                ticker VARCHAR NOT NULL,
                side VARCHAR NOT NULL,
                qty DOUBLE,
                order_type VARCHAR,
                limit_price DOUBLE,
                status VARCHAR
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS fills (
                fill_id VARCHAR PRIMARY KEY,
                order_id VARCHAR,
                timestamp TIMESTAMPTZ NOT NULL,
                ticker VARCHAR NOT NULL,
                side VARCHAR NOT NULL,
                qty DOUBLE,
                fill_price DOUBLE,
                expected_price DOUBLE,
                slippage DOUBLE
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS portfolio_snapshots (
                timestamp TIMESTAMPTZ NOT NULL,
                total_equity DOUBLE,
                cash DOUBLE,
                positions JSON,
                unrealized_pnl DOUBLE,
                drawdown_from_peak DOUBLE
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS regime_history (
                timestamp TIMESTAMPTZ NOT NULL,
                regime VARCHAR NOT NULL,
                regime_score DOUBLE,
                component_scores JSON
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS macro_indicators (
                timestamp TIMESTAMPTZ NOT NULL,
                series_id VARCHAR NOT NULL,
                value DOUBLE
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS fear_greed (
                timestamp TIMESTAMPTZ NOT NULL,
                source VARCHAR NOT NULL,
                value DOUBLE
            )
        """)
        self.conn.execute("""
            CREATE TABLE IF NOT EXISTS circuit_breaker_state (
                timestamp TIMESTAMPTZ NOT NULL,
                level VARCHAR NOT NULL,
                peak_equity DOUBLE,
                current_drawdown_pct DOUBLE,
                pause_until TIMESTAMPTZ
            )
        """)

    def list_tables(self) -> list[str]:
        """Return list of all table names."""
        result = self.conn.execute("SHOW TABLES").fetchall()
        return [row[0] for row in result]

    def query(self, sql: str, params: tuple = ()) -> list[dict]:
        """Execute a SQL query and return results as list of dicts."""
        result = self.conn.execute(sql, params)
        columns = [desc[0] for desc in result.description]
        return [dict(zip(columns, row)) for row in result.fetchall()]

    # --- Typed insert methods ---

    def insert_raw_price(
        self,
        timestamp: datetime,
        ticker: str,
        open: float, high: float, low: float, close: float,
        volume: int,
        rsi_14: float | None = None,
        ema_12: float | None = None,
        ema_26: float | None = None,
        macd: float | None = None,
        bb_upper: float | None = None,
        bb_lower: float | None = None,
        atr_14: float | None = None,
    ) -> None:
        """Insert a price row."""
        self.conn.execute(
            """INSERT INTO raw_prices VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            [
                timestamp, timestamp.date() if hasattr(timestamp, 'date') else timestamp,
                ticker, open, high, low, close, volume,
                rsi_14, ema_12, ema_26, macd, bb_upper, bb_lower, atr_14,
            ],
        )

    def insert_event(self, event: GeopoliticalEvent) -> None:
        """Insert a geopolitical event."""
        self.conn.execute(
            """INSERT INTO events VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            [
                event.event_id, event.timestamp,
                json.dumps(event.source_item_ids),
                event.event_type, event.severity,
                json.dumps(event.affected_assets),
                json.dumps(event.affected_sectors),
                event.direction, event.confidence,
                event.reasoning, event.nlp_model_version,
            ],
        )

    def insert_signal(self, signal: TradeSignal) -> None:
        """Insert a trade signal."""
        self.conn.execute(
            """INSERT INTO signals VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            [
                signal.signal_id, signal.timestamp,
                signal.strategy, signal.action,
                json.dumps(signal.assets),
                signal.conviction, signal.momentum_score,
                json.dumps(signal.component_scores) if signal.component_scores else None,
                signal.rank, signal.quintile,
                signal.ttl_hours, signal.regime_at_creation,
            ],
        )

    def save_circuit_breaker_state(self, state: CircuitBreakerState) -> None:
        """Persist circuit breaker state immediately (not via drain worker)."""
        self.conn.execute(
            """INSERT INTO circuit_breaker_state VALUES (?, ?, ?, ?, ?)""",
            [
                state.timestamp, state.level,
                state.peak_equity, state.current_drawdown_pct,
                state.pause_until,
            ],
        )

    def load_circuit_breaker_state(self) -> CircuitBreakerState | None:
        """Load the most recent circuit breaker state.

        Called on startup to restore state after crash/restart.
        Returns None if no state has been persisted.
        """
        rows = self.query(
            "SELECT * FROM circuit_breaker_state ORDER BY timestamp DESC LIMIT 1"
        )
        if not rows:
            return None
        row = rows[0]
        return CircuitBreakerState(
            timestamp=row["timestamp"],
            level=row["level"],
            peak_equity=row["peak_equity"],
            current_drawdown_pct=row["current_drawdown_pct"],
            pause_until=row.get("pause_until"),
        )
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest tests/storage/test_duckdb_store.py -v`
Expected: All 6 tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/storage/duckdb_store.py tests/storage/test_duckdb_store.py
git commit -m "feat: add DuckDB storage layer with schema and typed inserts"
```

---

### Task 7: Drain Worker (Redis → DuckDB)

**Files:**
- Create: `src/storage/drain_worker.py`
- Test: `tests/storage/test_drain_worker.py`

- [ ] **Step 1: Write the failing tests**

Create `tests/storage/test_drain_worker.py`:

```python
import json
from datetime import datetime, timezone

import pytest


@pytest.fixture
def fake_redis():
    import fakeredis
    return fakeredis.FakeRedis(decode_responses=True)


@pytest.fixture
def db(tmp_path):
    from src.storage.duckdb_store import DuckDBStore
    store = DuckDBStore(db_path=str(tmp_path / "test.duckdb"))
    store.initialize()
    yield store
    store.close()


def test_drain_social_post(fake_redis, db):
    """Drain worker moves social posts from Redis to DuckDB."""
    from src.storage.drain_worker import drain_once
    from src.storage.redis_streams import StreamPublisher
    from src.common.models import SocialPost

    pub = StreamPublisher(fake_redis)
    post = SocialPost(
        id="tw_drain_1",
        timestamp=datetime(2026, 3, 12, 12, 0, 0, tzinfo=timezone.utc),
        text="$AAPL bullish",
        source="twitter",
        likes=50,
        retweets=20,
        replies=5,
    )
    pub.publish("raw.social", post)

    drained = drain_once(fake_redis, db, streams=["raw.social"])
    assert drained == 1

    rows = db.query("SELECT * FROM raw_social WHERE id = 'tw_drain_1'")
    assert len(rows) == 1
    assert rows[0]["source"] == "twitter"


def test_drain_news_item(fake_redis, db):
    """Drain worker moves news items from Redis to DuckDB."""
    from src.storage.drain_worker import drain_once
    from src.storage.redis_streams import StreamPublisher
    from src.common.models import NewsItem

    pub = StreamPublisher(fake_redis)
    item = NewsItem(
        id="fh_drain_1",
        timestamp=datetime(2026, 3, 12, 14, 0, 0, tzinfo=timezone.utc),
        headline="Tariffs announced",
        summary="New tariffs on imports",
        source="Reuters",
        related_tickers=["SPY"],
        url="https://reuters.com/1",
    )
    pub.publish("raw.news", item)

    drained = drain_once(fake_redis, db, streams=["raw.news"])
    assert drained == 1

    rows = db.query("SELECT * FROM raw_news WHERE id = 'fh_drain_1'")
    assert len(rows) == 1
    assert rows[0]["source_tier"] == 1


def test_drain_empty_stream(fake_redis, db):
    """Draining empty streams returns 0."""
    from src.storage.drain_worker import drain_once

    drained = drain_once(fake_redis, db, streams=["raw.social"])
    assert drained == 0
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `uv run pytest tests/storage/test_drain_worker.py -v`
Expected: FAIL — `ModuleNotFoundError`

- [ ] **Step 3: Write implementation**

Create `src/storage/drain_worker.py`:

```python
"""Drain worker: continuously syncs Redis Streams → DuckDB.

Runs every 60 seconds (configurable). Reads unacknowledged messages
from all streams and inserts them into the corresponding DuckDB tables.
"""

import json
import time

from redis import Redis

from src.common.logging import get_logger, setup_logging
from src.common.models import (
    GeopoliticalEvent,
    NewsItem,
    SentimentScore,
    SocialPost,
    TradeSignal,
)
from src.storage.duckdb_store import DuckDBStore
from src.storage.redis_streams import StreamConsumer

logger = get_logger(__name__)

DRAIN_GROUP = "drain-worker"
DRAIN_CONSUMER = "drain-1"

ALL_STREAMS = [
    "raw.social", "raw.news", "raw.prices", "raw.trends",
    "raw.macro", "raw.sentiment",
    "events.geopolitical", "sentiment.scored",
    "signals.fast", "signals.momentum",
    "orders.sized", "orders.submitted",
    "fills.confirmed",
    "regime.current",
]


def drain_once(
    redis: Redis,
    db: DuckDBStore,
    streams: list[str] | None = None,
    batch_size: int = 100,
) -> int:
    """Drain one batch of messages from Redis to DuckDB.

    Args:
        redis: Redis client.
        db: DuckDB store.
        streams: Streams to drain. Defaults to ALL_STREAMS.
        batch_size: Max messages to read per stream.

    Returns:
        Number of messages drained.
    """
    if streams is None:
        streams = ALL_STREAMS

    consumer = StreamConsumer(
        redis, streams=streams, group=DRAIN_GROUP, consumer=DRAIN_CONSUMER
    )
    consumer.ensure_groups()

    messages = consumer.consume(count=batch_size, block_ms=500)
    drained = 0

    for stream, msg_id, data in messages:
        try:
            _insert_message(db, stream, data)
            consumer.ack(stream, msg_id)
            drained += 1
        except Exception:
            logger.exception("Failed to drain message", extra={
                "stream": stream, "msg_id": msg_id,
            })

    return drained


def _insert_message(db: DuckDBStore, stream: str, data: dict) -> None:
    """Route a message to the appropriate DuckDB insert method."""
    payload = data.get("payload")

    if stream == "raw.social" and payload:
        post = SocialPost.model_validate_json(payload)
        db.conn.execute(
            "INSERT INTO raw_social VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING",
            [
                post.id, post.timestamp, post.text, post.source,
                post.subreddit, post.likes, post.retweets, post.replies,
                post.engagement_weight,
            ],
        )
    elif stream == "raw.news" and payload:
        item = NewsItem.model_validate_json(payload)
        db.conn.execute(
            "INSERT INTO raw_news VALUES (?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING",
            [
                item.id, item.timestamp, item.headline, item.summary,
                item.source, item.source_tier,
                json.dumps(item.related_tickers), item.url,
            ],
        )
    elif stream == "events.geopolitical" and payload:
        event = GeopoliticalEvent.model_validate_json(payload)
        db.insert_event(event)
    elif stream.startswith("signals.") and payload:
        signal = TradeSignal.model_validate_json(payload)
        db.insert_signal(signal)
    # Additional stream handlers will be added in later plans


def main() -> None:
    """Run the drain worker loop."""
    import os
    setup_logging()
    logger.info("Starting drain worker")

    redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379")
    db_path = os.environ.get("DUCKDB_PATH", "data/momentum_trader.duckdb")

    redis = Redis.from_url(redis_url, decode_responses=True)
    db = DuckDBStore(db_path=db_path)
    db.initialize()

    try:
        while True:
            drained = drain_once(redis, db)
            if drained > 0:
                logger.info("Drained messages", extra={"count": drained})
            time.sleep(60)
    except KeyboardInterrupt:
        logger.info("Drain worker stopped")
    finally:
        db.close()


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `uv run pytest tests/storage/test_drain_worker.py -v`
Expected: All 3 tests PASS

- [ ] **Step 5: Commit**

```bash
git add src/storage/drain_worker.py tests/storage/test_drain_worker.py
git commit -m "feat: add drain worker for Redis → DuckDB sync"
```

---

## Chunk 5: JSON Schemas & Docker Compose

### Task 8: Codex CLI Output Schemas

**Files:**
- Create: `config/schemas/event_output.json`
- Create: `config/schemas/sentiment_output.json`

- [ ] **Step 1: Create event output schema**

Create `config/schemas/event_output.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["items"],
  "properties": {
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "event_type", "severity", "sentiment", "affected_assets", "direction", "confidence", "reasoning"],
        "properties": {
          "id": { "type": "string" },
          "event_type": {
            "type": "string",
            "enum": ["tariff", "sanctions", "military", "monetary_policy", "election", "trade_deal", "regulatory", "natural_disaster", "market_shock", "none"]
          },
          "severity": { "type": "integer", "minimum": 1, "maximum": 10 },
          "sentiment": { "type": "number", "minimum": -1.0, "maximum": 1.0 },
          "affected_assets": { "type": "array", "items": { "type": "string" } },
          "affected_sectors": { "type": "array", "items": { "type": "string" } },
          "direction": { "type": "string", "enum": ["bullish", "bearish", "neutral"] },
          "confidence": { "type": "number", "minimum": 0.0, "maximum": 1.0 },
          "reasoning": { "type": "string" }
        }
      }
    }
  }
}
```

- [ ] **Step 2: Create sentiment output schema**

Create `config/schemas/sentiment_output.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["scores"],
  "properties": {
    "scores": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "ticker", "sentiment", "direction", "confidence"],
        "properties": {
          "id": { "type": "string" },
          "ticker": { "type": "string" },
          "sentiment": { "type": "number", "minimum": -1.0, "maximum": 1.0 },
          "direction": { "type": "string", "enum": ["bullish", "bearish", "neutral"] },
          "confidence": { "type": "number", "minimum": 0.0, "maximum": 1.0 }
        }
      }
    }
  }
}
```

- [ ] **Step 3: Write schema validation test**

Create `tests/common/test_schemas.py`:

```python
import json
from pathlib import Path

import pytest


def _load_schema(name: str) -> dict:
    """Load a JSON schema file."""
    path = Path("config/schemas") / name
    with open(path) as f:
        return json.load(f)


def test_event_schema_accepts_valid_output():
    """Event output schema accepts a valid NLP result."""
    from jsonschema import validate

    schema = _load_schema("event_output.json")
    valid = {
        "items": [{
            "id": "test_1",
            "event_type": "tariff",
            "severity": 8,
            "sentiment": -0.7,
            "affected_assets": ["SPY"],
            "affected_sectors": ["tech"],
            "direction": "bearish",
            "confidence": 0.85,
            "reasoning": "New tariffs on imports"
        }]
    }
    validate(instance=valid, schema=schema)  # Should not raise


def test_event_schema_rejects_invalid_event_type():
    """Event output schema rejects unknown event types."""
    from jsonschema import validate, ValidationError

    schema = _load_schema("event_output.json")
    invalid = {
        "items": [{
            "id": "test_2",
            "event_type": "alien_invasion",  # not in enum
            "severity": 5,
            "sentiment": 0.0,
            "affected_assets": [],
            "direction": "neutral",
            "confidence": 0.5,
            "reasoning": "test"
        }]
    }
    with pytest.raises(ValidationError):
        validate(instance=invalid, schema=schema)


def test_event_schema_rejects_out_of_range_severity():
    """Event output schema rejects severity > 10."""
    from jsonschema import validate, ValidationError

    schema = _load_schema("event_output.json")
    invalid = {
        "items": [{
            "id": "test_3",
            "event_type": "tariff",
            "severity": 15,
            "sentiment": 0.0,
            "affected_assets": [],
            "direction": "bearish",
            "confidence": 0.5,
            "reasoning": "test"
        }]
    }
    with pytest.raises(ValidationError):
        validate(instance=invalid, schema=schema)
```

- [ ] **Step 4: Run schema tests**

Run: `uv run pip install jsonschema && uv run pytest tests/common/test_schemas.py -v`
Expected: All 3 tests PASS

Note: Add `jsonschema>=4.0` to `pyproject.toml` dependencies.

- [ ] **Step 5: Commit**

```bash
git add config/schemas/ tests/common/test_schemas.py
git commit -m "feat: add JSON schemas for Codex CLI structured output with validation tests"
```

---

### Task 9: Docker Compose & Procfile

**Files:**
- Create: `docker-compose.yml`
- Create: `Procfile`
- Create: `Dockerfile`

- [ ] **Step 1: Create Dockerfile**

Create `Dockerfile`:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install uv (official method)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy dependency files first for layer caching
COPY pyproject.toml .
RUN uv sync --no-dev

# Copy source
COPY . .

# Default command (overridden per service in docker-compose)
CMD ["uv", "run", "python", "-m", "src.storage.drain_worker"]
```

- [ ] **Step 2: Create `docker-compose.yml`**

Create `docker-compose.yml`:

```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data

  collector-apify:
    build: .
    command: uv run python -m src.collectors.apify_social
    env_file: .env
    environment:
      REDIS_URL: redis://redis:6379
    depends_on: [redis]

  collector-finnhub:
    build: .
    command: uv run python -m src.collectors.finnhub_news
    env_file: .env
    depends_on: [redis]

  collector-marketaux:
    build: .
    command: uv run python -m src.collectors.marketaux_news
    env_file: .env
    depends_on: [redis]

  collector-rss:
    build: .
    command: uv run python -m src.collectors.rss_feeds
    env_file: .env
    depends_on: [redis]

  collector-trends:
    build: .
    command: uv run python -m src.collectors.google_trends
    env_file: .env
    depends_on: [redis]

  collector-prices:
    build: .
    command: uv run python -m src.collectors.alpaca_prices
    env_file: .env
    depends_on: [redis]

  collector-fred:
    build: .
    command: uv run python -m src.collectors.fred_macro
    env_file: .env
    depends_on: [redis]

  collector-fear-greed:
    build: .
    command: uv run python -m src.collectors.fear_greed
    env_file: .env
    depends_on: [redis]

  nlp-engine:
    build: .
    command: uv run python -m src.nlp.preprocessor
    env_file: .env
    depends_on: [redis]

  signal-fast:
    build: .
    command: uv run python -m src.signals.fast_signal
    env_file: .env
    depends_on: [redis]

  signal-momentum:
    build: .
    command: uv run python -m src.signals.momentum_signal
    env_file: .env
    depends_on: [redis]

  regime-detector:
    build: .
    command: uv run python -m src.signals.regime_detector
    env_file: .env
    depends_on: [redis]

  portfolio-manager:
    build: .
    command: uv run python -m src.portfolio.position_sizer
    env_file: .env
    depends_on: [redis]

  executor:
    build: .
    command: uv run python -m src.execution.executor
    env_file: .env
    depends_on: [redis]

  drain-worker:
    build: .
    command: uv run python -m src.storage.drain_worker
    env_file: .env
    environment:
      REDIS_URL: redis://redis:6379
      DUCKDB_PATH: /app/data/momentum_trader.duckdb
    depends_on: [redis]
    volumes:
      - db-data:/app/data

  api-server:
    build: .
    command: uv run python -m src.api.server
    env_file: .env
    environment:
      REDIS_URL: redis://redis:6379
      DUCKDB_PATH: /app/data/momentum_trader.duckdb
    ports:
      - "8000:8000"
    depends_on: [redis]
    volumes:
      - db-data:/app/data

  dashboard:
    build: ./dashboard
    ports:
      - "3000:3000"
    depends_on: [api-server]

volumes:
  redis-data:
  db-data:
```

- [ ] **Step 3: Create `Procfile`**

Create `Procfile` (alternative to Docker for local development with `honcho` or `foreman`):

```procfile
collector-apify: uv run python -m src.collectors.apify_social
collector-finnhub: uv run python -m src.collectors.finnhub_news
collector-marketaux: uv run python -m src.collectors.marketaux_news
collector-rss: uv run python -m src.collectors.rss_feeds
collector-trends: uv run python -m src.collectors.google_trends
collector-prices: uv run python -m src.collectors.alpaca_prices
collector-fred: uv run python -m src.collectors.fred_macro
collector-fear-greed: uv run python -m src.collectors.fear_greed
nlp-engine: uv run python -m src.nlp.preprocessor
signal-fast: uv run python -m src.signals.fast_signal
signal-momentum: uv run python -m src.signals.momentum_signal
regime-detector: uv run python -m src.signals.regime_detector
portfolio-manager: uv run python -m src.portfolio.position_sizer
executor: uv run python -m src.execution.executor
drain-worker: uv run python -m src.storage.drain_worker
api-server: uv run python -m src.api.server
```

- [ ] **Step 4: Commit**

```bash
git add docker-compose.yml Dockerfile Procfile
git commit -m "feat: add Docker Compose, Dockerfile, and Procfile for orchestration"
```

---

### Task 10: Integration test — full round-trip

**Files:**
- Create: `tests/test_integration_foundation.py`

This test verifies the full data flow: config → model → Redis publish → consume → DuckDB drain.

- [ ] **Step 1: Write the integration test**

Create `tests/test_integration_foundation.py`:

```python
"""Integration test: config → model → Redis → DuckDB round-trip."""

from datetime import datetime, timezone

import pytest


@pytest.fixture
def fake_redis():
    import fakeredis
    return fakeredis.FakeRedis(decode_responses=True)


@pytest.fixture
def db(tmp_path):
    from src.storage.duckdb_store import DuckDBStore
    store = DuckDBStore(db_path=str(tmp_path / "integration.duckdb"))
    store.initialize()
    yield store
    store.close()


def test_full_round_trip(tmp_path, fake_redis, db):
    """Data flows: config → model → Redis publish → consume → DuckDB."""
    # 1. Load config
    from src.common.config import load_config, load_watchlist

    config_yaml = tmp_path / "config.yaml"
    config_yaml.write_text("trading:\n  mode: paper\nnlp:\n  batch_size: 75\n")
    watchlist_yaml = tmp_path / "watchlist.yaml"
    watchlist_yaml.write_text("equities:\n  - AAPL\ncrypto:\n  - BTC/USD\nsectors:\n  tech: [AAPL]\n  crypto: [BTC/USD]\n")

    cfg = load_config(config_path=config_yaml)
    wl = load_watchlist(watchlist_path=watchlist_yaml)
    assert cfg["trading"]["mode"] == "paper"
    assert "AAPL" in wl["equities"]

    # 2. Create a model
    from src.common.models import SocialPost

    post = SocialPost(
        id="integration_1",
        timestamp=datetime(2026, 3, 12, 15, 0, 0, tzinfo=timezone.utc),
        text="$AAPL breaking out! Tariffs cancelled",
        source="twitter",
        likes=5000,
        retweets=1200,
        replies=300,
    )
    assert post.engagement_weight > 0

    # 3. Publish to Redis
    from src.storage.redis_streams import StreamPublisher

    pub = StreamPublisher(fake_redis)
    pub.publish("raw.social", post)

    # 4. Drain to DuckDB
    from src.storage.drain_worker import drain_once

    drained = drain_once(fake_redis, db, streams=["raw.social"])
    assert drained == 1

    # 5. Query from DuckDB
    rows = db.query("SELECT * FROM raw_social WHERE id = 'integration_1'")
    assert len(rows) == 1
    assert rows[0]["text"] == "$AAPL breaking out! Tariffs cancelled"
    assert rows[0]["source"] == "twitter"
    assert rows[0]["likes"] == 5000
```

- [ ] **Step 2: Run integration test**

Run: `uv run pytest tests/test_integration_foundation.py -v`
Expected: PASS

- [ ] **Step 3: Run full test suite**

Run: `uv run pytest -v`
Expected: All tests PASS (config: 5, logging: 2, models: 19, redis: 5, duckdb: 6, drain: 3, schemas: 3, integration: 1 = 44 total)

- [ ] **Step 4: Commit**

```bash
git add tests/test_integration_foundation.py
git commit -m "feat: add integration test for full config → Redis → DuckDB round-trip"
```

---

## Summary

**Plan 1 delivers:**
- Project scaffold with uv, dependencies, directory structure
- Config loader (YAML + .env + watchlist)
- Structured JSON logging
- 16 Pydantic data models covering all cross-service contracts (including MacroIndicator, FearGreedIndex)
- Redis Streams publish/consume helpers (with fakeredis for testing)
- DuckDB storage with 13 tables matching the spec schema
- Drain worker (Redis → DuckDB sync)
- Codex CLI JSON output schemas
- Docker Compose + Dockerfile + Procfile for orchestration
- Integration test proving the full data flow

**Next plan:** Plan 2: Data Collectors — implements all 8 collector services on top of this foundation.
