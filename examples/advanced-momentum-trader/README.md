# Advanced Example: Momentum Trader

This is a real-world example of a complex multi-phase project built with codex-handoff. It demonstrates how the phased execution mode handles large, multi-plan projects where each phase builds on the previous one.

## What's Here

- [`design-spec.md`](design-spec.md) — Full design specification for an event-driven momentum trading system (equities + crypto)
- [`plan-phase1-foundation.md`](plan-phase1-foundation.md) — Phase 1 implementation plan: project scaffolding, config system, data models, Redis Streams, DuckDB storage

## The Project

An event-driven momentum trading system that combines:
- Market data from multiple sources (Alpaca, Finnhub, MarketAux, RSS)
- Social media sentiment (Twitter/X, Reddit via Apify)
- NLP-powered geopolitical event detection (Codex CLI + Ollama fallback)
- Dual-timeframe signal generation (fast intraday + daily/weekly momentum)
- Risk-managed portfolio execution via Alpaca

The full system spans 7 implementation plans — this example includes the design spec and Phase 1 (Foundation).

## How codex-handoff Handles This

### Multi-plan workflow

Large projects like this are broken into separate plan files, each handed off independently:

```
Plan 1: Foundation        ← included here
Plan 2: Data Collectors
Plan 3: NLP Engine
Plan 4: Signal Generation
Plan 5: Portfolio & Execution
Plan 6: Dashboard
Plan 7: Backtesting
```

Each plan is executed with `/codex-handoff`, and the agent runs the full supervisor loop (execute → review → correct → repeat) for each one.

### Within-plan phased execution

Each plan can itself contain phases (using `## Phase N:` headings). When codex-handoff detects phase headings, it executes one phase at a time, ensuring Phase 2 only runs after Phase 1's files exist.

### Why this matters

- **Context efficiency** — Codex gets a focused prompt for each phase, not the entire spec
- **Dependency ordering** — Later phases build on earlier phases' output
- **Failure isolation** — A failed phase can be re-run with `--phase N` without re-doing everything
- **Progress visibility** — Per-phase scorecards show exactly where things stand

## How This Was Built

The design spec and plans were created using Claude Code's planning skills:

1. Brainstorming session to explore requirements and make key decisions
2. Design spec written with full architecture, data flows, and schemas
3. Implementation plans generated from the spec, one per system layer

The plans were then executed with `/codex-handoff`, letting Codex CLI do the coding while Claude Code supervised and reviewed.
