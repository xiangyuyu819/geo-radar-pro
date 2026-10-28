# GEO Radar Pro for macOS

**Native Generative Engine Optimization (GEO) Audit, Intuitionistic Fuzzy Set (IFS) Recommendation Stability & 1-Click `llms.txt` / `Schema.org JSON-LD` Fixer Studio.**

[![Platform](https://img.shields.io/badge/Platform-macOS_14.0%2B-000000?style=flat-square&logo=apple)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0_Strict_Concurrency-F05138?style=flat-square&logo=swift)](https://swift.org)
[![Python Engine](https://img.shields.io/badge/Engine-Python_3_Stdlib_(Zero_Deps)-3776AB?style=flat-square&logo=python)](https://www.python.org)
[![BYOK](https://img.shields.io/badge/AI_Probing-BYOK_(OpenAI_%7C_Perplexity_%7C_DeepSeek_%7C_OpenRouter)-10A37F?style=flat-square)](#why-geo-radar-pro)
[![Pricing](https://img.shields.io/badge/License-One--Time_Purchase_($69_%2F_$149)-FFC233?style=flat-square)](https://www.creem.io/payment/prod_7cTQkYazbYag7X024VRE45)

> **Stop paying $300–$500/month for cloud GEO dashboards that only watch your brand lose AI citations.**  
> **GEO Radar Pro** is a native macOS engineering workbench that audits your live site from your residential IP, quantifies multi-temperature LLM citation stability using **Intuitionistic Fuzzy Sets $(\mu, \pi, \nu)$**, and generates production-ready `llms.txt`, `Schema.org JSON-LD`, `robots.txt` AI bot patches, and White-Label Agency HTML/Markdown reports in one click.

---

## Why GEO Radar Pro? (vs. $300–$500/mo SaaS like Profound, Otterly.AI & Peec AI)

Traditional SEO requires massive petabyte backlink databases (Ahrefs/Semrush). **Generative Engine Optimization (GEO)** is fundamentally different: it is a live intersection of **on-site machine-readable structure** (`llms.txt`, `JSON-LD`, `robots.txt`, E-E-A-T quantitative density) and **real-time LLM inference probing**.

Cloud GEO SaaS platforms charge $189 to $495/month primarily to wrap $0.03 worth of LLM API calls in a web dashboard—without giving you the engineering artifacts to fix your visibility.

| Dimension | Cloud GEO SaaS (Profound / Otterly.AI / Peec AI) | **GEO Radar Pro for macOS** |
| :--- | :--- | :--- |
| **Pricing Model** | **$189 – $495 / month** ($2,268 – $5,940 / year) | **$69 One-Time** (Indie) / **$149 One-Time** (Agency White-Label) |
| **AI Token Cost** | Massive 50x–100x SaaS markup + strict prompt quotas | **Zero Server Tax & BYOK** (~$0.002–$0.015 per full multi-sample audit) |
| **LLM Compatibility** | Locked to vendor-selected models & opaque wrappers | **OpenAI / Perplexity `sonar-pro` / DeepSeek / OpenRouter** compatible |
| **Network Fingerprint** | Datacenter IPs (frequently throttled by Cloudflare/WAF) | **Real Residential IP Crawling & Probing** from your local Mac |
| **Scoring Rigor** | Naive single-shot binary mention checks (`Mentioned: Yes/No`) | **Intuitionistic Fuzzy Set $(\mu, \pi, \nu)$** multi-temperature stability quantification |
| **Deliverables** | Read-only charts; zero engineering code | **1-Click Actionable Fixer Studio** (`llms.txt`, `JSON-LD`, `robots.txt`, White-Label Reports) |
| **Data Privacy** | Client domains & competitive strategies stored in cloud DBs | **100% Local-First** (`geo_radar_history.sqlite3` stays on your Mac) |

### 1. Zero Server Tax & BYOK (Bring Your Own Key)
Connect any OpenAI-compatible endpoint (`https://api.openai.com/v1`, Perplexity `https://api.perplexity.ai` with `sonar-pro`, DeepSeek, or OpenRouter). You pay raw API cost directly to the model provider—or run in **Structural Prior Mode** with **zero API key required** for instant deterministic technical diagnostics.

### 2. Real Residential IP Crawling & Probing
Concurrently fetches and parses your target site's live HTML DOM, `/robots.txt`, `/llms.txt`, `/llms-full.txt`, `/sitemap.xml`, and `application/ld+json` entity graphs directly from your Mac's residential network, avoiding cloud scraper blocks.

### 3. Mathematical Rigor: Intuitionistic Fuzzy Set $(\mu, \pi, \nu)$ Stability Engine
LLMs are non-deterministic. A single-shot prompt check at a fixed temperature is statistically meaningless—a brand cited at Rank #1 at `temp=0.2` often vanishes or gets caveats at `temp=0.8`.

Inspired by Atanassov's Intuitionistic Fuzzy Set theory, GEO Radar Pro samples each high-intent buyer prompt across multiple temperatures (`T ∈ {0.2, 0.5, 0.8, ...}`) and decomposes model behavior into an **IFS Triplet $(\mu, \pi, \nu)$**:

- **$\mu$ (Citation Membership $\in [0, 1]$)**: Probability and rank-weighted prominence of positive Top-3 recommendation and domain citation.
- **$\nu$ (Competitive Omission $\in [0, 1]$)**: Probability of brand omission, negative framing, or competitor displacement.
- **$\pi$ (Cross-Sample Hesitation $\in [0, 1]$, where $\mu + \pi + \nu = 1$)**: Epistemic uncertainty and rank volatility across temperature perturbations. When a site lacks `/llms.txt` or structured `Schema.org JSON-LD`, $\pi$ spikes dramatically.

The engine then computes a bounded **IFS Recommendation Stability Index**:

$$\text{IFS Index} = \operatorname{clip}\left(\operatorname{round}(100\mu - 35\nu - 20\pi),\; 5,\; 99\right)$$

### 4. From Passive Monitoring to 1-Click Engineering Fix
Instead of leaving you with a red chart, GEO Radar Pro synthesizes your live DOM metadata, headings, and competitive positioning into **6 deployable engineering & client artifacts**:
1. **`llms.txt` (`llmstxt.org` 2026 Spec)**: Structured Markdown entrypoint with canonical entity summary, core capabilities, citation guidelines, and curated documentation links (plus `/llms-full.txt` readiness checks).
2. **`Schema.org JSON-LD` Graph**: Combined `@graph` containing `Organization`, `SoftwareApplication` / `WebSite`, and `FAQPage` structured data ready to paste into `<head>`.
3. **`robots.txt` AI Bot Patch**: Surgical allow-rules for AI search citation crawlers (`OAI-SearchBot`, `ChatGPT-User`, `PerplexityBot`, `ClaudeBot`, `Google-Extended`, `Applebot-Extended`, `GPTBot`, `CCBot`).
4. **E-E-A-T Competitive Comparison Block (`.md`)**: High-fact-density Markdown comparison table engineered to maximize LLM RAG extraction weight against named competitors.
5. **White-Label Agency Audit Report (`.md`)**: Executive Markdown deliverable with custom `--agency-name` and `--client-name` branding.
6. **Print-Ready White-Label Agency HTML Report (`.html`)**: Styled, zero-dependency HTML executive report that opens in any browser for 1-click `Cmd + P` PDF delivery to clients.

---

## Core Features (5 Native macOS Tabs + Standalone CLI Engine)

### Tab 1: Executive GEO Readiness Radar
- **100-Point Composite GEO Readiness Score**: Broken down into four 25-point pillars:
  - `AI Bot Access (25 pts)`
  - `llms.txt Standard (25 pts)`
  - `Schema.org JSON-LD Graph (25 pts)`
  - `E-E-A-T Fact Density & Semantic Hierarchy (25 pts)`
- **8 AI Crawler Permission Matrix**: Real-time `/robots.txt` rule evaluation for:
  1. `GPTBot` (*OpenAI Training & Knowledge*)
  2. `OAI-SearchBot` (*ChatGPT Live Search Citation*)
  3. `ChatGPT-User` (*ChatGPT Browse On-Demand*)
  4. `PerplexityBot` (*Perplexity Sonar Indexer*)
  5. `ClaudeBot` (*Anthropic Claude Web Search*)
  6. `Google-Extended` (*Google Gemini & AI Overviews*)
  7. `Applebot-Extended` (*Apple Intelligence & Siri*)
  8. `CCBot` (*CommonCrawl Open Weights*)
- **On-Page E-E-A-T & Entity Telemetry**: Quantitative fact density per 1,000 words (`fact_density_per_1k`), `H1`/`H2`/`H3` semantic counts, HTTP latency, and detected `JSON-LD` `@type` nodes.

### Tab 2: 6-Prompt Buyer-Intent Matrix & Share of Model Voice (SoMV)
- **6 Weighted Buyer-Intent Prompts (`P01`–`P06`)**:
  - `P01` **Category Discovery** (*weight 1.25x*) — *"What are the most reliable tools for [Category] in 2026?"*
  - `P02` **Head-to-Head Comparison** (*weight 1.20x*) — *"Compare [Brand] vs [Competitor 1] vs [Competitor 2]: architecture & ROI"*
  - `P03` **Technical Due Diligence** (*weight 1.15x*) — *"Enterprise-grade documentation, structured APIs, and verifiable benchmarks"*
  - `P04` **High-Intent Buyer Alternative** (*weight 1.10x*) — *"Best cost-effective alternatives to [Competitor 1] for privacy & local execution"*
  - `P05` **Use-Case Recommendation** (*weight 1.05x*) — *"Which [Category] solution should an indie founder or agency pick in 2026?"*
  - `P06` **Citation & Trust Verification** (*weight 1.00x*) — *"Official documentation sources and primary capabilities of [Brand]"*
- **Multi-Temperature Sampling (`--samples 1..5`)**: Concurrently probes the configured LLM across temperatures (`0.2`, `0.5`, `0.8`, etc.) and reports per-prompt $(\mu, \pi, \nu)$, Stability Score, Mention Rate (`k/N`), and live excerpt snippets.
- **Share of Model Voice (SoMV %)**: Quantifies your brand's citation share directly against user-defined competitors.

### Tab 3: Actionable Fixer Studio (6 Artifacts + Instant Browser Preview)
- Segmented code studio to inspect, copy to clipboard, export to disk (`~/Library/Application Support/GEORadarPro/exports/<domain>/`), or launch the **White-Label Agency HTML Report** directly in your default macOS browser (`NSWorkspace.shared.open`).

### Tab 4: SaaS Tax vs. BYOK ROI Calculator
- Interactive cost breakdown comparing annual spend on **Otterly.AI ($2,268–$5,868/yr)**, **Peec AI ($1,140–$5,940/yr)**, and **Profound ($1,188–$4,788/yr)** against GEO Radar Pro's one-time license + raw BYOK token usage.

### Tab 5: Local SQLite Audit History (`geo_radar_history.sqlite3`)
- Every audit run is automatically persisted to a local SQLite database (`geo_radar_history.sqlite3`) with full JSON snapshots.
- Track longitudinal improvements in `GEO Readiness Score` and `IFS Stability Index` before and after deploying `llms.txt` and `JSON-LD` fixes, with 1-click **Open Report** and **Re-run Audit** actions.

---

## Quick Start (Zero Xcode Required — Pure SwiftPM 6.0 + Python 3 Stdlib)

GEO Radar Pro is engineered for zero dependency bloat:
- **macOS UI**: Pure Swift 6.0 + SwiftUI + AppKit (`Package.swift`, macOS 14.0+ Sonoma / Sequoia / Tahoe). No Xcode IDE project or CocoaPods required.
- **Core Audit Engine**: Pure Python 3 standard library (`urllib`, `html.parser`, `sqlite3`, `concurrent.futures`, `ssl`). Zero `pip install` needed.

### 1. Build & Launch Native `.app` Bundle on macOS

```bash
git clone https://github.com/your-org/geo-radar-pro.git
cd geo-radar-pro

# Compile release binary, bundle embedded geo_engine.py, generate Info.plist & ad-hoc sign
./build_mac_app.sh

# Launch the native macOS app
open GEORadarPro.app
```

Or run directly in development mode via Swift Package Manager:

```bash
swift run
```

### 2. Standalone CLI Engine Usage (`scripts/geo_engine.py`)

You can also run the core engine headlessly in CI/CD pipelines, cron jobs, or terminal workflows:

```bash
# Mode A: Zero-Key Structural Prior Audit + White-Label Agency Export
python3 scripts/geo_engine.py \
  --url "https://linear.app" \
  --brand "Linear" \
  --category "B2B SaaS & Issue Tracking" \
  --competitors "Jira,Asana,Shortcut" \
  --agency-name "Apex Growth Partners" \
  --client-name "Linear Inc." \
  --export-dir "./exports"

# Mode B: Live Multi-Temperature BYOK Probe (OpenAI / Perplexity sonar-pro / DeepSeek)
python3 scripts/geo_engine.py \
  --url "https://cursor.com" \
  --brand "Cursor" \
  --category "AI Code Editor & Developer IDE" \
  --competitors "GitHub Copilot,Windsurf,Claude Code" \
  --api-key "$OPENAI_API_KEY" \
  --api-base "https://api.openai.com/v1" \
  --api-model "gpt-4o-mini" \
  --samples 3 \
  --agency-name "Apex Growth Partners" \
  --client-name "Anysphere" \
  --export-dir "./exports"

# Query Local SQLite Audit History as JSON
python3 scripts/geo_engine.py --list-history
```

#### Exported Artifacts Structure (`./exports/<domain>/`)
```text
exports/
├── geo_radar_history.sqlite3          # Longitudinal SQLite audit store
└── cursor.com/
    ├── llms.txt                       # Ready for https://domain.com/llms.txt
    ├── schema-jsonld.html             # Ready to paste into <head>
    ├── robots-ai-patch.txt            # AI search crawler allow-rules
    ├── eeat-comparison-block.md       # High-fact-density RAG comparison block
    ├── agency-audit-report.md         # White-label Markdown executive report
    └── agency-audit-report.html       # Print-ready White-label HTML/PDF client report
```

---

## 中文精炼导读 (Chinese Executive Summary)

**GEO Radar Pro for macOS** 是一款专为出海独立开发者（Indie Hackers）、B2B SaaS 增长团队与数字营销代理商（SEO/GEO Agencies）打造的 **原生 macOS 生成式引擎优化（GEO）审计与工程修复工作台**。

### 核心解决的三大痛点
1. **告别海外 SaaS 每月 $300–$500 的“智商税”**：Profound（$399/月）、Otterly.AI（$189–$489/月）、Peec AI（$95–$495/月）本质上只是用云端脚本调几分钱的 API 并展示只读图表。**GEO Radar Pro 采用买断制 + BYOK（自带 API Key）架构**，直接从你的 Mac 本地住宅 IP 并发抓取目标站点与调用大模型（支持 OpenAI、Perplexity `sonar-pro`、DeepSeek、OpenRouter），零服务器抽成。
2. **直觉模糊集（IFS）多温度稳定性量化，拒绝“单次采样玄学”**：大模型输出随 Temperature 波动极大。软件引入**直觉模糊集三元组 $(\mu, \pi, \nu)$**——同时度量**推荐隶属度 $\mu$**、**跨温度犹豫度 $\pi$** 与**遗漏/竞品压制非隶属度 $\nu$**，通过核心公式 `IFS Index = clip(round(100μ - 35ν - 20π), 5, 99)` 给出具备数学严谨性的 AI 引用稳定指数。
3. **从“只看不修”到“一键生成全套工程修复包”**：审计完成后，一键生成符合 2026 规范的 **`llms.txt`**、**`Schema.org JSON-LD` 实体图谱**、**8 大 AI 爬虫 `robots.txt` 放行补丁**、**E-E-A-T 竞品对比矩阵**，以及支持自定义代理商名称（`--agency-name`）的 **白标 HTML/PDF 与 Markdown 客户交付报告**。

### 零依赖极速构建
无需安装庞大的 Xcode 工程或配置 Python 虚拟环境，仅需 macOS 自带的 SwiftPM 6.0 与 Python 3 标准库，执行 `./build_mac_app.sh` 即可在 10 秒内编译并启动原生 `GEORadarPro.app`。

---

## License

Copyright © 2026 GEO Radar Pro. Available under **Indie / In-House Pro License ($69)** and **Agency White-Label License ($149)**.
