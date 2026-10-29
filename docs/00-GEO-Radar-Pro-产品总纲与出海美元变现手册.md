# GEO Radar Pro for macOS —— 产品总纲、核心算法壁垒与出海美元变现手册

> **立项日期**：2026-10-27（最近更新：2026-10-29）
> **负责人**：于祥雨（Xiangyu Yu）
> **专属协同 Bot**：`@GEO Radar Pro · 出海AI搜索优化台`
> **工程代码仓（Mac）**：`/Users/yu/work/apple-apps/apps/geo-radar-pro/`
> **GitHub 开源/分发仓**：`https://github.com/xiangyuyu819/geo-radar-pro`
> **产品官网（GitHub Pages）**：`https://xiangyuyu819.github.io/geo-radar-pro/`
> **海外 SaaS 实测榜单**：`https://xiangyuyu819.github.io/geo-radar-pro/benchmarks/`
> **全球美元收单平台（MoR）**：**Creem.io**（已替代不支持中国大陆激活的 Lemon Squeezy，当前商品 ID：`prod_7cTQkYazbYag7X024VRE45`）
> **原生客户端包**：`/Users/yu/work/apple-apps/apps/geo-radar-pro/GEORadarPro.app`（及 `dist/GEORadarPro-v1.0.0-macOS.dmg`）
> **导出工程包目录**：`/Users/yu/work/apple-apps/apps/geo-radar-pro/exports/`
> **Obsidian 知识库路径**：`/Users/yu/myObsidian/个人事务/5-自研产品/Apple独立开发/GEO-Radar-Pro/`

---

## 一、 为什么「无自有存量数据库」反而能做成海外暴利硬产品？

1. **传统 SEO vs. 生成式引擎优化（GEO）的底层差异**：
   - 传统 SEO（Ahrefs / Semrush）需要预先爬取并索引百亿级网页与反向链接库，服务器成本高达数百万美元/年，个人开发者无法入局。
   - **GEO（Generative Engine Optimization）的本质是“实时探针 + 目标站点实时结构化诊断”**：
     - **站点侧数据**：用户输入自己或客户的网址后，客户端当场并发抓取目标网页 HTML、`/robots.txt`、`/llms.txt`、`/llms-full.txt`、`/sitemap.xml` 与 `Schema.org JSON-LD` 实体图谱；
     - **模型侧数据**：通过 **BYOK（Bring Your Own API Key）** 直接在用户本地 Mac 发起 OpenAI / Perplexity (`sonar`) / Claude / Gemini / DeepSeek 实时探测，无需开发者承担一分钱云端服务器、住宅代理池或 Token 成本。

2. **2026 海外竞品真实价格锚点（你的高利润保护伞）**：
   - **Otterly.AI**：Lite $29/月（仅 15 个词）、Standard **$189/月**（100 个词）、Premium **$489/月**（400 个词）；
   - **Peec AI**：Starter **$95/月**（50 个词）、Pro **$245/月**、Advanced **$495/月**；
   - **Profound**：Starter **$99/月**（仅单引擎）、Growth **$399/月**（100 个词）。
   - **GEO Radar Pro 定价策略（通过 Creem.io 全球收单与自动发码）**：
     - **Indie / Founder 终身买断版**：**$69 Lifetime**（无限站点审计、BYOK 无限 Prompt 探测、一键生成 `llms.txt` + `JSON-LD`）；
     - **Agency 代理商白标版**：**$149 Lifetime**（支持一键导出带代理商名称的英文客户白标 HTML/PDF 审计报告与 6 件套修复代码包）。

---

## 二、 三大硬核技术壁垒（别人周末抄不走的护城河）

### 1. 直觉模糊集（IFS）AI 推荐稳定性量化引擎（源自 `ifs-llm-uncertainty`）
- 普通工具只跑单次关键词匹配，忽略了 LLM 生成随温度与 Prompt 微扰产生的剧烈波动。
- `GEO Radar Pro` 对每个高购买意图 Prompt 在多温度（$T \in \{0.2, 0.5, 0.8\}$）下计算直觉模糊三元组 $(\mu, \nu, \pi)$：
  - **隶属度 $\mu$（Citation Membership）**：品牌在 Top-3 核心位置被正面推荐与引用的概率；
  - **非隶属度 $\nu$（Omission / Competitor Takeover）**：品牌被完全忽略或被竞品压制的概率；
  - **犹豫度 $\pi = 1 - \mu - \nu$（Cross-Engine Hesitation）**：不同模型或多次采样之间的摇摆程度（当网站缺失 `/llms.txt` 或 `JSON-LD` 时，$\pi$ 显著升高）。
  - **IFS 综合稳定指数**：$S_{\text{IFS}} = \text{clip}\left(\text{round}(100\mu - 35\nu - 20\pi),\; 5,\; 99\right)$。

### 2. 实时 8 大 AI 爬虫权限矩阵与 E-E-A-T 信源密度审计
- 实时解析 `/robots.txt` 对 8 大核心 AI 搜索爬虫（`GPTBot`, `OAI-SearchBot`, `ChatGPT-User`, `PerplexityBot`, `ClaudeBot`, `Google-Extended`, `Applebot-Extended`, `CCBot`）的放行状态；
- 自动统计页面每千词定量事实密度（Quantitative Fact Density per 1k words）、H1–H3 语义层级与 `application/ld+json` 实体覆盖度。

### 3. 一键可落地的「GEO 修复工程包（Actionable Fixer Pack 6 件套）」
- 诊断完直接产出 6 个可部署到客户网站根目录或直接交付给甲方的工程文件：
  1. 符合 `llmstxt.org` 2026 规范的 **`llms.txt`**；
  2. 包含 `Organization` + `SoftwareApplication` + `FAQPage` 的 **`schema-jsonld.html`** 实体脚本；
  3. 精准放行 AI 搜索引用爬虫的 **`robots-ai-patch.txt`** 补丁；
  4. 针对核心竞品的 **`eeat-comparison-block.md`** 结构化对比表格；
  5. 客户白标 Markdown 深度体检报告 **`agency-audit-report.md`**；
  6. 支持浏览器一键 `Cmd+P` 打印高颜值 PDF 的白标报告 **`agency-audit-report.html`**。

---

## 三、 本地一键编译、打包与运行指令（零 Xcode 依赖）

```bash
# 1. 单独测试 Python GEO 核心审计引擎（支持多温度采样与白标署名）
python3 /Users/yu/work/apple-apps/apps/geo-radar-pro/scripts/geo_engine.py \
  --url "https://cursor.com" \
  --brand "Cursor" \
  --category "AI Code Editor & Developer IDE" \
  --competitors "GitHub Copilot,Windsurf,Claude Code" \
  --samples 3 \
  --agency-name "Apex Growth GEO Agency" \
  --client-name "Cursor Inc."

# 2. 一键重新编译并启动原生 macOS 客户端 GEORadarPro.app
/Users/yu/work/apple-apps/02-scripts/build_mac_app.sh \
  /Users/yu/work/apple-apps/apps/geo-radar-pro \
  GEORadarPro \
  com.yuxiangyu.georadarpro
open /Users/yu/work/apple-apps/apps/geo-radar-pro/GEORadarPro.app

# 3. 一键生成分发级 .dmg 与 .zip 安装包及 SHA-256 校验文件
cd /Users/yu/work/apple-apps/apps/geo-radar-pro && bash scripts/package_release.sh
```

---

## 四、 Obsidian 知识库专题文档目录（`GEO-Radar-Pro/`）

1. **`00-GEO-Radar-Pro-产品总纲与出海美元变现手册.md`**（本文档：核心定位、算法壁垒与全局导航）
2. **`01-ProductHunt-Launch-Kit.md`**（Product Hunt 首发 Tagline、Maker 首评、5 张 1270×760 宣传图脚本与 X 造势帖）
3. **`02-LemonSqueezy-Pricing-and-Store-Copy.md`**（英文高转化商品详情页文案、6 大 FAQ 与 Swift License Manager 原始架构蓝图）
4. **`03-GitHub-README.md`**（GitHub 开源/分发仓库英文 README 全文）
5. **`04-Cold-Start-Outreach-Playbook.md`**（5 大海外知名 SaaS 实测榜单、X 一键 `@创始人` 破冰链接与 Reddit `r/SaaS` `r/SEO` 引流帖）
6. **`05-Creem-io-出海收款与产品管理全流程指南.md`**（**主力收单手册**：Creem.io 大陆身份证 KYC、商品与 License Key 管理、合规审核 4 要素、Test Mode 切 Live Mode 操作步骤与支付宝/银行卡提现全流程）
