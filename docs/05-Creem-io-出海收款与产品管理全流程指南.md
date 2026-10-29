# GEO Radar Pro — Creem.io 出海美元收款、商品管理与激活码闭环全流程指南

> **归档日期**：2026-10-29
> **适用项目**：`GEO Radar Pro for macOS` 及后续 Apple 独立开发出海软件（macOS / iOS 官网直售版）
> **负责人**：于祥雨（Xiangyu Yu）
> **当前收单平台**：[Creem.io](https://www.creem.io)（Merchant of Record 全球税务代缴 + 内置 License Key 授权码自动发放 + 支持中国大陆身份证 KYC 与支付宝/银行卡结汇提现）
> **当前测试商品 ID**：`prod_7cTQkYazbYag7X024VRE45`
> **当前收银台链接**：`https://www.creem.io/payment/prod_7cTQkYazbYag7X024VRE45`
> **关联官网地址**：`https://xiangyuyu819.github.io/geo-radar-pro/`
> **售后支持邮箱**：`xiangyuyu819@yeah.net`

---

## 一、 为什么选择 Creem.io 替代 Lemon Squeezy？

在 Apple 独立开发出海（尤其是 macOS 桌面软件官网直售 `.dmg` + License Key 商业模式）中，支付与授权码平台（Merchant of Record, MoR）选型直接决定能否顺利收款：

| 维度 | Lemon Squeezy（已被 Stripe 收购） | Creem.io（当前主力方案） |
| :--- | :--- | :--- |
| **中国大陆开发者支持** | ❌ **不支持**（Store 激活列表中已移除 China，无海外公司无法开店） | ✅ **原生支持中国大陆个人开发者**（支持中国二代居民身份证实名 KYC） |
| **全球税务合规（MoR）** | ✅ 自动代收代缴欧盟 VAT / 美国州税 | ✅ 作为官方 Merchant of Record 自动处理全球 VAT / Sales Tax |
| **软件激活码（License Key）** | ✅ 内置生成与 API 校验 | ✅ **原生内置 `Delivery -> License key`**，付款即在收银台与邮件自动发码 |
| **提现回国方式（Payouts）** | 仅支持 Stripe 支持地区银行账户或 PayPal | ✅ **支持支付宝（Alipay）、国内银行卡跨境电汇（Bank Wire）、Payoneer** |
| **平台费率** | 5% + $0.50 | **3.9% + $0.40**（同类 MoR 平台中费率更低） |

---

## 二、 Creem.io 账号注册、建店与大陆身份证 KYC 标准操作步骤（SOP）

### Step 1：注册与创建店铺（Create Store）
1. 访问 `https://www.creem.io` 注册并登录后台。
2. 创建店铺（Store）：
   - **Store Name**：`GEO Radar Pro`
   - **Store URL / Website**：`https://xiangyuyu819.github.io/geo-radar-pro/`
   - **Support Email**：`xiangyuyu819@yeah.net`
   - **Default Currency**：`USD ($)`

### Step 2：填写合规问卷（Compliance — What You Sell）
在 Creem 后台 **Compliance / Onboarding** 页面填写业务说明时，使用标准英文合规模板，确保一次性通过人工风控审核：

- **Product Type / Category**：`Software / SaaS / macOS Desktop Application`
- **What you sell（售卖内容说明标准话术）**：
  ```text
  We develop and sell GEO Radar Pro for macOS, a native macOS desktop software workbench for Generative Engine Optimization (GEO) and technical SEO auditing. Customers purchase a one-time software license key ($69 Indie Edition or $149 Agency White-Label Edition) to unlock local website crawler diagnostics, multi-temperature LLM citation stability analysis, and automated generation of llms.txt and Schema.org JSON-LD configuration files. The software is immediately downloadable from our official website and GitHub Releases, and license keys are delivered automatically upon purchase via Creem.
  ```

### Step 3：完成中国大陆个人身份认证（Identity Verification / KYC）
1. 进入 **Compliance -> Identity Verification**，点击跳转认证页面。
2. **Country / Region**：选择 `China (CHN)`。
3. **Document Type**：选择 `National ID Card（居民身份证）`。
4. **姓名填写规范**：
   - **First Name（名）**：`Xiangyu`
   - **Last Name（姓）**：`Yu`
   - *(注意：切勿把姓和名填反，必须与身份证拼音顺序一致)*
5. 上传身份证人像面与国徽面清晰照片，并按提示完成人脸活体自拍校验。

---

## 三、 Creem.io 商品创建与 License Key 授权码管理规范

> ⚠️ **核心机制提醒**：Creem 后台左下角有 **`Test Mode`（测试沙盒模式）** 开关。
> - **Test Mode 开启时**创建的商品（如当前的 `prod_7cTQkYazbYag7X024VRE45`）仅用于开发联调与测试卡模拟支付，**不能刷真实买家的信用卡**。
> - **店铺审核通过（Approved）后**，必须在左下角**关闭 `Test Mode`** 切换到正式环境（Live Mode），并在正式环境下重新创建正式商品！

### 1. 商品基础信息配置（Products -> New Product）

建议在正式环境（Live Mode）下分别创建两个独立买断制商品，对应官网定价区的两个购买按钮：

#### 商品 A：个人版（Indie / In-House Pro — `$69`）
- **Name**：`GEO Radar Pro — Indie Edition (macOS Lifetime License)`
- **Billing Type**：选择 **`One-time`**（一次性买断，切勿选 Recurring 订阅制）
- **Price**：`69.00` (`USD`)
- **Description（商品描述，支持 Markdown）**：
  ```markdown
  Native macOS Generative Engine Optimization (GEO) & AI Search Readiness Workbench.
  - 1 Mac device activation (Lifetime License, Bring Your Own API Key)
  - Real-time 8 AI Crawler Permission Matrix (`GPTBot`, `OAI-SearchBot`, `PerplexityBot`, `ClaudeBot`, etc.)
  - 6-Prompt Multi-Temperature IFS (μ, π, ν) Citation Stability Engine
  - 1-Click Actionable Fixer Studio: export deployable `llms.txt`, `Schema.org JSON-LD`, `robots.txt` AI bot patches, and E-E-A-T comparison blocks
  - Local SQLite longitudinal audit history (`geo_radar_history.sqlite3`)
  ```
- **Product Image**：上传 `/Users/yu/work/apple-apps/apps/geo-radar-pro/assets/ph-gallery/01-hero-overview.png`（1270×760 高清主图）。

#### 商品 B：机构白标版（Agency White-Label Edition — `$149`）
- **Name**：`GEO Radar Pro — Agency White-Label Edition (3 Macs)`
- **Billing Type**：选择 **`One-time`**
- **Price**：`149.00` (`USD`)
- **Description**：
  ```markdown
  Full Agency & Consultant White-Label Edition of GEO Radar Pro for macOS.
  - Up to 3 Mac activations across your agency or team
  - Everything in Indie Edition, plus full commercial client audit rights
  - Custom `--agency-name` and `--client-name` white-label branding controls
  - 1-Click export of watermark-free, print-ready White-Label HTML/PDF & Markdown Client Audit Reports (`agency-audit-report.html`)
  ```

### 2. 开启自动发放激活码（Delivery -> License Key）
在创建或编辑商品的弹窗中，切换到顶部/中部的 **`Delivery`**（或 **`Features`**）标签页：
1. 找到 **`License key`** 开关并**打开（Enable）**。
2. **Activation Limit（激活设备数上限）**：
   - `$69 Indie Edition` 设为 `1`（或宽限设为 `2` 方便用户台式机+笔记本）；
   - `$149 Agency Edition` 设为 `3`（或 `5`）。
3. **Expiration（有效期）**：选择 `Never expires / Unlimited`（终身有效）。
4. 点击 **Create / Update Product** 保存后，在商品详情页右上角点击 **`Copy Payment Link`**，即可获得形如 `https://www.creem.io/payment/prod_xxxxxxxxx` 的收银台直链。

### 3. 优惠码配置（Discounts -> New Discount）
用于 Product Hunt 首发、X 评论区冷启动或邮件早鸟促销：
- **Discount Code**：`PHLAUNCH20`
- **Type**：`Percentage` -> `20% OFF`（折后 Indie 版 `$55.20`，Agency 版 `$119.20`）
- **Applicable Products**：勾选上述两个商品。

---

## 四、 Creem 店铺人工审核必查的 4 项官网合规要素（Checklist）

Creem 审核员在审批店铺（将账号从 Test Mode 解锁为 Live Mode）时，会人工打开你提交的官网 `https://xiangyuyu819.github.io/geo-radar-pro/` 检查以下 4 项。**我们已在 `index.html` 中 100% 预置完毕，后续改版官网时切勿删除：**

1. **清晰的定价与交付形式说明**：
   - 明确标明 `$69` / `$149` 为 `One-Time Payment`（一次性买断），且写明系统要求为 `macOS 14.0+`。
2. **服务条款（Terms of Service，`#terms`）**：
   - 位于官网页脚 `#terms` 卡片，明确软件授权范围（Indie 1 台 Mac / Agency 3 台 Mac）及本地执行免责声明。
3. **隐私政策（Privacy Policy，`#privacy`）**：
   - 位于官网页脚 `#privacy` 卡片，明确 BYOK API Key 与 SQLite 历史数据均保存在用户本地 Mac，订单与税务由 Merchant of Record（Creem.io）处理。
4. **退款政策与售后联系邮箱（Refund Policy & Support Email，`#refund`）**：
   - 位于官网页脚 `#refund` 卡片，明确提供 **14-Day Satisfaction Guarantee（14 天无理由退款保障）**，并公开展示可点击的售后邮箱 `xiangyuyu819@yeah.net`。

---

## 五、 从 Test Mode 切换到正式收款（Live Mode）的 3 步代码更新手册

当 Creem 审核通过、你在后台关闭 `Test Mode` 并创建好正式商品后，拿到正式的 `prod_...` 链接，只需更新工程中的 **2 个文件**：

### 1. 更新 macOS 客户端（`Sources/GEORadarPro/main.swift`）
打开 `/Users/yu/work/apple-apps/apps/geo-radar-pro/Sources/GEORadarPro/main.swift`（第 491–492 行）：
```swift
static let defaultIndieCheckoutURL = "https://www.creem.io/payment/你的正式Indie版prod_ID"
static let defaultAgencyCheckoutURL = "https://www.creem.io/payment/你的正式Agency版prod_ID"
```
*(注：如果不改源码，也可以通过环境变量 `GEO_LS_INDIE_CHECKOUT_URL` 和 `GEO_LS_AGENCY_CHECKOUT_URL` 动态覆盖。)*

### 2. 更新官网购买按钮（`index.html` / `site/index.html` / `docs/index.html`）
将官网 Pricing 卡片中的 `href="https://www.creem.io/payment/prod_7cTQkYazbYag7X024VRE45"` 分别替换为正式版的 `$69` 和 `$149` 支付链接。

### 3. 一键重新打包 `.dmg` 并同步 GitHub Pages
在终端执行以下命令即可完成重编译、重打包与线上更新：
```bash
cd /Users/yu/work/apple-apps/apps/geo-radar-pro

# 1. 重新编译 GEORadarPro.app 并打包 .dmg / .zip
/Users/yu/work/apple-apps/02-scripts/build_mac_app.sh \
  /Users/yu/work/apple-apps/apps/geo-radar-pro \
  GEORadarPro \
  com.yuxiangyu.georadarpro
bash scripts/package_release.sh

# 2. 推送官网更新到 GitHub Pages 并更新 Release 安装包
git add Sources/GEORadarPro/main.swift index.html site/index.html docs/index.html dist/
git commit -m "chore(release): switch Creem checkout links to live production products"
git push origin main
gh release upload v1.0.0 dist/GEORadarPro-v1.0.0-macOS.dmg dist/GEORadarPro-v1.0.0-macOS.zip dist/SHA256SUMS.txt --clobber
```

---

## 六、 客户端 License Key 激活与 API 校验技术架构说明

在 `Sources/GEORadarPro/main.swift` 的 `LemonSqueezyLicenseManager` 中，我们采用了 **三级兼容校验架构**，兼顾安全性、用户体验与离线可用性：

1. **第一级：内置评测与自测激活码（Offline / Review Preset Keys）**
   - 方便开发者自测、Product Hunt 评测员或大 V 媒体免付体验：
   - **Indie 版测试码**：`GRP-INDIE-2026-PRO`（或任意以 `GRP-INDIE-` / `CREEM-INDIE-` 开头的 Key）
   - **Agency 白标版测试码**：`GRP-AGENCY-2026-VIP`（或任意以 `GRP-AGENCY-` / `CREEM-AGENCY-` 开头的 Key）

2. **第二级：Creem.io 官方激活码校验（`POST https://api.creem.io/v1/licenses/activate`）**
   - 当用户输入 Creem 发放的标准格式激活码（匹配正则 `^[A-Z0-9]{4,12}(-[A-Z0-9]{4,12}){2,5}$`）时：
   - 若配置了 `GEO_CREEM_API_KEY`，客户端直接向 `https://api.creem.io/v1/licenses/activate` 发起 POST 请求：
     ```json
     {
       "key": "XXXX-XXXX-XXXX-XXXX",
       "instance_name": "Yu-MacBook-Pro"
     }
     ```
   - 同时支持客户端本地格式校验与 `UserDefaults` 持久化缓存（`geo_ls_license_key`、`geo_ls_cached_tier`、`geo_ls_instance_id`），确保用户在无网/飞机环境下打开软件不会掉激活。

3. **第三级：权限门控（Feature Gating）边界**
   - **未激活（`Free Evaluation`）**：可免费运行站点实时探测、查看 8 大 AI 爬虫权限矩阵、查看 IFS $(\mu, \pi, \nu)$ 评分与修复代码预览（先让用户看到自己网站的分数有多低，激发购买欲）。
   - **已激活（`$69 Indie` / `$149 Agency`）**：解锁 `Export All 6 Fixer Files` 一键导出落盘、多温度采样，以及 `$149 Agency` 专属的自定义代理商名称（`--agency-name`）与无水印白标客户 HTML/PDF 报告一键打开。

---

## 七、 日常售后、订单管理与美元提现（Payouts）运维指南

1. **查看订单与客户激活码（Orders & Customers）**：
   - 登录 Creem 后台 -> **Orders**，可查看每一笔交易的买家邮箱、支付金额、税费明细及系统自动生成的 License Key。
2. **帮客户重置激活设备数或退款（License Management & Refunds）**：
   - 如果客户换了新电脑导致激活次数用满，进入 **Customers / Licenses** 找到该客户的 Key，点击 **Deactivate / Reset Instances** 即可。
   - 如果客户在 14 天内申请退款，在 **Orders** 中点击该笔订单的 **Refund**，Creem 会自动原路退回信用卡并自动吊销（Revoke）对应的 License Key。
3. **美元结汇提现（Payouts）**：
   - 进入 Creem 后台 **Payouts / Settings**，绑定你的收款账户（推荐优先绑定 **支付宝 Alipay** 或国内银行卡，小额美元结汇入账最快、手续费最低）。
   - Creem 按照结算周期将扣除 `3.9% + $0.40` 手续费后的净收入打入你的账户。
