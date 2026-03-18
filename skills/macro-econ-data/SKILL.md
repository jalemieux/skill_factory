---
name: macro-econ-data
description: "Use when asked to gather, check, or analyze macroeconomic data — treasury rates, CPI, PCE, commodity prices (gold, silver, oil), or US market indices (S&P 500)"
tools: WebFetch
---

# Macro Economic Data

Fetches current and historical US macroeconomic indicators from free public APIs. Outputs LLM-friendly structured text.

**Data sources used (all free, no credit card):**

| Data | Source | Auth |
|------|--------|------|
| Treasury rates (all maturities) | Treasury.gov XML feed | None |
| CPI (Consumer Price Index) | BLS API v1 | None |
| PCE (Personal Consumption Expenditures) | FRED API | Free API key |
| S&P 500 | Yahoo Finance | None |
| Gold & Silver | Yahoo Finance | None |
| Crude Oil (WTI) | Yahoo Finance | None |

**Prerequisites:** For PCE data, a FRED API key is needed. All other endpoints require no key.

**Setup:** If `FRED_API_KEY` is not set, run `scripts/setup-fred-key.sh` from this skill's directory. Resolve the path relative to where this skill is installed (e.g., `bash ~/.claude/skills/macro-econ-data/scripts/setup-fred-key.sh` or `bash ./skills/macro-econ-data/scripts/setup-fred-key.sh`).

The script walks you through: sign up → paste key → validate → persist to shell config. If `FRED_API_KEY` is already set, it confirms it's working.

## Usage

### Treasury Rates (Current & Historical)

Fetches daily yield curve including 1-month, 3-month, 6-month, 1-year, 2-year, 5-year, 10-year, and 30-year maturities.

**Current year rates:**
```
WebFetch https://home.treasury.gov/resource-center/data-chart-center/interest-rates/pages/xml?data=daily_treasury_yield_curve&field_tdr_date_value=2026
```

**Historical (specific year):**
```
WebFetch https://home.treasury.gov/resource-center/data-chart-center/interest-rates/pages/xml?data=daily_treasury_yield_curve&field_tdr_date_value=2024
```

**Short-term bill rates only:**
```
WebFetch https://home.treasury.gov/resource-center/data-chart-center/interest-rates/pages/xml?data=daily_treasury_bill_rates&field_tdr_date_value=2026
```

The XML response contains `<entry>` elements with fields like `<d:BC_10YEAR>`, `<d:BC_2YEAR>`, `<d:BC_1MONTH>`, etc. Parse these to extract the rates.

**Output format:**
```
## Treasury Rates (as of YYYY-MM-DD)

| Maturity | Yield |
|----------|-------|
| 1 Month  | X.XX% |
| 3 Month  | X.XX% |
| 6 Month  | X.XX% |
| 1 Year   | X.XX% |
| 2 Year   | X.XX% |
| 5 Year   | X.XX% |
| 10 Year  | X.XX% |
| 30 Year  | X.XX% |

Yield curve slope (10Y - 2Y): X.XX bps
```

### CPI (Consumer Price Index)

Uses BLS API v1 — no registration or key needed.

**Series IDs:**
- `CUUR0000SA0` — CPI-U, All Items, Not Seasonally Adjusted
- `CUSR0000SA0` — CPI-U, All Items, Seasonally Adjusted
- `CUUR0000SA0L1E` — CPI-U, All Items Less Food and Energy (Core CPI)

**Fetch latest CPI data:**
```
WebFetch https://api.bls.gov/publicAPI/v1/timeseries/data/CUUR0000SA0
```

**Fetch Core CPI:**
```
WebFetch https://api.bls.gov/publicAPI/v1/timeseries/data/CUUR0000SA0L1E
```

Response is JSON. Parse `Results.series[0].data[]` — each entry has `year`, `period` (M01-M12), and `value` (index level). Calculate YoY % change: `((current - year_ago) / year_ago) * 100`.

**Output format:**
```
## CPI (as of YYYY-MM)

| Measure | Index | YoY Change |
|---------|-------|------------|
| CPI-U All Items | XXX.X | X.X% |
| Core CPI (ex Food & Energy) | XXX.X | X.X% |
```

### PCE (Personal Consumption Expenditures)

Requires FRED API key (free). This is the Fed's preferred inflation gauge.

**Series IDs:**
- `PCEPI` — PCE Price Index
- `PCEPILFE` — Core PCE (ex Food & Energy)

**Fetch PCE:**
```
WebFetch https://api.stlouisfed.org/fred/series/observations?series_id=PCEPI&api_key=${FRED_API_KEY}&file_type=json&sort_order=desc&limit=24
```

**Fetch Core PCE:**
```
WebFetch https://api.stlouisfed.org/fred/series/observations?series_id=PCEPILFE&api_key=${FRED_API_KEY}&file_type=json&sort_order=desc&limit=24
```

Response JSON has `observations[]` with `date` and `value`. Calculate YoY change from 12-month-apart observations.

**Output format:**
```
## PCE (as of YYYY-MM)

| Measure | Index | YoY Change |
|---------|-------|------------|
| PCE Price Index | XXX.X | X.X% |
| Core PCE (ex Food & Energy) | XXX.X | X.X% |
```

If `FRED_API_KEY` is not set, skip PCE and note it in the output.

### S&P 500, Gold, Silver, Oil (Yahoo Finance)

Yahoo Finance provides current and historical price data with no API key.

**Ticker symbols:**
- `^GSPC` — S&P 500
- `GC=F` — Gold Futures
- `SI=F` — Silver Futures
- `CL=F` — Crude Oil WTI Futures

**Current quote (all tickers at once):**
```
WebFetch https://query1.finance.yahoo.com/v8/finance/chart/%5EGSPC?range=5d&interval=1d
WebFetch https://query1.finance.yahoo.com/v8/finance/chart/GC%3DF?range=5d&interval=1d
WebFetch https://query1.finance.yahoo.com/v8/finance/chart/SI%3DF?range=5d&interval=1d
WebFetch https://query1.finance.yahoo.com/v8/finance/chart/CL%3DF?range=5d&interval=1d
```

**Historical data (1 year, daily):**
```
WebFetch https://query1.finance.yahoo.com/v8/finance/chart/%5EGSPC?range=1y&interval=1d
```

**Historical data (5 years, weekly):**
```
WebFetch https://query1.finance.yahoo.com/v8/finance/chart/%5EGSPC?range=5y&interval=1wk
```

**Range options:** `1d`, `5d`, `1mo`, `3mo`, `6mo`, `1y`, `2y`, `5y`, `10y`, `max`
**Interval options:** `1d`, `1wk`, `1mo`

Response JSON path: `chart.result[0].indicators.quote[0]` contains `open`, `high`, `low`, `close`, `volume` arrays. Timestamps at `chart.result[0].timestamp`. Current price is the last `close` value.

**Output format:**
```
## Markets & Commodities (as of YYYY-MM-DD)

| Asset | Price | Day Change |
|-------|-------|------------|
| S&P 500 | X,XXX.XX | +/-X.X% |
| Gold (per oz) | $X,XXX.XX | +/-X.X% |
| Silver (per oz) | $XX.XX | +/-X.X% |
| WTI Crude Oil | $XX.XX | +/-X.X% |
```

## Examples

### Full Macro Snapshot

When the user asks for a broad macro overview, fetch all categories and combine:

```
## Macro Economic Snapshot (YYYY-MM-DD)

### Treasury Rates
[table from Treasury section]

### Inflation
[CPI + PCE tables]

### Markets & Commodities
[table from Markets section]

### Key Observations
- [Notable spread/inversion signals]
- [Inflation trend direction]
- [Commodity price context]
```

### Historical Comparison

When comparing periods (e.g., "how have rates changed since 2022"):

1. Fetch Treasury XML for both years
2. Fetch Yahoo Finance with appropriate range
3. Present side-by-side:

```
## Rate Comparison: 2022 vs 2026

| Maturity | 2022-01 | 2026-03 | Change |
|----------|---------|---------|--------|
| 10 Year  | X.XX%   | X.XX%   | +X.XX  |
```

## Tips

- BLS v1 API returns the last 3 years by default — enough for YoY calculations without extra params.
- Treasury XML paginates. Page 0 is most recent. Add `&page=0` if you only need the latest entries.
- Yahoo Finance URL-encode special characters: `^` → `%5E`, `=` → `%3D`.
- When presenting data, always include the date of the observation — macro data has publication lags.
- For CPI, the YoY change is more meaningful than the index level. Always calculate and display it.
- The yield curve slope (10Y minus 2Y) is a key recession signal — include it when showing Treasury rates.

## Common Mistakes

- **Using CPI index values without context** — an index of 315.2 means nothing to most users. Always compute and show the YoY percentage change alongside.
- **Confusing CPI and PCE** — CPI is from BLS (monthly, typically reported first). PCE is from BEA/FRED (the Fed's preferred measure). They use different baskets and weights. Present both when available.
- **Not URL-encoding Yahoo Finance tickers** — `^GSPC` must be `%5EGSPC` and `CL=F` must be `CL%3DF` in URLs. Raw special characters will 404.
- **Ignoring data staleness** — Treasury data updates daily on business days. CPI publishes monthly with a ~2 week lag. PCE publishes monthly with a ~4 week lag. Always note the actual observation date, not today's date.
- **Fetching too much historical data at once** — Yahoo Finance may throttle or return partial data for `max` range. Use `5y` with `1wk` interval for long-term analysis instead.
- **Missing FRED_API_KEY for PCE** — don't error out. Skip PCE, note it's unavailable, and suggest the user get a free key.
