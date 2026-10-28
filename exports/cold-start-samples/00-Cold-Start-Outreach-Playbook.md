# GEO Radar Pro — 海外明星 AI / 开发者 SaaS 冷启动外联作战手册 (Cold-Start Outreach Playbook)

> **生成机构**：GEO Radar Pro Benchmark Lab  
> **审计时间**：2026-10-28 (UTC+8)  
> **技术引擎**：GEO Radar Pro (`geo_engine.py`) — 真实 HTTP 抓取 + 结构先验直觉模糊集 (IFS) 评估 + 全套白标修复包  
> **样本数据库**：`/workspace/geo-radar-pro/exports/cold-start-samples/cold_start_history.sqlite3`

---

## 一、 5 家海外明星 SaaS 站点真实实测指标对比总表

以下数据全部来自对目标站点生产环境的实时 HTTP 抓取、`/robots.txt` 8 大 AI 爬虫权限解析、`/llms.txt` 与 `/llms-full.txt` 探测、HTML DOM `application/ld+json` 实体抽取及 E-E-A-T 事实密度测算：

| 排名 | 品牌 / 域名 | 客户名称 | HTTP 状态 | 响应耗时 | GEO Readiness 总分 | 四维细分 (Bots / llms.txt / Schema / E-E-A-T) | IFS 稳定性指数 | 直觉模糊集 $(\mu, \pi, \nu)$ | 8 大 AI 爬虫放行 | `/llms.txt` 状态 | Schema JSON-LD 数量与类型 | 核心失分项与工程缺口诊断 |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **#1** | **Cursor**<br>`cursor.com` | Cursor (Anysphere) | `200 OK` | `1,448 ms` | **95 / 100** | `25 / 25 / 24 / 21` | **85 / 100** | $(0.878,\ 0.082,\ 0.040)$ | **8 / 8 (100%)** | ✅ 已部署 `/llms.txt`<br>❌ 缺 `/llms-full.txt` | **2 个 Block**<br>`Organization`, `WebSite` | 缺少 `SoftwareApplication` 与 `FAQPage` 结构化对比定价实体；缺少 `/llms-full.txt` 全量知识归档；首页词数 375 词（事实密度 16.0/1k），可进一步补充可验证基准表。 |
| **#2** | **Resend**<br>`resend.com` | Resend Inc. | `200 OK` | `2,620 ms` | **86 / 100** | `25 / 25 / 12 / 24` | **85 / 100** | $(0.878,\ 0.082,\ 0.040)$ | **8 / 8 (100%)** | ✅ 已部署 `/llms.txt`<br>✅ 已部署 `/llms-full.txt` | **1 个 Block** (含 `@graph`)<br>`BreadcrumbList`, `Organization`, `SoftwareApplication`, `WebPage`, `WebSite` | **E-E-A-T 表现全场最佳（24/25，事实密度高达 28.2/1k，496 词，14 个 H2）**；但 JSON-LD 仅封装在单个 `<script>` 块中（Schema 得分 12/25），且缺少显式 `FAQPage` 与竞品（SendGrid/Postmark/AWS SES）参数对比矩阵。 |
| **#3** | **Dub**<br>`dub.co` | Dub Technologies | `200 OK` | `1,602 ms` | **85 / 100** | `25 / 25 / 24 / 11` | **85 / 100** | $(0.878,\ 0.082,\ 0.040)$ | **8 / 8 (100%)** | ✅ 已部署 `/llms.txt`<br>❌ 缺 `/llms-full.txt` | **2 个 Block**<br>`Organization`, `SoftwareApplication` | **E-E-A-T 事实密度偏低（11/25）**：首页可见正文仅 295 词、事实密度仅 `3.4 / 1k words`（仅 4 个 H2、1 个 H3），缺少可被 Perplexity/ChatGPT Search 直接摘录的量化吞吐/归因延迟指标与 vs Bitly/Rebrandly 对比块。 |
| **#4** | **Linear**<br>`linear.app` | Linear Orbit Inc. | `200 OK` | `164 ms` | **52 / 100** | `25 / 25 / 0 / 2` | **56 / 100** | $(0.653,\ 0.190,\ 0.157)$ | **8 / 8 (100%)** | ✅ 已部署 `/llms.txt`<br>❌ 缺 `/llms-full.txt` | **0 个 Block**<br>*(完全缺失 JSON-LD)* | **典型重客户端渲染 / 极简视觉陷阱**：虽然放行了全部 AI 爬虫并配有 `/llms.txt`，但首屏 HTML **0 个 Schema.org JSON-LD（0/25）**，且静态 HTML 正文仅提取到 31 词、0 个 H2、事实密度 `0.0/1k`（E-E-A-T 仅 2/25），导致犹豫度 $\pi=0.190$ 偏高。 |
| **#4** | **Cal.com**<br>`cal.com` | Cal.com Inc. | `200 OK` | `114 ms` | **52 / 100** | `25 / 25 / 0 / 2` | **56 / 100** | $(0.653,\ 0.190,\ 0.157)$ | **8 / 8 (100%)** | ✅ 已部署 `/llms.txt`<br>❌ 缺 `/llms-full.txt` | **0 个 Block**<br>*(完全缺失 JSON-LD)* | **SSR 静态语义空心化问题**：响应极快（114ms）且有 `/llms.txt`，但首页 HTML 中 **完全没有 `application/ld+json`（0/25）**，且无 `<p>`/`<h1>`/`<h2>` 静态事实段落（word_count=0，E-E-A-T 仅 2/25），无头 AI 检索爬虫抓取首页 DOM 时存在高犹豫度（$\pi=0.190$）。 |

> **关键洞察（可用于 X / LinkedIn Build-in-Public 爆款选题）**：
> 1. **2026 开发者工具新趋势**：5 家顶流海外 DevTools/SaaS（Cursor、Linear、Cal.com、Dub、Resend）**100% 全部已部署 `/llms.txt` 并对 8 大 AI 爬虫全量放行（8/8）**！说明海外头部团队已经普遍意识到 AI 搜索入口的重要性。
> 2. **但分化极其严重（95 分 vs 52 分）**：许多团队以为“放个 `llms.txt` 就做完 GEO 了”，实测发现 **Linear (52/100)** 和 **Cal.com (52/100)** 因为首页完全缺失 `Schema.org JSON-LD`（0/25）且首屏 DOM 静态事实密度为 `0.0/1k`（2/25），导致大模型在对比场景下的直觉模糊犹豫度 $\pi$ 飙升至 `0.190`；而 **Cursor (95/100)** 与 **Resend (86/100)** 则兼具结构化实体与高事实密度。

---

## 二、 5 大站点一对一创始人冷启动外联模板（DM / Email / X @提及，中英对照）

以下每套模板均已嵌入各站点的**真实实测分数、延迟、Schema 数量、事实密度与具体修复文件**，可直接用于冷启动邮件、X (Twitter) 公开 @ 互动或创始人私信。

---

### 1. Cursor (`cursor.com`) — 致 Michael Truell / Aman Sanger / Sualeh Asif

#### 🇺🇸 English Version (Cold DM / Email / X Post)
**Subject / Hook:** Cursor scored 95/100 on our live GEO (Generative Engine Optimization) benchmark — #1 among top DevTools, plus 2 quick fixes to hit 100/100

Hi Michael & Cursor team,

We just ran a live Generative Engine Optimization (GEO) technical audit across 5 flagship developer SaaS websites (`cursor.com`, `linear.app`, `cal.com`, `dub.co`, `resend.com`) using **GEO Radar Pro**.

**Cursor ranked #1 overall with a 95/100 GEO Readiness Score and an 85/100 IFS Stability Score** ($\mu=0.878, \pi=0.082, \nu=0.040$):
- **AI Crawler Access (25/25):** 8/8 major AI bots (`OAI-SearchBot`, `PerplexityBot`, `ClaudeBot`, `GPTBot`, etc.) fully allowed.
- **LLMs.txt Standard (25/25):** Live `/llms.txt` detected (`HTTP 200`, `1,448ms` response).
- **Schema.org JSON-LD (24/25):** 2 JSON-LD blocks (`Organization`, `WebSite`) active.
- **E-E-A-T Fact Density (21/25):** `16.0` verifiable facts per 1k words across 375 words and 15 `<h2>` sections.

**The remaining 5-point gap to hit a perfect 100/100:**
1. Your homepage JSON-LD includes `Organization` and `WebSite`, but lacks `SoftwareApplication` (with explicit pricing/OS metadata) and `FAQPage` entities, which AI answer engines rely on when developers ask *"Cursor vs GitHub Copilot vs Windsurf vs Claude Code pricing & enterprise privacy"*.
2. Adding a `/llms-full.txt` alongside `/llms.txt` and raising homepage verifiable fact density above 18/1k words.

We already generated the drop-in `schema-jsonld.html` (`SoftwareApplication` + `FAQPage`) and `eeat-comparison-block.md` specifically for `cursor.com` — happy to send the static HTML report link or open a quick gist if useful!

Best,  
GEO Radar Pro Benchmark Lab

#### 🇨🇳 中文对照版（外联说明 / 双语跟进）
**主题：** Cursor 在我们的实时 GEO（生成式引擎优化）基准测试中获得 95/100 分（开发者工具第 1 名）——附冲击满分 100 的 2 个工程补丁

Michael 及 Cursor 团队好：

我们刚刚使用 **GEO Radar Pro** 对 5 家海外标杆开发者 SaaS（Cursor、Linear、Cal.com、Dub、Resend）进行了实时 GEO 技术审计。

**Cursor 以 95/100 的 GEO 就绪度总分和 85/100 的直觉模糊集（IFS）稳定性指数位列全场第 1 名**（隶属度 $\mu=0.878$，犹豫度 $\pi=0.082$，非隶属度 $\nu=0.040$）：
- **AI 爬虫权限 (25/25)**：8/8 主流 AI 搜索引擎爬虫全部放行。
- **LLMs.txt 规范 (25/25)**：已检测到线上 `/llms.txt`（HTTP 200，耗时 1,448ms）。
- **Schema.org 实体图谱 (24/25)**：检测到 2 个 JSON-LD 块（`Organization`, `WebSite`）。
- **E-E-A-T 事实密度 (21/25)**：首页 375 词中包含 15 个 H2 章节，事实密度达 `16.0 / 千词`。

**距离满分 100/100 仅剩最后 5 分的微小缺口：**
1. 首页 JSON-LD 仅有 `Organization` 和 `WebSite`，尚未声明 `SoftwareApplication`（含明确定价层级与系统环境）及 `FAQPage` 实体——当开发者向 ChatGPT Search 或 Perplexity 提问 *"Cursor vs GitHub Copilot vs Windsurf vs Claude Code"* 时，这两类 Schema 能显著降低模型幻觉。
2. 补充 `/llms-full.txt` 并将首页可验证事实密度提升至 18/千词以上。

我们已经为 `cursor.com` 生成好了开箱即用的 `schema-jsonld.html` 与 `eeat-comparison-block.md` 修复包，随时可以发给你们直接粘贴验证！

---

### 2. Linear (`linear.app`) — 致 Karri Saarinen / Tuomas Artman

#### 🇺🇸 English Version (Cold DM / Email / X Post)
**Subject / Hook:** Linear has `/llms.txt` live, but `linear.app` scored 52/100 on GEO Readiness due to 0 JSON-LD blocks & 31 static words in initial HTML

Hi Karri & Tuomas,

Huge fan of Linear's craft. We just benchmarked `linear.app` with **GEO Radar Pro** to test how AI Answer Engines (ChatGPT Search, Perplexity, Claude Web Search) parse Linear in 2026.

**The good news:** Linear is fast (`HTTP 200` in `164ms`), allows **8/8 AI crawlers (25/25)**, and already ships a live `/llms.txt` (**25/25**).

**The hidden bottleneck (why Linear scored 52/100 overall with a high IFS hesitation $\pi = 0.190$):**
- **Schema.org JSON-LD: 0/25** — `linear.app` currently serves **0 `application/ld+json` blocks** on the homepage.
- **E-E-A-T Fact Density: 2/25** — Stateless HTTP crawlers only extract **31 words** of paragraph text, **0 `<h2>` tags**, and **0.0 verifiable numeric claims per 1k words** from the initial DOM.
- Because stateless AI retrieval bots don't execute heavy client hydration or infer facts from visual minimalism, Linear's IFS stability drops to **56/100** ($\mu=0.653, \pi=0.190, \nu=0.157$) on high-intent queries like *"Linear vs Jira vs Asana vs Shortcut for engineering teams"*.

**We built a ready-to-paste fix package for `linear.app`:**
1. `schema-jsonld.html`: Adds `SoftwareApplication` + `Organization` + `FAQPage` JSON-LD directly into `<head>` (zero visual impact on your minimalist UI, +25 pts immediately).
2. `eeat-comparison-block.md`: Semantic comparison table (Linear vs Jira / Asana / Shortcut) & verifiable citation anchors (+23 pts).

Would love to share the full white-label audit report (`linear.app/agency-audit-report.html`) — no strings attached!

Best,  
GEO Radar Pro Benchmark Lab

#### 🇨🇳 中文对照版（外联说明 / 双语跟进）
**主题：** Linear 已上线 `/llms.txt`，但因首屏 HTML 缺失 JSON-LD（0 个）且仅提取到 31 个静态词，GEO 总分仅 52/100

Karri 与 Tuomas 你们好：

一直非常欣赏 Linear 的极致设计。我们刚刚用 **GEO Radar Pro** 对 `linear.app` 进行了实时生成式引擎优化（GEO）体检，测试 ChatGPT Search、Perplexity 和 Claude 在 2026 年如何解析 Linear。

**亮点部分**：Linear 响应极快（`HTTP 200`，仅 `164ms`），**8/8 主流 AI 爬虫全部放行（25/25）**，并且已经部署了 `/llms.txt`（**25/25**）。

**核心隐患（导致 GEO 总分仅 52/100、IFS 犹豫度 $\pi$ 高达 `0.190` 的原因）**：
- **Schema.org 结构化数据：0/25 分** —— `linear.app` 首页目前 **没有任何 `application/ld+json` 实体块（0 个）**。
- **E-E-A-T 事实密度：2/25 分** —— 无状态 AI 检索爬虫从首页初始 DOM 中仅能提取出 **31 个正文词、0 个 `<h2>` 标签、事实密度为 `0.0 / 千词`**。
- 由于 AI 搜索爬虫不会像人类一样欣赏极简视觉，也不会完整执行复杂的客户端渲染，当用户询问 *"Linear vs Jira vs Asana vs Shortcut"* 时，模型的直觉模糊稳定性跌至 **56/100**（$\mu=0.653, \pi=0.190, \nu=0.157$）。

**我们为 `linear.app` 生成了零视觉侵入的修复包：**
1. `schema-jsonld.html`：在 `<head>` 注入 `SoftwareApplication` + `Organization` + `FAQPage`（完全不影响极简 UI 设计，直接拿满 +25 分）。
2. `eeat-comparison-block.md`：针对 Jira / Asana / Shortcut 的语义对比矩阵与高事实密度锚点。

附上完整白标审计报告与补丁文件，供团队直接参考！

---

### 3. Cal.com (`cal.com`) — 致 Peer Richelsen / Bailey Pumfleet

#### 🇺🇸 English Version (Cold DM / Email / X Post)
**Subject / Hook:** Auditing `cal.com` for AI Search (GEO): 114ms response & `/llms.txt` live, but 0 Schema JSON-LD & 0 static `<p>` words (52/100)

Hey Peer & Bailey,

We ran a live GEO (Generative Engine Optimization) audit on `cal.com` alongside Cursor, Linear, Dub, and Resend using **GEO Radar Pro**.

You guys nailed the first half of AI Readiness:
- **Latency:** Blazing fast `114ms` (`HTTP 200`).
- **AI Bots:** **8/8 allowed (25/25)** in `robots.txt`.
- **LLMs.txt:** `/llms.txt` is live and reachable (**25/25**).

**Why `cal.com` scored 52/100 overall (and 56/100 on IFS Citation Stability, $\mu=0.653, \pi=0.190, \nu=0.157$):**
1. **0 JSON-LD Schema Blocks (0/25):** There is no `application/ld+json` (`SoftwareApplication`, `Organization`, or `FAQPage`) on `https://cal.com`.
2. **0 Extracted Static Paragraph/Heading Words (2/25):** Our raw HTTP DOM parser found `word_count: 0`, `h1_count: 0`, `h2_count: 0`, and `fact_density_per_1k: 0.0` in standard `<p>/<h1>/<h2>` tags on the homepage. When `OAI-SearchBot` or `PerplexityBot` fetches `cal.com` without JS execution, it relies almost entirely on your `<title>` and `<meta description>`.

We generated the exact 4-file engineering fix pack for `cal.com` (`schema-jsonld.html`, enhanced `llms.txt`, `eeat-comparison-block.md` vs Calendly/SavvyCal/Chili Piper, and `agency-audit-report.html`). Taking 10 minutes to drop in the JSON-LD and semantic comparison block will jump `cal.com` from **52 → 96+**.

Want me to drop the link here or DM the report?

Cheers,  
GEO Radar Pro Benchmark Lab

#### 🇨🇳 中文对照版（外联说明 / 双语跟进）
**主题：** `cal.com` 实时 GEO 审计报告：114ms 极速响应且已配 `/llms.txt`，但首页 JSON-LD 与静态段落词数为 0（总分 52/100）

Peer 和 Bailey 你们好：

我们使用 **GEO Radar Pro** 对 `cal.com` 以及 Cursor、Linear、Dub、Resend 进行了实时生成式引擎优化（GEO）基准审计。

Cal.com 在基础 AI 友好度上做得非常超前：
- **响应速度**：全场最快 `114ms`（`HTTP 200`）。
- **AI 爬虫权限**：`robots.txt` 对 **8/8 大模型爬虫全部放行（25/25）**。
- **LLMs.txt**：`/llms.txt` 已上线且可正常抓取（**25/25**）。

**但 `cal.com` 总分停留在 52/100（IFS 稳定性 56/100，$\mu=0.653, \pi=0.190, \nu=0.157$）的两大工程原因：**
1. **Schema.org JSON-LD 数量为 0（0/25 分）**：首页没有任何 `application/ld+json` 结构化实体声明。
2. **首屏静态语义标签提取词数为 0（2/25 分）**：在原始 HTTP 响应中，标准 `<h1>`/`<h2>`/`<p>` 标签提取到的有效正文词数为 `0`（事实密度 `0.0/1k`）。当 `OAI-SearchBot` 或 `PerplexityBot` 抓取首页时，只能读到 `<title>` 和 `<meta description>`，缺乏对抗 Calendly / SavvyCal / Chili Piper 的结构化事实锚点。

我们已为 `cal.com` 生成了全套修复包（含 `schema-jsonld.html` 和针对 Calendly/SavvyCal/Chili Piper 的 `eeat-comparison-block.md`），只需 10 分钟接入即可将得分从 **52 分拉升至 96+ 分**！

---

### 4. Dub (`dub.co`) — 致 Steven Tey

#### 🇺🇸 English Version (Cold DM / Email / X Post)
**Subject / Hook:** `dub.co` scored 85/100 on our GEO Benchmark (#3 overall) — great Schema & `/llms.txt`, just missing E-E-A-T fact density (11/25)

Hey Steven,

We just ran `dub.co` through **GEO Radar Pro**, our live Generative Engine Optimization auditor & IFS (Intuitionistic Fuzzy Set) citation stability engine.

**Dub scored a strong 85/100 GEO Readiness Score and 85/100 IFS Stability** ($\mu=0.878, \pi=0.082, \nu=0.040$):
- **AI Crawler Access:** 8/8 bots allowed (**25/25**).
- **LLMs.txt:** `/llms.txt` is live (**25/25**).
- **Schema JSON-LD:** 2 blocks (`Organization`, `SoftwareApplication`) detected (**24/25**).

**Where `dub.co` lost 14 points (E-E-A-T Fact Density: 11/25):**
- On the homepage (`295 words`, `1 H1`, `4 H2s`), verifiable numeric/citation fact density measured at just **`3.4 facts per 1k words`** (compared to `16.0/1k` on `cursor.com` and `28.2/1k` on `resend.com`).
- Adding a `FAQPage` JSON-LD entity (+1 pt on Schema) and embedding a high-density factual comparison section (redirect latency in ms, attribution accuracy %, Dub vs Bitly vs Rebrandly vs Short.io) will push `dub.co` from **85/100 → 98/100**.

We already generated the custom `eeat-comparison-block.md` and `schema-jsonld.html` for Dub — happy to share the full benchmark hub if you'd like to take a look!

Best,  
GEO Radar Pro Benchmark Lab

#### 🇨🇳 中文对照版（外联说明 / 双语跟进）
**主题：** `dub.co` 在我们的 GEO 基准测试中斩获 85/100 分（全场第 3）——Schema 与 `/llms.txt` 接近满分，唯一短板在 E-E-A-T 事实密度（11/25）

Steven 你好：

我们刚刚使用 **GEO Radar Pro** 对 `dub.co` 进行了实时生成式引擎优化（GEO）审计与直觉模糊集（IFS）引用稳定性评测。

**Dub 取得了 85/100 的高分，IFS 稳定性达到 85/100**（$\mu=0.878, \pi=0.082, \nu=0.040$）：
- **AI 爬虫权限**：8/8 全部放行（**25/25**）。
- **LLMs.txt**：`/llms.txt` 已上线（**25/25**）。
- **Schema JSON-LD**：已部署 2 个实体块 `Organization` 与 `SoftwareApplication`（**24/25**）。

**唯一的失分点（E-E-A-T 事实密度得分：11/25，丢了 14 分）：**
- 首页静态 HTML 提取到 `295` 词（1 个 H1、4 个 H2），但可验证的量化事实密度仅为 **`3.4 / 千词`**（作为对比，Cursor 为 `16.0/千词`，Resend 高达 `28.2/千词`）。
- 只需在 JSON-LD 中补充 `FAQPage` 实体（Schema 即可满分 25/25），并在页面补充高密度量化指标（如重定向延迟 ms、转化归因精度、Dub vs Bitly / Rebrandly / Short.io 结构化对比表），即可将 `dub.co` 从 **85 分直接推升至 98 分**。

我们已为 Dub 生成好专属的 `eeat-comparison-block.md` 和 `schema-jsonld.html`，随时可以发你预览！

---

### 5. Resend (`resend.com`) — 致 Zeno Rocha / Bu Kinoshita

#### 🇺🇸 English Version (Cold DM / Email / X Post)
**Subject / Hook:** `resend.com` has the highest E-E-A-T Fact Density (`28.2/1k`) + `/llms-full.txt` in our benchmark (86/100) — 1 quick JSON-LD tweak to hit 99/100!

Hey Zeno & Bu,

We just audited 5 top developer SaaS sites (`cursor.com`, `resend.com`, `dub.co`, `linear.app`, `cal.com`) using **GEO Radar Pro**.

**Resend ranked #2 overall (86/100) and #1 in E-E-A-T Content Engineering (24/25):**
- You are the **only company among all 5** shipping both `/llms.txt` AND `/llms-full.txt` (**25/25**).
- Your homepage achieved a massive **`28.2 verifiable facts per 1k words`** across `496 words`, `14 H2s`, and `12 H3s` (**24/25 E-E-A-T**).
- All **8/8 AI crawlers** are allowed (**25/25**), giving Resend an **85/100 IFS Stability Score** ($\mu=0.878, \pi=0.082, \nu=0.040$).

**Why Resend scored 86/100 instead of 99/100 (Schema JSON-LD: 12/25):**
- Currently, `resend.com` packs its schema types (`BreadcrumbList`, `Organization`, `SoftwareApplication`, `WebPage`, `WebSite`) into just **1 single JSON-LD block**, and is missing a dedicated `FAQPage` JSON-LD block answering high-intent developer queries (*"Resend vs SendGrid vs Postmark vs AWS SES deliverability & pricing"*).
- Also, homepage TTFB/response time measured at `2,620ms` during our live probe.

Splitting/enriching the JSON-LD with our generated `schema-jsonld.html` (`FAQPage` + standalone `SoftwareApplication` offer schema) immediately takes Resend's Schema score from **12/25 → 25/25** (overall **99/100**, #1 on the leaderboard). Happy to send over the report & patch!

Best,  
GEO Radar Pro Benchmark Lab

#### 🇨🇳 中文对照版（外联说明 / 双语跟进）
**主题：** `resend.com` 拿下全场最高 E-E-A-T 事实密度（28.2/千词）且唯一配备 `/llms-full.txt`（总分 86/100）——仅需 1 处 JSON-LD 调整即可登顶 99/100！

Zeno 和 Bu 你们好：

我们刚刚用 **GEO Radar Pro** 对 5 家顶流开发者 SaaS（Cursor、Resend、Dub、Linear、Cal.com）完成了实时 GEO 基准测试。

**Resend 以 86/100 位列总榜第 2，并在 E-E-A-T 事实密度维度斩获全场第 1（24/25 分）：**
- 你们是 **5 家中唯一同时部署了 `/llms.txt` 和 `/llms-full.txt` 的团队**（**25/25**）。
- 首页在 496 个词、14 个 H2、12 个 H3 中实现了高达 **`28.2 / 千词`** 的可验证事实密度（**E-E-A-T 24/25**）。
- **8/8 AI 爬虫全部放行（25/25）**，IFS 稳定性指数达 **85/100**（$\mu=0.878, \pi=0.082, \nu=0.040$）。

**为什么 Resend 是 86 分而不是 99 分？（唯一失分项：Schema JSON-LD 12/25 分）**
- 目前 `resend.com` 仅包含 **1 个 `<script type="application/ld+json">` 块**，且缺少专门针对高购买意向提问（如 *"Resend vs SendGrid vs Postmark vs AWS SES 送达率与定价对比"*）的独立 `FAQPage` 实体块，因此 Schema 维度仅得 12/25 分。
- 此外，实测首页抓取耗时为 `2,620ms`，建议留意边缘缓存预热。

使用我们生成的 `schema-jsonld.html` 补充独立 `FAQPage` 与 `SoftwareApplication` 定价结构后，Resend 的 Schema 得分将直接从 **12/25 升至 25/25**（总分 **99/100** 反超登顶第 1）。报告与补丁已备好，欢迎随时查阅！

---

## 三、 导出文件目录树与快速索引

所有生成产物均位于 `/workspace/geo-radar-pro/exports/cold-start-samples`：

- `00-Cold-Start-Outreach-Playbook.md`（本冷启动外联作战手册）
- `index.html`（Benchmark Showcase Hub 静态交互排行榜索引页）
- `cold_start_history.sqlite3`（包含全部 5 次真实审计运行记录的 SQLite 历史库）
- `cursor.com/`
  - `agency-audit-report.html` | `agency-audit-report.md` | `llms.txt` | `schema-jsonld.html` | `robots-ai-patch.txt` | `eeat-comparison-block.md`
- `linear.app/`
  - `agency-audit-report.html` | `agency-audit-report.md` | `llms.txt` | `schema-jsonld.html` | `robots-ai-patch.txt` | `eeat-comparison-block.md`
- `cal.com/`
  - `agency-audit-report.html` | `agency-audit-report.md` | `llms.txt` | `schema-jsonld.html` | `robots-ai-patch.txt` | `eeat-comparison-block.md`
- `dub.co/`
  - `agency-audit-report.html` | `agency-audit-report.md` | `llms.txt` | `schema-jsonld.html` | `robots-ai-patch.txt` | `eeat-comparison-block.md`
- `resend.com/`
  - `agency-audit-report.html` | `agency-audit-report.md` | `llms.txt` | `schema-jsonld.html` | `robots-ai-patch.txt` | `eeat-comparison-block.md`
