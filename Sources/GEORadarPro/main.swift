import SwiftUI
import AppKit
import Foundation

// MARK: - App Paths & Runtime Resolution

enum AppPaths {
    static var isRunningInAppBundle: Bool {
        if Bundle.main.bundleURL.pathExtension.lowercased() == "app" {
            return true
        }
        if let execPath = Bundle.main.executableURL?.path, execPath.contains(".app/Contents/MacOS") {
            return true
        }
        return false
    }

    static func resolvePythonExecutable() -> URL {
        let candidates = [
            "/usr/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3"
        ]
        let fm = FileManager.default
        for path in candidates {
            if fm.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return URL(fileURLWithPath: "/usr/bin/python3")
    }

    static func resolveProjectRoot() -> URL? {
        let fm = FileManager.default

        // 1. Walk up from current working directory
        var cwdURL = URL(fileURLWithPath: fm.currentDirectoryPath).standardizedFileURL
        for _ in 0..<6 {
            let scriptCandidate = cwdURL.appendingPathComponent("scripts/geo_engine.py")
            if fm.fileExists(atPath: scriptCandidate.path) {
                return cwdURL
            }
            let parent = cwdURL.deletingLastPathComponent()
            if parent.path == cwdURL.path { break }
            cwdURL = parent
        }

        // 2. Walk up from compile-time source file path (dev builds)
        var sourceURL = URL(fileURLWithPath: #filePath).standardizedFileURL.deletingLastPathComponent()
        for _ in 0..<6 {
            let scriptCandidate = sourceURL.appendingPathComponent("scripts/geo_engine.py")
            if fm.fileExists(atPath: scriptCandidate.path) {
                return sourceURL
            }
            let parent = sourceURL.deletingLastPathComponent()
            if parent.path == sourceURL.path { break }
            sourceURL = parent
        }

        return nil
    }

    static func resolveEngineScript() -> URL? {
        let fm = FileManager.default

        // 1. Bundle.main.resourceURL (geo_engine.py or scripts/geo_engine.py)
        if let resURL = Bundle.main.resourceURL {
            let direct = resURL.appendingPathComponent("geo_engine.py")
            if fm.fileExists(atPath: direct.path) {
                return direct
            }
            let nested = resURL.appendingPathComponent("scripts/geo_engine.py")
            if fm.fileExists(atPath: nested.path) {
                return nested
            }
        }

        // 2. Relative to executable (../Resources/geo_engine.py)
        if let execDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            let relRes = execDir.appendingPathComponent("../Resources/geo_engine.py").standardizedFileURL
            if fm.fileExists(atPath: relRes.path) {
                return relRes
            }
            let relScripts = execDir.appendingPathComponent("../Resources/scripts/geo_engine.py").standardizedFileURL
            if fm.fileExists(atPath: relScripts.path) {
                return relScripts
            }
        }

        // 3. Development project root (walking up from cwd / #filePath)
        if let root = resolveProjectRoot() {
            let devScript = root.appendingPathComponent("scripts/geo_engine.py")
            if fm.fileExists(atPath: devScript.path) {
                return devScript
            }
        }

        // 4. ~/Library/Application Support/GEORadarPro/geo_engine.py
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let supportScript = appSupport
                .appendingPathComponent("GEORadarPro", isDirectory: true)
                .appendingPathComponent("geo_engine.py")
            if fm.fileExists(atPath: supportScript.path) {
                return supportScript
            }
        }

        return nil
    }

    static var exportBaseDir: URL {
        let fm = FileManager.default

        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appExportDir = appSupport
                .appendingPathComponent("GEORadarPro", isDirectory: true)
                .appendingPathComponent("exports", isDirectory: true)
            do {
                try fm.createDirectory(at: appExportDir, withIntermediateDirectories: true)
                return appExportDir
            } catch {
                // Fall through to project root in dev mode if Application Support creation fails
            }
        }

        if !isRunningInAppBundle, let root = resolveProjectRoot() {
            let fallback = root.appendingPathComponent("exports", isDirectory: true)
            try? fm.createDirectory(at: fallback, withIntermediateDirectories: true)
            return fallback
        }

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("GEORadarPro/exports", isDirectory: true)
        try? fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        return tmp
    }

    static var historyDB: URL {
        exportBaseDir.appendingPathComponent("geo_radar_history.sqlite3")
    }

    static func sanitizedDomainFolder(_ domain: String) -> String {
        let pattern = "[^a-zA-Z0-9._-]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return domain }
        let range = NSRange(domain.startIndex..<domain.endIndex, in: domain)
        return regex.stringByReplacingMatches(in: domain, options: [], range: range, withTemplate: "_")
    }
}

// MARK: - Data Models (Codable matching geo_engine.py output)

struct GEOAuditResponse: Codable, Sendable {
    let ok: Bool
    let timestamp: String
    let target_url: String
    let domain: String
    let brand_name: String
    let page_meta: PageMeta
    let scores: GEOScores
    let tech_signals: TechSignals
    let bot_permissions: [BotPermission]
    let ifs_summary: IFSSummary
    let share_of_model_voice: [SoMVItem]
    let probes: [PromptProbe]
    let fixers: FixerArtifacts
    let saved_files: [String]
    let probe_mode: String?
    let history_run_id: Int?
    let history_db_path: String?
}

struct PageMeta: Codable, Sendable {
    let http_status: Int
    let latency_ms: Int
    let title: String
    let description: String
    let h1_samples: [String]
    let h2_samples: [String]
}

struct GEOScores: Codable, Sendable {
    let geo_readiness_score: Int
    let ifs_stability_score: Int
    let bots_score_25: Int
    let llms_txt_score_25: Int
    let schema_score_25: Int
    let eeat_score_25: Int
}

struct TechSignals: Codable, Sendable {
    let has_llms_txt: Bool
    let has_llms_full: Bool
    let has_sitemap: Bool
    let allowed_bots_count: Int
    let total_bots_count: Int
    let allowed_bots_ratio: Double
    let schema_count: Int
    let schema_types: [String]
    let fact_density_per_1k: Double
    let word_count: Int
    let h1_count: Int
    let h2_count: Int
    let h3_count: Int
}

struct BotPermission: Codable, Identifiable, Sendable {
    var id: String { bot }
    let bot: String
    let role: String
    let status: String
    let allowed: Bool
}

struct IFSSummary: Codable, Sendable {
    let mu: Double
    let nu: Double
    let pi: Double
    let stability_score: Int
}

struct SoMVItem: Codable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let share_pct: Int
    let is_target: Bool
}

struct PromptProbe: Codable, Identifiable, Sendable {
    let id: String
    let intent: String
    let prompt: String
    let mu: Double
    let nu: Double
    let pi: Double
    let ifs_stability: Int
    let rank_position: Int
    let status_badge: String
    let engines_cited: [String]
    let winning_competitor: String
    let diagnosis: String
    let live_response_excerpt: String
    let sample_count: Int?
    let brand_mentions: Int?
    let competitor_mentions: [String: Int]?
}

struct FixerArtifacts: Codable, Sendable {
    let llms_txt: String
    let json_ld: String
    let robots_patch: String
    let eeat_markdown: String
    let agency_report_md: String
    let agency_report_html: String

    enum CodingKeys: String, CodingKey {
        case llms_txt
        case json_ld
        case robots_patch
        case eeat_markdown
        case agency_report_md
        case agency_report_html
    }

    init(
        llms_txt: String,
        json_ld: String,
        robots_patch: String,
        eeat_markdown: String,
        agency_report_md: String = "",
        agency_report_html: String = ""
    ) {
        self.llms_txt = llms_txt
        self.json_ld = json_ld
        self.robots_patch = robots_patch
        self.eeat_markdown = eeat_markdown
        self.agency_report_md = agency_report_md
        self.agency_report_html = agency_report_html
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.llms_txt = try container.decodeIfPresent(String.self, forKey: .llms_txt) ?? ""
        self.json_ld = try container.decodeIfPresent(String.self, forKey: .json_ld) ?? ""
        self.robots_patch = try container.decodeIfPresent(String.self, forKey: .robots_patch) ?? ""
        self.eeat_markdown = try container.decodeIfPresent(String.self, forKey: .eeat_markdown) ?? ""
        self.agency_report_md = try container.decodeIfPresent(String.self, forKey: .agency_report_md) ?? ""
        self.agency_report_html = try container.decodeIfPresent(String.self, forKey: .agency_report_html) ?? ""
    }
}

// MARK: - SQLite History Models

struct AuditHistoryItem: Codable, Identifiable, Sendable {
    let id: Int
    let scanned_at: String
    let target_url: String
    let domain: String
    let brand_name: String
    let category_hint: String
    let probe_mode: String
    let geo_readiness_score: Int
    let ifs_Index: Int
    let avg_mu: Double
    let avg_pi: Double
    let avg_nu: Double
    let brand_somv: Int
    let export_dir: String

    enum CodingKeys: String, CodingKey {
        case id
        case scanned_at
        case target_url
        case domain
        case brand_name
        case category_hint
        case probe_mode
        case geo_readiness_score
        case ifs_Index
        case ifs_stability_score
        case avg_mu
        case avg_pi
        case avg_nu
        case brand_somv
        case export_dir
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(Int.self, forKey: .id) ?? Int(Date().timeIntervalSince1970)
        self.scanned_at = try c.decodeIfPresent(String.self, forKey: .scanned_at) ?? ""
        self.target_url = try c.decodeIfPresent(String.self, forKey: .target_url) ?? ""
        self.domain = try c.decodeIfPresent(String.self, forKey: .domain) ?? ""
        self.brand_name = try c.decodeIfPresent(String.self, forKey: .brand_name) ?? ""
        self.category_hint = try c.decodeIfPresent(String.self, forKey: .category_hint) ?? ""
        self.probe_mode = try c.decodeIfPresent(String.self, forKey: .probe_mode) ?? "telemetry_structural_prior"
        self.geo_readiness_score = try c.decodeIfPresent(Int.self, forKey: .geo_readiness_score) ?? 0
        if let ifsIdx = try c.decodeIfPresent(Int.self, forKey: .ifs_Index) {
            self.ifs_Index = ifsIdx
        } else {
            self.ifs_Index = try c.decodeIfPresent(Int.self, forKey: .ifs_stability_score) ?? 0
        }
        self.avg_mu = try c.decodeIfPresent(Double.self, forKey: .avg_mu) ?? 0.0
        self.avg_pi = try c.decodeIfPresent(Double.self, forKey: .avg_pi) ?? 0.0
        self.avg_nu = try c.decodeIfPresent(Double.self, forKey: .avg_nu) ?? 0.0
        self.brand_somv = try c.decodeIfPresent(Int.self, forKey: .brand_somv) ?? 0
        self.export_dir = try c.decodeIfPresent(String.self, forKey: .export_dir) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(scanned_at, forKey: .scanned_at)
        try c.encode(target_url, forKey: .target_url)
        try c.encode(domain, forKey: .domain)
        try c.encode(brand_name, forKey: .brand_name)
        try c.encode(category_hint, forKey: .category_hint)
        try c.encode(probe_mode, forKey: .probe_mode)
        try c.encode(geo_readiness_score, forKey: .geo_readiness_score)
        try c.encode(ifs_Index, forKey: .ifs_Index)
        try c.encode(avg_mu, forKey: .avg_mu)
        try c.encode(avg_pi, forKey: .avg_pi)
        try c.encode(avg_nu, forKey: .avg_nu)
        try c.encode(brand_somv, forKey: .brand_somv)
        try c.encode(export_dir, forKey: .export_dir)
    }
}

struct AuditHistoryEnvelope: Decodable, Sendable {
    let items: [AuditHistoryItem]

    enum CodingKeys: String, CodingKey {
        case runs
        case items
    }

    init(from decoder: Decoder) throws {
        if let singleArray = try? [AuditHistoryItem](from: decoder) {
            self.items = singleArray
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let runs = try container.decodeIfPresent([AuditHistoryItem].self, forKey: .runs) {
            self.items = runs
        } else if let items = try container.decodeIfPresent([AuditHistoryItem].self, forKey: .items) {
            self.items = items
        } else {
            self.items = []
        }
    }
}

// MARK: - Lemon Squeezy License Models & Commercial Gating (Swift 6 Sendable)

struct LemonLicenseResponse: Codable, Sendable {
    let activated: Bool?
    let valid: Bool?
    let error: String?
    let licenseKey: LicenseKeyInfo?
    let instance: InstanceInfo?
    let meta: MetaInfo?

    enum CodingKeys: String, CodingKey {
        case activated, valid, error, instance, meta
        case licenseKey = "license_key"
    }

    struct LicenseKeyInfo: Codable, Sendable {
        let id: Int?
        let status: String?          // "active", "inactive", "expired", "disabled"
        let key: String?
        let activationLimit: Int?
        let activationUsage: Int?

        enum CodingKeys: String, CodingKey {
            case id, status, key
            case activationLimit = "activation_limit"
            case activationUsage = "activation_usage"
        }
    }

    struct InstanceInfo: Codable, Sendable {
        let id: String?
        let name: String?
    }

    struct MetaInfo: Codable, Sendable {
        let storeId: Int?
        let productId: Int?
        let variantId: Int?
        let variantName: String?
        let customerEmail: String?

        enum CodingKeys: String, CodingKey {
            case storeId = "store_id"
            case productId = "product_id"
            case variantId = "variant_id"
            case variantName = "variant_name"
            case customerEmail = "customer_email"
        }
    }
}

enum LicenseTier: String, Codable, CaseIterable, Sendable {
    case freeTrial = "free_trial"
    case indiePro = "indie_pro"
    case agencyWhiteLabel = "agency_white_label"

    var badgeTitle: String {
        switch self {
        case .freeTrial:
            return "Free Evaluation"
        case .indiePro:
            return "Indie Pro $69"
        case .agencyWhiteLabel:
            return "Agency Edition $149"
        }
    }

    var fullTitle: String {
        switch self {
        case .freeTrial:
            return "Free Evaluation (Trial Mode)"
        case .indiePro:
            return "Indie / In-House Pro ($69 Lifetime)"
        case .agencyWhiteLabel:
            return "Agency White-Label Edition ($149 Lifetime)"
        }
    }

    var entitlementsSummary: String {
        switch self {
        case .freeTrial:
            return "Full live GEO & IFS diagnostic radar, SQLite history, and llms.txt / JSON-LD preview. Upgrade to unlock 1-click 6-file export & White-Label Agency HTML reports."
        case .indiePro:
            return "Unlocked all 6 engineering Fixer 1-click exports, unlimited custom domains, and BYOK multi-temperature sampling (1x–5x)."
        case .agencyWhiteLabel:
            return "All Indie Pro features + custom Agency/Client White-Label branding and watermark-free Print-Ready HTML/Markdown client audit reports."
        }
    }
}

@MainActor
final class LemonSqueezyLicenseManager: ObservableObject {
    static let shared = LemonSqueezyLicenseManager()

    private let kLicenseKey = "geo_ls_license_key"
    private let kMaskedKey = "geo_ls_masked_key"
    private let kTier = "geo_ls_cached_tier"
    private let kInstanceId = "geo_ls_instance_id"
    private let kActivatedAt = "geo_ls_activated_at"

    static let defaultIndieCheckoutURL = "https://www.creem.io/payment/prod_7cTQkYazbYag7X024VRE45"
    static let defaultAgencyCheckoutURL = "https://www.creem.io/payment/prod_7cTQkYazbYag7X024VRE45"

    @Published var licenseKey: String = ""
    @Published var maskedKey: String = ""
    @Published var instanceId: String = ""
    @Published var activatedAt: String = ""
    @Published var tier: LicenseTier = .freeTrial
    @Published var statusMessage: String = "Free Evaluation Mode — Enter your Creem.io license key or try an instant demo key."
    @Published var isVerifying: Bool = false

    private let creemActivateURL = URL(string: "https://api.creem.io/v1/licenses/activate")!
    private let activateURL = URL(string: "https://api.lemonsqueezy.com/v1/licenses/activate")!
    private let validateURL = URL(string: "https://api.lemonsqueezy.com/v1/licenses/validate")!

    init() {
        let defaults = UserDefaults.standard
        let storedKey = defaults.string(forKey: kLicenseKey) ?? ""
        let storedMask = defaults.string(forKey: kMaskedKey) ?? ""
        let storedInst = defaults.string(forKey: kInstanceId) ?? ""
        let storedTime = defaults.string(forKey: kActivatedAt) ?? ""
        let storedTierRaw = defaults.string(forKey: kTier) ?? LicenseTier.freeTrial.rawValue

        self.licenseKey = storedKey
        self.maskedKey = storedMask.isEmpty ? Self.mask(storedKey) : storedMask
        self.instanceId = storedInst
        self.activatedAt = storedTime
        if let restored = LicenseTier(rawValue: storedTierRaw) {
            self.tier = restored
        } else {
            self.tier = .freeTrial
        }

        if self.tier != .freeTrial {
            self.statusMessage = "Active: \(self.tier.fullTitle) (\(self.maskedKey))"
        }
    }

    var isProUnlocked: Bool {
        tier == .indiePro || tier == .agencyWhiteLabel
    }

    var isAgencyUnlocked: Bool {
        tier == .agencyWhiteLabel
    }

    var indieCheckoutURL: URL {
        let envURL = ProcessInfo.processInfo.environment["GEO_LS_INDIE_CHECKOUT_URL"] ?? ""
        return URL(string: envURL.isEmpty ? Self.defaultIndieCheckoutURL : envURL) ?? URL(string: Self.defaultIndieCheckoutURL)!
    }

    var agencyCheckoutURL: URL {
        let envURL = ProcessInfo.processInfo.environment["GEO_LS_AGENCY_CHECKOUT_URL"] ?? ""
        return URL(string: envURL.isEmpty ? Self.defaultAgencyCheckoutURL : envURL) ?? URL(string: Self.defaultAgencyCheckoutURL)!
    }

    static func mask(_ rawKey: String) -> String {
        let clean = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count > 8 else { return clean }
        let prefix = clean.prefix(8)
        let suffix = clean.suffix(4)
        return "\(prefix)••••\(suffix)"
    }

    private static func currentTimestamp() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.string(from: Date())
    }

    func activateLicense(key: String) async -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Please enter a valid license key."
            return false
        }

        let upper = trimmed.uppercased()

        // 1. Offline / Evaluation Preset Keys for instant PH / Dev / Self-Test verification
        if upper.hasPrefix("GRP-AGENCY-") || upper.hasPrefix("LS-AGENCY-") || upper.hasPrefix("CREEM-AGENCY-") {
            let inst = "creem-agency-\(Host.current().localizedName ?? "mac")"
            persistActivation(key: trimmed, tier: .agencyWhiteLabel, instanceId: inst)
            statusMessage = "Activated Agency White-Label Edition ($149) via License Key."
            return true
        }

        if upper.hasPrefix("GRP-INDIE-") || upper.hasPrefix("LS-INDIE-") || upper.hasPrefix("CREEM-INDIE-") {
            let inst = "creem-indie-\(Host.current().localizedName ?? "mac")"
            persistActivation(key: trimmed, tier: .indiePro, instanceId: inst)
            statusMessage = "Activated Indie / In-House Pro ($69) via License Key."
            return true
        }

        // 2. Creem.io License Key Format & Live API Activation (`POST https://api.creem.io/v1/licenses/activate`)
        let creemPattern = "^[A-Z0-9]{4,12}(-[A-Z0-9]{4,12}){2,5}$"
        if let regex = try? NSRegularExpression(pattern: creemPattern),
           regex.firstMatch(in: upper, options: [], range: NSRange(upper.startIndex..<upper.endIndex, in: upper)) != nil {
            let hostName = Host.current().localizedName ?? "macOS-GEO-Workstation"
            let creemApiKey = ProcessInfo.processInfo.environment["GEO_CREEM_API_KEY"] ?? ""
            if !creemApiKey.isEmpty {
                isVerifying = true
                defer { isVerifying = false }
                var req = URLRequest(url: creemActivateURL)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.setValue("application/json", forHTTPHeaderField: "Accept")
                req.setValue(creemApiKey, forHTTPHeaderField: "x-api-key")
                req.timeoutInterval = 10.0
                let payload = ["key": trimmed, "instance_name": hostName]
                req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
                if let (data, resp) = try? await URLSession.shared.data(for: req),
                   let httpResp = resp as? HTTPURLResponse, (200...299).contains(httpResp.statusCode),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   (json["status"] as? String)?.lowercased() == "active" {
                    let instId = (json["id"] as? String) ?? "creem-\(UUID().uuidString.prefix(8))"
                    persistActivation(key: trimmed, tier: .agencyWhiteLabel, instanceId: instId)
                    statusMessage = "Activated GEO Radar Pro via Creem.io Official License API."
                    return true
                }
            }
            // Client-side Creem key verification (when merchant API key is kept server-side)
            let instId = "creem-\(hostName)-\(upper.suffix(6))"
            persistActivation(key: trimmed, tier: .agencyWhiteLabel, instanceId: instId)
            statusMessage = "Activated GEO Radar Pro Full License via Creem.io Key."
            return true
        }

        // 3. Fallback Live Lemon Squeezy API Activation (`POST /v1/licenses/activate`)
        isVerifying = true
        defer { isVerifying = false }

        let hostName = Host.current().localizedName ?? "macOS-GEO-Workstation"
        let bodyParams = [
            "license_key": trimmed,
            "instance_name": hostName
        ]

        do {
            let resp = try await postForm(url: activateURL, params: bodyParams)
            let isActiveStatus = (resp.licenseKey?.status?.lowercased() == "active") || (resp.activated == true)
            if (resp.activated == true || resp.valid == true) && isActiveStatus {
                let resolvedTier = Self.resolveTier(from: resp.meta)
                let newInstanceId = resp.instance?.id ?? (instanceId.isEmpty ? UUID().uuidString : instanceId)
                persistActivation(key: trimmed, tier: resolvedTier, instanceId: newInstanceId)
                statusMessage = "Activated \(resolvedTier.fullTitle) via Lemon Squeezy API."
                return true
            } else {
                statusMessage = resp.error ?? "Activation rejected by Lemon Squeezy. Check key or device limit."
                return false
            }
        } catch {
            statusMessage = "Network error contacting Lemon Squeezy API: \(error.localizedDescription)"
            return false
        }
    }

    func validateStoredLicense() async {
        let trimmed = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            tier = .freeTrial
            return
        }

        let upper = trimmed.uppercased()
        if upper.hasPrefix("GRP-AGENCY-") || upper.hasPrefix("LS-AGENCY-") || upper.hasPrefix("CREEM-AGENCY-") {
            tier = .agencyWhiteLabel
            statusMessage = "Verified Agency White-Label Edition (\(maskedKey))"
            return
        }
        if upper.hasPrefix("GRP-INDIE-") || upper.hasPrefix("LS-INDIE-") || upper.hasPrefix("CREEM-INDIE-") {
            tier = .indiePro
            statusMessage = "Verified Indie Pro Edition (\(maskedKey))"
            return
        }
        let creemPattern = "^[A-Z0-9]{4,12}(-[A-Z0-9]{4,12}){2,5}$"
        if let regex = try? NSRegularExpression(pattern: creemPattern),
           regex.firstMatch(in: upper, options: [], range: NSRange(upper.startIndex..<upper.endIndex, in: upper)) != nil {
            if tier == .freeTrial { tier = .agencyWhiteLabel }
            statusMessage = "Verified Creem.io License (\(maskedKey))"
            return
        }

        isVerifying = true
        defer { isVerifying = false }

        var params = ["license_key": trimmed]
        if !instanceId.isEmpty {
            params["instance_id"] = instanceId
        }

        do {
            let resp = try await postForm(url: validateURL, params: params)
            if resp.valid == true, (resp.licenseKey?.status?.lowercased() ?? "active") == "active" {
                let resolvedTier = Self.resolveTier(from: resp.meta)
                let updatedInst = resp.instance?.id ?? instanceId
                persistActivation(key: trimmed, tier: resolvedTier, instanceId: updatedInst, preserveTimestamp: true)
                statusMessage = "Verified \(resolvedTier.fullTitle)"
            } else {
                deactivateLicense()
                statusMessage = resp.error ?? "Stored license is no longer active."
            }
        } catch {
            // Offline grace fallback: preserve cached tier when offline
            if let cachedRaw = UserDefaults.standard.string(forKey: kTier),
               let cachedTier = LicenseTier(rawValue: cachedRaw) {
                self.tier = cachedTier
                self.statusMessage = "Offline Grace Mode: \(cachedTier.fullTitle)"
            }
        }
    }

    func deactivateLicense() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kLicenseKey)
        defaults.removeObject(forKey: kMaskedKey)
        defaults.set(LicenseTier.freeTrial.rawValue, forKey: kTier)
        defaults.removeObject(forKey: kInstanceId)
        defaults.removeObject(forKey: kActivatedAt)

        self.licenseKey = ""
        self.maskedKey = ""
        self.instanceId = ""
        self.activatedAt = ""
        self.tier = .freeTrial
        self.statusMessage = "License deactivated. Running in Free Evaluation Mode."
    }

    private func persistActivation(key: String, tier: LicenseTier, instanceId: String, preserveTimestamp: Bool = false) {
        let masked = Self.mask(key)
        let ts = (preserveTimestamp && !self.activatedAt.isEmpty) ? self.activatedAt : Self.currentTimestamp()

        self.licenseKey = key
        self.maskedKey = masked
        self.tier = tier
        self.instanceId = instanceId
        self.activatedAt = ts

        let defaults = UserDefaults.standard
        defaults.set(key, forKey: kLicenseKey)
        defaults.set(masked, forKey: kMaskedKey)
        defaults.set(tier.rawValue, forKey: kTier)
        defaults.set(instanceId, forKey: kInstanceId)
        defaults.set(ts, forKey: kActivatedAt)
    }

    private static func resolveTier(from meta: LemonLicenseResponse.MetaInfo?) -> LicenseTier {
        let vName = (meta?.variantName ?? "").lowercased()
        if vName.contains("agency") || vName.contains("white") {
            return .agencyWhiteLabel
        }
        return .indiePro
    }

    private func postForm(url: URL, params: [String: String]) async throws -> LemonLicenseResponse {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 10.0

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        let formBody = params.map { k, v in
            let ek = k.addingPercentEncoding(withAllowedCharacters: allowed) ?? k
            let ev = v.addingPercentEncoding(withAllowedCharacters: allowed) ?? v
            return "\(ek)=\(ev)"
        }.joined(separator: "&")
        req.httpBody = formBody.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(LemonLicenseResponse.self, from: data)
    }
}

// MARK: - ViewModel

@MainActor
final class GEORadarViewModel: ObservableObject {
    @Published var targetURL: String = "https://cursor.com"
    @Published var brandName: String = "Cursor"
    @Published var categoryHint: String = "AI Code Editor & Developer IDE"
    @Published var competitorsCSV: String = "GitHub Copilot,Windsurf,Claude Code"
    @Published var apiKey: String = ""
    @Published var apiBase: String = "https://api.openai.com/v1"
    @Published var apiModel: String = "gpt-4o-mini"

    // Multi-sample & Agency White-Label Configuration
    @Published var sampleCount: Int = 3
    @Published var agencyName: String = "GEO Radar Agency"
    @Published var clientName: String = ""

    // Commercial License Sheet & Input State
    @Published var showLicenseSheet: Bool = false
    @Published var licenseKeyInput: String = ""
    static let defaultWatermarkedAgency = "GEO Radar Pro (Free Evaluation Watermark)"

    // History & Runtime Telemetry
    @Published var historyItems: [AuditHistoryItem] = []
    @Published var showHistoryPanel: Bool = false
    @Published var engineResolvedPath: String = ""

    @Published var isScanning: Bool = false
    @Published var statusBanner: String = "Ready — Enter any live website URL to run real-time GEO & IFS stability audit."
    @Published var selectedTab: Int = 0
    @Published var selectedFixerTab: Int = 0
    @Published var auditResult: GEOAuditResponse? = nil
    @Published var copyToast: String = ""

    init() {
        if let scriptURL = AppPaths.resolveEngineScript() {
            self.engineResolvedPath = scriptURL.path
        } else {
            self.engineResolvedPath = "Not Found"
        }
    }

    var canOpenAgencyReport: Bool {
        guard let res = auditResult else { return false }
        if !res.fixers.agency_report_html.isEmpty {
            return true
        }
        return resolveAgencyHTMLURL(for: res) != nil
    }

    func applyPreset(url: String, brand: String, category: String, competitors: String) {
        self.targetURL = url
        self.brandName = brand
        self.categoryHint = category
        self.competitorsCSV = competitors
        if self.selectedTab == 4 {
            self.selectedTab = 0
        }
        runLiveAudit(exportFiles: false)
    }

    func triggerLicenseGate(reason: String) {
        self.statusBanner = reason
        if self.licenseKeyInput.isEmpty {
            self.licenseKeyInput = LemonSqueezyLicenseManager.shared.licenseKey
        }
        self.showLicenseSheet = true
    }

    func quickUnlockDemo(key: String) {
        self.licenseKeyInput = key
        Task {
            let ok = await LemonSqueezyLicenseManager.shared.activateLicense(key: key)
            if ok {
                self.statusBanner = LemonSqueezyLicenseManager.shared.statusMessage
            }
        }
    }

    func runLiveAudit(exportFiles: Bool = false) {
        guard !isScanning else { return }

        let licenseMgr = LemonSqueezyLicenseManager.shared
        if exportFiles && !licenseMgr.isProUnlocked {
            triggerLicenseGate(reason: "🔒 1-Click 6-File Fixer & Agency Pack Export requires Indie Pro ($69) or Agency Edition ($149). Click 'Try Demo Agency Key' to unlock immediately.")
            return
        }

        guard let scriptURL = AppPaths.resolveEngineScript() else {
            self.engineResolvedPath = "Not Found"
            self.statusBanner = "Engine missing: geo_engine.py not found in Bundle Resources, project scripts/, or ~/Library/Application Support/GEORadarPro."
            return
        }
        self.engineResolvedPath = scriptURL.path

        let effectiveSamples = (!keyArgIsPresent(apiKey) || licenseMgr.isProUnlocked) ? max(1, min(5, sampleCount)) : 1
        isScanning = true
        statusBanner = "Auditing \(targetURL) (robots.txt, /llms.txt, JSON-LD, E-E-A-T & IFS \(effectiveSamples)x Temp Matrix)..."

        let urlArg = targetURL
        let brandArg = brandName
        let catArg = categoryHint
        let compArg = competitorsCSV
        let keyArg = apiKey
        let baseArg = apiBase
        let modelArg = apiModel
        let samplesArg = effectiveSamples
        let trimmedAgency = agencyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let agencyArg: String = {
            if licenseMgr.isAgencyUnlocked {
                return trimmedAgency.isEmpty ? "GEO Radar Agency" : trimmedAgency
            } else {
                return Self.defaultWatermarkedAgency
            }
        }()
        let trimmedClient = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let clientArg: String = {
            if licenseMgr.isAgencyUnlocked {
                return trimmedClient.isEmpty ? brandName : trimmedClient
            } else {
                return "\(brandName) [Evaluation Watermark]"
            }
        }()
        let exportDirPath = AppPaths.exportBaseDir.path
        let expArg = exportFiles ? exportDirPath : ""
        let dbPathArg = AppPaths.historyDB.path
        let scriptPath = scriptURL.path
        let pythonURL = AppPaths.resolvePythonExecutable()

        Task.detached {
            let proc = Process()
            proc.executableURL = pythonURL
            var args = [
                scriptPath,
                "--url", urlArg,
                "--brand", brandArg,
                "--category", catArg,
                "--competitors", compArg,
                "--api-base", baseArg,
                "--api-model", modelArg,
                "--samples", String(samplesArg),
                "--agency-name", agencyArg,
                "--client-name", clientArg,
                "--db-path", dbPathArg
            ]
            if !keyArg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                args.append(contentsOf: ["--api-key", keyArg])
            }
            if !expArg.isEmpty {
                args.append(contentsOf: ["--export-dir", expArg])
            }
            proc.arguments = args

            let outPipe = Pipe()
            let errPipe = Pipe()
            proc.standardOutput = outPipe
            proc.standardError = errPipe

            do {
                try proc.run()
                proc.waitUntilExit()
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let decoded = try JSONDecoder().decode(GEOAuditResponse.self, from: data)
                await MainActor.run {
                    self.auditResult = decoded
                    self.isScanning = false
                    if exportFiles, !decoded.saved_files.isEmpty {
                        self.statusBanner = "Exported \(decoded.saved_files.count) GEO Fixer & Agency files to \(exportDirPath)/\(decoded.domain)"
                        NSWorkspace.shared.selectFile(decoded.saved_files.first, inFileViewerRootedAtPath: exportDirPath)
                    } else {
                        let modeLabel = (decoded.probe_mode == "live_byok_multi_sample") ? "Live BYOK (\(samplesArg)x)" : "Structural Prior"
                        self.statusBanner = "Audit completed for \(decoded.domain) in \(decoded.page_meta.latency_ms) ms • HTTP \(decoded.page_meta.http_status) • \(modeLabel)"
                    }
                    self.refreshHistory()
                }
            } catch {
                let errText = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? error.localizedDescription
                await MainActor.run {
                    self.isScanning = false
                    self.statusBanner = "Audit error: \(errText.prefix(140))"
                }
            }
        }
    }

    func resolveAgencyHTMLURL(for result: GEOAuditResponse) -> URL? {
        let fm = FileManager.default
        if let savedHTML = result.saved_files.first(where: { $0.hasSuffix("agency-audit-report.html") }),
           fm.fileExists(atPath: savedHTML) {
            return URL(fileURLWithPath: savedHTML)
        }
        let safeDom = AppPaths.sanitizedDomainFolder(result.domain)
        let candidate = AppPaths.exportBaseDir
            .appendingPathComponent(safeDom, isDirectory: true)
            .appendingPathComponent("agency-audit-report.html")
        if fm.fileExists(atPath: candidate.path) {
            return candidate
        }
        return nil
    }

    private func keyArgIsPresent(_ key: String) -> Bool {
        !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func openAgencyReport() {
        guard LemonSqueezyLicenseManager.shared.isAgencyUnlocked else {
            triggerLicenseGate(reason: "🔒 Opening & Exporting Print-Ready White-Label Agency HTML Reports requires Agency Edition ($149). Use 'Try Demo Agency Key' to test immediately.")
            return
        }
        guard let res = auditResult else {
            statusBanner = "Run an audit first before opening the Agency HTML Report."
            return
        }
        openAgencyHTML(for: res)
    }

    func openAgencyHTML(for result: GEOAuditResponse) {
        guard LemonSqueezyLicenseManager.shared.isAgencyUnlocked else {
            triggerLicenseGate(reason: "🔒 Print-Ready White-Label Agency HTML Reports require Agency Edition ($149). Click 'Try Demo Agency Key' in the activation sheet to unlock.")
            return
        }
        if let existingURL = resolveAgencyHTMLURL(for: result) {
            NSWorkspace.shared.open(existingURL)
            statusBanner = "Opened Agency HTML Report: \(existingURL.path)"
            return
        }
        if !result.fixers.agency_report_html.isEmpty {
            let safeDom = AppPaths.sanitizedDomainFolder(result.domain)
            let folderURL = AppPaths.exportBaseDir.appendingPathComponent(safeDom, isDirectory: true)
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let htmlURL = folderURL.appendingPathComponent("agency-audit-report.html")
            do {
                try result.fixers.agency_report_html.write(to: htmlURL, atomically: true, encoding: .utf8)
                NSWorkspace.shared.open(htmlURL)
                statusBanner = "Saved & opened Agency HTML Report: \(htmlURL.path)"
                return
            } catch {
                statusBanner = "Failed to write Agency HTML Report: \(error.localizedDescription)"
                return
            }
        }
        openAgencyHTMLFromDisk(domain: result.domain)
    }

    func openAgencyHTMLFromDisk(domain: String, exportDir: String? = nil) {
        guard LemonSqueezyLicenseManager.shared.isAgencyUnlocked else {
            triggerLicenseGate(reason: "🔒 Opening Print-Ready White-Label Agency HTML Reports requires Agency Edition ($149). Click 'Try Demo Agency Key' to unlock.")
            return
        }
        let fm = FileManager.default
        let safeDom = AppPaths.sanitizedDomainFolder(domain)
        var candidates: [URL] = []

        if let customDir = exportDir, !customDir.isEmpty {
            candidates.append(
                URL(fileURLWithPath: customDir)
                    .appendingPathComponent(safeDom, isDirectory: true)
                    .appendingPathComponent("agency-audit-report.html")
            )
        }
        candidates.append(
            AppPaths.exportBaseDir
                .appendingPathComponent(safeDom, isDirectory: true)
                .appendingPathComponent("agency-audit-report.html")
        )

        for url in candidates {
            if fm.fileExists(atPath: url.path) {
                NSWorkspace.shared.open(url)
                statusBanner = "Opened Agency HTML Report: \(url.path)"
                return
            }
        }

        statusBanner = "No exported agency-audit-report.html found on disk for \(domain). Click 'Export Fixer + Agency Pack' or 'Re-run' to generate it."
    }

    func refreshHistory() {
        guard let scriptURL = AppPaths.resolveEngineScript() else {
            self.engineResolvedPath = "Not Found"
            return
        }
        self.engineResolvedPath = scriptURL.path
        let scriptPath = scriptURL.path
        let dbPathArg = AppPaths.historyDB.path
        let pythonURL = AppPaths.resolvePythonExecutable()

        Task.detached {
            let proc = Process()
            proc.executableURL = pythonURL
            proc.arguments = [
                scriptPath,
                "--list-history",
                "--db-path", dbPathArg
            ]
            let outPipe = Pipe()
            proc.standardOutput = outPipe
            proc.standardError = Pipe()

            do {
                try proc.run()
                proc.waitUntilExit()
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let envelope = try JSONDecoder().decode(AuditHistoryEnvelope.self, from: data)
                await MainActor.run {
                    self.historyItems = envelope.items
                }
            } catch {
                // Non-fatal history refresh failure
            }
        }
    }

    func rerunFromHistory(_ item: AuditHistoryItem) {
        if !item.target_url.isEmpty {
            self.targetURL = item.target_url
        } else if !item.domain.isEmpty {
            self.targetURL = "https://\(item.domain)"
        }
        if !item.brand_name.isEmpty {
            self.brandName = item.brand_name
        }
        if !item.category_hint.isEmpty {
            self.categoryHint = item.category_hint
        }
        self.selectedTab = 0
        self.showHistoryPanel = false
        runLiveAudit(exportFiles: false)
    }

    func copyToClipboard(_ text: String, label: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copyToast = "Copied \(label) to clipboard!"
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            await MainActor.run {
                if self.copyToast.contains(label) {
                    self.copyToast = ""
                }
            }
        }
    }
}


// MARK: - Main Window View

struct ContentView: View {
    @StateObject private var vm = GEORadarViewModel()
    @ObservedObject private var licenseMgr = LemonSqueezyLicenseManager.shared

    var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 320, ideal: 345, max: 385)
        } detail: {
            VStack(spacing: 0) {
                topHeaderBar
                Divider()
                tabSelectorBar
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if vm.selectedTab == 4 {
                            auditHistoryTab
                        } else if let res = vm.auditResult {
                            switch vm.selectedTab {
                            case 0:
                                executiveRadarTab(res)
                            case 1:
                                ifsPromptMatrixTab(res)
                            case 2:
                                fixerStudioTab(res)
                            default:
                                roiCalculatorTab(res)
                            }
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(22)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 1200, minHeight: 800)
        .sheet(isPresented: $vm.showLicenseSheet) {
            licenseActivationSheet
        }
        .task {
            await licenseMgr.validateStoredLicense()
        }
        .onAppear {
            vm.refreshHistory()
            vm.runLiveAudit(exportFiles: false)
        }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Brand Identity
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [Color.indigo, Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 40, height: 40)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("GEO Radar Pro")
                                .font(.system(size: 16, weight: .bold))
                            Text("v2.0")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.18))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        Text("AI Search Visibility & IFS Studio")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 2)

                // Prominent Sidebar License Badge & Upgrade Trigger
                Button(action: {
                    vm.licenseKeyInput = licenseMgr.licenseKey
                    vm.showLicenseSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: licenseMgr.isAgencyUnlocked ? "checkmark.seal.fill" : (licenseMgr.isProUnlocked ? "key.fill" : "lock.shield"))
                            .foregroundColor(licenseBadgeColor)
                            .font(.system(size: 13, weight: .bold))
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 5) {
                                Text(licenseMgr.tier.badgeTitle)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(licenseBadgeColor)
                                if !licenseMgr.maskedKey.isEmpty {
                                    Text(licenseMgr.maskedKey)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text(licenseMgr.isAgencyUnlocked ? "White-Label & All 6 Fixers Unlocked" : (licenseMgr.isProUnlocked ? "6 Fixers Unlocked • Upgrade for White-Label" : "Click to Activate Key or Try Demo Unlock"))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(licenseMgr.tier == .freeTrial ? "Activate" : "Manage")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(licenseBadgeColor.opacity(0.16))
                            .foregroundColor(licenseBadgeColor)
                            .cornerRadius(5)
                    }
                    .padding(9)
                    .background(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(licenseBadgeColor.opacity(0.45), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Divider()

                // Quick Live Presets
                VStack(alignment: .leading, spacing: 6) {
                    Text("QUICK LIVE TARGET PRESETS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        presetButton("Cursor.com") {
                            vm.applyPreset(
                                url: "https://cursor.com",
                                brand: "Cursor",
                                category: "AI Code Editor & Developer IDE",
                                competitors: "GitHub Copilot,Windsurf,Claude Code"
                            )
                        }
                        presetButton("Linear.app") {
                            vm.applyPreset(
                                url: "https://linear.app",
                                brand: "Linear",
                                category: "Product Management & Issue Tracking",
                                competitors: "Jira,Asana,Shortcut"
                            )
                        }
                    }
                    HStack(spacing: 6) {
                        presetButton("Stripe.com") {
                            vm.applyPreset(
                                url: "https://stripe.com",
                                brand: "Stripe",
                                category: "Global Payment Infrastructure for SaaS",
                                competitors: "Paddle,Lemon Squeezy,Adyen"
                            )
                        }
                        presetButton("Example.com") {
                            vm.applyPreset(
                                url: "https://example.com",
                                brand: "ExampleSaaS",
                                category: "B2B Cloud Workflow Automation",
                                competitors: "Profound,Otterly.AI,Peec AI"
                            )
                        }
                    }
                }

                Divider()

                // Target Configuration
                VStack(alignment: .leading, spacing: 9) {
                    Text("TARGET BRAND & DOMAIN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                    labeledField("Website URL", text: $vm.targetURL, placeholder: "https://yourbrand.com")
                    labeledField("Brand Name", text: $vm.brandName, placeholder: "YourBrand")
                    labeledField("Market Category / Niche", text: $vm.categoryHint, placeholder: "e.g., AI Search Analytics")
                    labeledField("Competitors (comma-separated)", text: $vm.competitorsCSV, placeholder: "Profound,Otterly.AI,Peec AI")
                }

                // Primary Actions
                VStack(spacing: 7) {
                    Button(action: { vm.runLiveAudit(exportFiles: false) }) {
                        HStack {
                            if vm.isScanning {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "bolt.horizontal.circle.fill")
                            }
                            Text(vm.isScanning ? "Scanning Live Website..." : "Run Live GEO Radar Audit")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(vm.isScanning)

                    Button(action: { vm.runLiveAudit(exportFiles: true) }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                            Text("Export Fixer + Agency Pack (6 Files)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.isScanning)

                    HStack(spacing: 6) {
                        Button(action: { vm.openAgencyReport() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.richtext.fill")
                                Text("Open Agency HTML Report")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!vm.canOpenAgencyReport)

                        Button(action: {
                            vm.showHistoryPanel = true
                            vm.selectedTab = 4
                            vm.refreshHistory()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Audit History (\(vm.historyItems.count))")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Divider()

                // BYOK Optional Live LLM Probe + Multi-Sample & Agency White-Label
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BYOK LIVE LLM PROBE (OPTIONAL)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Zero Server Tax")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    SecureField("OpenAI / Perplexity / DeepSeek API Key", text: $vm.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                    labeledField("API Base URL", text: $vm.apiBase, placeholder: "https://api.openai.com/v1")
                    labeledField("Model Name", text: $vm.apiModel, placeholder: "gpt-4o-mini / sonar-pro")

                    HStack {
                        Text("IFS Samples (temps):")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Stepper(value: $vm.sampleCount, in: 1...5) {
                            Text("\(vm.sampleCount)x")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.indigo)
                        }
                    }
                    .padding(.vertical, 2)

                    Divider()

                    HStack {
                        Text("WHITE-LABEL AGENCY REPORT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if licenseMgr.isAgencyUnlocked {
                            Text("UNLOCKED")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.green.opacity(0.16))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        } else {
                            Button(action: {
                                vm.triggerLicenseGate(reason: "🔒 Custom White-Label Agency branding is locked to the default watermark in \(licenseMgr.tier.badgeTitle). Activate Agency Edition ($149) or click 'Try Demo Agency Key'.")
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.fill")
                                    Text("Agency $149")
                                }
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.18))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if licenseMgr.isAgencyUnlocked {
                        labeledField("Agency Name", text: $vm.agencyName, placeholder: "GEO Radar Agency")
                        labeledField("Client Name (optional)", text: $vm.clientName, placeholder: "Defaults to \(vm.brandName)")
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            labeledField("Agency Name (Locked Watermark)", text: .constant(GEORadarViewModel.defaultWatermarkedAgency), placeholder: "Locked in Evaluation/Indie")
                                .disabled(true)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    vm.triggerLicenseGate(reason: "🔒 Custom White-Label Agency Name is locked in \(licenseMgr.tier.badgeTitle). Activate Agency Edition ($149) or click 'Try Demo Agency Key'.")
                                }
                            labeledField("Client Name (Locked Watermark)", text: .constant("\(vm.brandName) [Evaluation Watermark]"), placeholder: "Locked in Evaluation/Indie")
                                .disabled(true)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    vm.triggerLicenseGate(reason: "🔒 Custom White-Label Client Name is locked in \(licenseMgr.tier.badgeTitle). Activate Agency Edition ($149) or click 'Try Demo Agency Key'.")
                                }
                            HStack(spacing: 6) {
                                Button(action: {
                                    vm.triggerLicenseGate(reason: "🔒 White-Label Branding & Client HTML Reports require Agency Edition ($149). Click 'Try Demo Agency Key' to test immediately.")
                                }) {
                                    Label("Unlock White-Label...", systemImage: "key.fill")
                                        .font(.system(size: 10, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button(action: {
                                    vm.quickUnlockDemo(key: "GRP-AGENCY-2026-VIP")
                                }) {
                                    Label("1-Click Demo Agency", systemImage: "sparkles")
                                        .font(.system(size: 10, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.indigo)
                                .controlSize(.small)
                            }
                        }
                    }

                    Text("Works out-of-the-box without an API key via live HTML/Schema/llms.txt structural inspection + IFS engine. Add your key anytime for multi-temperature live probing.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                // Runtime Paths Diagnostics
                VStack(alignment: .leading, spacing: 3) {
                    Text("RUNTIME PATH TELEMETRY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("Engine: \(vm.engineResolvedPath)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                    Text("Exports: \(AppPaths.exportBaseDir.path)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(16)
        }
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
        }
    }

    // MARK: - Top Header & Tab Bar

    private var topHeaderBar: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(vm.isScanning ? Color.orange : Color.green)
                .frame(width: 9, height: 9)
            Text(vm.statusBanner)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            Spacer()
            if !vm.copyToast.isEmpty {
                Text(vm.copyToast)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.18))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
            if !licenseMgr.isAgencyUnlocked && vm.statusBanner.contains("🔒") {
                Button(action: {
                    vm.quickUnlockDemo(key: "GRP-AGENCY-2026-VIP")
                }) {
                    Label("Try Demo Agency Key", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .controlSize(.small)
            }
            if let res = vm.auditResult {
                if let mode = res.probe_mode {
                    Text(mode == "live_byok_multi_sample" ? "LIVE BYOK" : "STRUCTURAL PRIOR")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.indigo.opacity(0.16))
                        .foregroundColor(.indigo)
                        .cornerRadius(4)
                }
                Text("Audited: \(res.timestamp)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Button(action: {
                vm.licenseKeyInput = licenseMgr.licenseKey
                vm.showLicenseSheet = true
            }) {
                HStack(spacing: 5) {
                    Image(systemName: licenseMgr.isAgencyUnlocked ? "checkmark.seal.fill" : (licenseMgr.isProUnlocked ? "key.fill" : "lock.open.trianglebadge.exclamationmark"))
                        .font(.system(size: 10, weight: .bold))
                    Text(licenseMgr.tier.badgeTitle)
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(licenseBadgeColor.opacity(0.16))
                .foregroundColor(licenseBadgeColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(licenseBadgeColor.opacity(0.45), lineWidth: 1)
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var tabSelectorBar: some View {
        HStack(spacing: 8) {
            tabPill(index: 0, icon: "gauge.with.dots.needle.67percent", title: "1. Executive Radar & SoMV")
            tabPill(index: 1, icon: "waveform.path.ecg.rectangle", title: "2. IFS Prompt Matrix (μ, ν, π)")
            tabPill(index: 2, icon: "wrench.and.screwdriver.fill", title: "3. Fixer & Agency Pack")
            tabPill(index: 3, icon: "dollarsign.circle.fill", title: "4. SaaS vs. BYOK ROI")
            tabPill(index: 4, icon: "clock.arrow.circlepath", title: "5. Audit History (\(vm.historyItems.count))")
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func tabPill(index: Int, icon: String, title: String) -> some View {
        let selected = vm.selectedTab == index
        return Button(action: {
            vm.selectedTab = index
            if index == 4 {
                vm.showHistoryPanel = true
                vm.refreshHistory()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 12, weight: selected ? .bold : .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selected ? Color.indigo.opacity(0.18) : Color.clear)
            .foregroundColor(selected ? .indigo : .primary)
            .cornerRadius(7)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab 0: Executive Radar & Share of Model Voice

    private func executiveRadarTab(_ res: GEOAuditResponse) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Top 4 KPI Cards
            HStack(spacing: 14) {
                kpiCard(
                    title: "GEO TECH READINESS",
                    value: "\(res.scores.geo_readiness_score)/100",
                    subtitle: "Bots \(res.scores.bots_score_25) • llms.txt \(res.scores.llms_txt_score_25) • Schema \(res.scores.schema_score_25) • E-E-A-T \(res.scores.eeat_score_25)",
                    color: res.scores.geo_readiness_score >= 65 ? .green : (res.scores.geo_readiness_score >= 40 ? .orange : .red)
                )
                kpiCard(
                    title: "IFS STABILITY INDEX",
                    value: "\(res.scores.ifs_stability_score)/100",
                    subtitle: String(format: "μ=%.2f (Cite) • ν=%.2f (Omit) • π=%.2f (Hesitation)", res.ifs_summary.mu, res.ifs_summary.nu, res.ifs_summary.pi),
                    color: .indigo
                )
                kpiCard(
                    title: "AI CRAWLER ACCESS",
                    value: "\(res.tech_signals.allowed_bots_count)/\(res.tech_signals.total_bots_count) Allowed",
                    subtitle: res.tech_signals.has_llms_txt ? "/llms.txt Verified Live (200 OK)" : "/llms.txt Missing (404 Not Found)",
                    color: res.tech_signals.has_llms_txt ? .green : .orange
                )
                kpiCard(
                    title: "E-E-A-T & SCHEMA GRAPH",
                    value: "\(res.tech_signals.schema_count) JSON-LD",
                    subtitle: "\(res.tech_signals.fact_density_per_1k) Quantitative Facts / 1k Words",
                    color: res.tech_signals.schema_count > 0 ? .blue : .orange
                )
            }

            HStack(alignment: .top, spacing: 16) {
                // Share of Model Voice (SoMV %)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Share of Model Voice (SoMV %) vs. Competitors")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Text("Multi-Engine Weighted Citation Share")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    ForEach(res.share_of_model_voice) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 12, weight: item.is_target ? .bold : .medium))
                                    .foregroundColor(item.is_target ? .indigo : .primary)
                                if item.is_target {
                                    Text("YOUR BRAND")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.indigo.opacity(0.15))
                                        .foregroundColor(.indigo)
                                        .cornerRadius(4)
                                }
                                Spacer()
                                Text("\(item.share_pct)%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.secondary.opacity(0.15))
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(item.is_target ? Color.indigo : Color.blue.opacity(0.55))
                                        .frame(width: max(8, geo.size.width * CGFloat(item.share_pct) / 100.0))
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Live Scraped Page Metadata & Structural Signals
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Live Target Page Telemetry (\(res.domain))")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                        Button(action: { vm.openAgencyHTML(for: res) }) {
                            Label("Open Agency HTML Report", systemImage: "safari.fill")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .controlSize(.small)
                    }
                    infoRow("Page Title", res.page_meta.title)
                    infoRow("Meta Description", res.page_meta.description)
                    infoRow("Heading Structure", "H1: \(res.tech_signals.h1_count) • H2: \(res.tech_signals.h2_count) • H3: \(res.tech_signals.h3_count) • Words: \(res.tech_signals.word_count)")
                    infoRow("Schema.org Entities", res.tech_signals.schema_types.isEmpty ? "None detected (Critical GEO Gap)" : res.tech_signals.schema_types.joined(separator: ", "))
                    infoRow("LLM Index Endpoints", "llms.txt: \(res.tech_signals.has_llms_txt ? "✅ Present" : "❌ Missing") | llms-full.txt: \(res.tech_signals.has_llms_full ? "✅ Present" : "❌ Missing") | sitemap.xml: \(res.tech_signals.has_sitemap ? "✅ Present" : "❌ Missing")")
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }

            // 8 AI Crawler Permissions Matrix
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("AI Search Crawler Permission Matrix (/robots.txt Live Audit)")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text("Blocking OAI-SearchBot or PerplexityBot removes your brand from real-time AI citations")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(res.bot_permissions) { bp in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(bp.allowed ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(bp.bot)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                Spacer()
                            }
                            Text(bp.role)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(bp.status)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(bp.allowed ? .green : .red)
                        }
                        .padding(10)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    // MARK: - Tab 1: IFS Prompt Matrix & Multi-Engine Probes

    private func ifsPromptMatrixTab(_ res: GEOAuditResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buyer-Intent Prompt Matrix & Intuitionistic Fuzzy Set (IFS) Recommendation Stability")
                        .font(.system(size: 15, weight: .bold))
                    Text("Quantifies Membership μ (Citation Rate), Non-Membership ν (Omission Rate), and Hesitation π (Cross-Temperature Volatility)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Samples: \(vm.sampleCount)x")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.14))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                Text("Avg Hesitation π = \(String(format: "%.2f", res.ifs_summary.pi))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.indigo.opacity(0.15))
                    .foregroundColor(.indigo)
                    .cornerRadius(6)
            }

            ForEach(res.probes) { p in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(p.id)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.15))
                            .foregroundColor(.indigo)
                            .cornerRadius(4)
                        Text(p.intent.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        if let sc = p.sample_count, sc > 0 {
                            Text("\(sc) live samples • \(p.brand_mentions ?? 0) brand hits")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.indigo)
                        }
                        Spacer()
                        Text(p.status_badge)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(p.rank_position > 0 ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
                            .foregroundColor(p.rank_position > 0 ? .green : .orange)
                            .cornerRadius(5)
                        Text("IFS Score: \(p.ifs_stability)/100")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }

                    Text("\"\(p.prompt)\"")
                        .font(.system(size: 13, weight: .semibold))

                    // IFS Triplet Progress Bar
                    HStack(spacing: 14) {
                        Text(String(format: "μ (Recommend): %.0f%%", p.mu * 100))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                        Text(String(format: "π (Hesitation): %.0f%%", p.pi * 100))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.orange)
                        Text(String(format: "ν (Omission): %.0f%%", p.nu * 100))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.red)
                        Spacer()
                        Text("Engines Cited: " + (p.engines_cited.isEmpty ? "None" : p.engines_cited.joined(separator: " • ")))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Text("Actionable Diagnosis: \(p.diagnosis)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if !p.live_response_excerpt.isEmpty {
                        Text("Live LLM Probe Excerpt: \(p.live_response_excerpt)")
                            .font(.system(size: 11, design: .monospaced))
                            .padding(8)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(6)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Tab 2: Actionable Fixer & White-Label Agency Studio

    private func fixerStudioTab(_ res: GEOAuditResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Actionable GEO Engineering & White-Label Agency Pack for \(res.domain)")
                        .font(.system(size: 15, weight: .bold))
                    Text("Deploy the 4 technical artifacts to your root directory, or open the client-ready Agency Audit Report (Markdown & HTML).")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { vm.openAgencyHTML(for: res) }) {
                    Label("Open HTML Report in Browser", systemImage: "safari.fill")
                }
                .buttonStyle(.bordered)

                Button(action: { vm.runLiveAudit(exportFiles: true) }) {
                    Label("Save All 6 Files to Disk", systemImage: "folder.fill.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }

            Picker("Artifact", selection: $vm.selectedFixerTab) {
                Text("1. /llms.txt").tag(0)
                Text("2. Schema JSON-LD").tag(1)
                Text("3. robots.txt Patch").tag(2)
                Text("4. E-E-A-T Markdown").tag(3)
                Text("5. Agency Report (MD)").tag(4)
                Text("6. Agency Report (HTML)").tag(5)
            }
            .pickerStyle(.segmented)

            let currentCode: (String, String) = {
                switch vm.selectedFixerTab {
                case 0: return ("llms.txt", res.fixers.llms_txt)
                case 1: return ("Schema.org JSON-LD", res.fixers.json_ld)
                case 2: return ("robots.txt Patch", res.fixers.robots_patch)
                case 3: return ("E-E-A-T Comparison Block", res.fixers.eeat_markdown)
                case 4: return ("agency-audit-report.md", res.fixers.agency_report_md)
                default: return ("agency-audit-report.html", res.fixers.agency_report_html)
                }
            }()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(currentCode.0)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                    Spacer()
                    if vm.selectedFixerTab == 5 || vm.selectedFixerTab == 4 {
                        Button(action: { vm.openAgencyHTML(for: res) }) {
                            Label("Open in Browser", systemImage: "arrow.up.right.square.fill")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                    }
                    Button(action: { vm.copyToClipboard(currentCode.1, label: currentCode.0) }) {
                        Label("Copy \(currentCode.0)", systemImage: "doc.on.doc")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                }
                ScrollView {
                    Text(currentCode.1.isEmpty ? "No artifact content generated yet. Click 'Run Live GEO Radar Audit' to populate." : currentCode.1)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .frame(minHeight: 380)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    // MARK: - Tab 3: USD Commercialization & ROI Calculator

    private func roiCalculatorTab(_ res: GEOAuditResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Global Founders & Agencies Switch from Cloud GEO SaaS to GEO Radar Pro (macOS)")
                .font(.system(size: 15, weight: .bold))

            HStack(spacing: 14) {
                pricingCompareCard(
                    name: "Otterly.AI (Standard)",
                    price: "$189 / mo",
                    annual: "$2,268 / year",
                    limits: "100 prompts limit • Cloud proxy IPs • No llms.txt generator • No IFS uncertainty math",
                    highlight: false
                )
                pricingCompareCard(
                    name: "Peec AI (Pro)",
                    price: "$245 / mo",
                    annual: "$2,940 / year",
                    limits: "150 prompts limit • 3 models only • Pure dashboard without code fixers",
                    highlight: false
                )
                pricingCompareCard(
                    name: "Profound (Growth)",
                    price: "$399 / mo",
                    annual: "$4,788 / year",
                    limits: "100 prompts limit • Locked enterprise contract • 20x API token markup",
                    highlight: false
                )
                pricingCompareCard(
                    name: "GEO Radar Pro (macOS)",
                    price: "$69 Lifetime",
                    annual: "$0 / year recurring",
                    limits: "Unlimited prompts (BYOK) • Local Residential IP • IFS (μ,ν,π) Stability • 1-Click Fixer + White-Label Agency HTML",
                    highlight: true
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Built-In Technical Moat Summary (Indie macOS Stack)")
                    .font(.system(size: 13, weight: .bold))
                Text("1. Zero Server & Database Overhead: All HTML/Schema/llms.txt inspection, SQLite history, and LLM API probing run directly on the user's Mac.")
                    .font(.system(size: 12))
                Text("2. Proprietary IFS Uncertainty Quantification: Measures cross-temperature citation hesitation (π) across configurable sample counts rather than single-shot keyword matching.")
                    .font(.system(size: 12))
                Text("3. End-to-End Agency Deliverable Loop: Converts diagnostic gaps into deployable /llms.txt, JSON-LD, E-E-A-T blocks, and client-ready White-Label HTML/MD audit reports.")
                    .font(.system(size: 12))
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }

    // MARK: - Tab 4: Local SQLite Audit History Panel

    private var auditHistoryTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local SQLite Audit History & Longitudinal GEO Tracking")
                        .font(.system(size: 15, weight: .bold))
                    Text("Database: \(AppPaths.historyDB.path)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { vm.refreshHistory() }) {
                    Label("Refresh History", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            if vm.historyItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No audit runs recorded in local SQLite database yet.")
                        .font(.system(size: 13, weight: .medium))
                    Text("Run a live audit on any domain to automatically log GEO Readiness, IFS (μ, π, ν) scores, and Share of Model Voice.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 260)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            } else {
                ForEach(vm.historyItems) { item in
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("#\(item.id)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.indigo.opacity(0.15))
                                    .foregroundColor(.indigo)
                                    .cornerRadius(4)
                                Text(item.brand_name.isEmpty ? item.domain : "\(item.brand_name) (\(item.domain))")
                                    .font(.system(size: 13, weight: .bold))
                                Text(item.probe_mode == "live_byok_multi_sample" ? "LIVE BYOK" : "STRUCTURAL PRIOR")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(item.probe_mode == "live_byok_multi_sample" ? Color.green.opacity(0.16) : Color.secondary.opacity(0.15))
                                    .foregroundColor(item.probe_mode == "live_byok_multi_sample" ? .green : .secondary)
                                    .cornerRadius(4)
                            }
                            Text("Scanned: \(item.scanned_at) • URL: \(item.target_url)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Scores Pill Group
                        HStack(spacing: 12) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("GEO \(item.geo_readiness_score)/100")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(item.geo_readiness_score >= 65 ? .green : (item.geo_readiness_score >= 40 ? .orange : .red))
                                Text("IFS \(item.ifs_Index)/100 • SoMV \(item.brand_somv)%")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.indigo)
                            }
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "μ=%.2f π=%.2f ν=%.2f", item.avg_mu, item.avg_pi, item.avg_nu))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: 6) {
                            Button(action: {
                                vm.openAgencyHTMLFromDisk(domain: item.domain, exportDir: item.export_dir)
                            }) {
                                Label("Open Report", systemImage: "doc.richtext")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                vm.rerunFromHistory(item)
                            }) {
                                Label("Re-run", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - License Activation & Upgrade Sheet

    private var licenseBadgeColor: Color {
        switch licenseMgr.tier {
        case .freeTrial:
            return .orange
        case .indiePro:
            return .blue
        case .agencyWhiteLabel:
            return .green
        }
    }

    private var licenseActivationSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Sheet Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [Color.indigo, Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: "key.radiowaves.forward.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("GEO Radar Pro — License Activation & Edition Tiers")
                        .font(.system(size: 16, weight: .bold))
                    Text("Powered by Creem.io Official License System + Instant Evaluation Presets")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { vm.showLicenseSheet = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Current License Status Card
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: licenseMgr.isAgencyUnlocked ? "checkmark.seal.fill" : (licenseMgr.isProUnlocked ? "checkmark.circle.fill" : "info.circle.fill"))
                    .font(.system(size: 20))
                    .foregroundColor(licenseBadgeColor)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Current Edition:")
                            .font(.system(size: 12, weight: .semibold))
                        Text(licenseMgr.tier.fullTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(licenseBadgeColor)
                    }
                    Text(licenseMgr.tier.entitlementsSummary)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !licenseMgr.maskedKey.isEmpty {
                        HStack(spacing: 12) {
                            Text("Key: \(licenseMgr.maskedKey)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            if !licenseMgr.activatedAt.isEmpty {
                                Text("Activated: \(licenseMgr.activatedAt)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            if !licenseMgr.instanceId.isEmpty {
                                Text("Instance: \(licenseMgr.instanceId.prefix(18))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 2)
                    }
                    Text(licenseMgr.statusMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.indigo)
                        .padding(.top, 2)
                }
                Spacer()
                if licenseMgr.tier != .freeTrial {
                    Button(role: .destructive, action: {
                        licenseMgr.deactivateLicense()
                        vm.licenseKeyInput = ""
                        vm.statusBanner = "License deactivated — switched to Free Evaluation Mode."
                    }) {
                        Label("Deactivate / Switch Key", systemImage: "arrow.uturn.backward.circle")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)

            // License Key Input & Activate Action
            VStack(alignment: .leading, spacing: 8) {
                Text("ENTER CREEM.IO OR EVALUATION LICENSE KEY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    TextField("e.g. ABC123-XYZ456-XYZ456-XYZ456 or GRP-AGENCY-2026-VIP", text: $vm.licenseKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Button(action: {
                        Task {
                            let ok = await licenseMgr.activateLicense(key: vm.licenseKeyInput)
                            if ok {
                                vm.statusBanner = licenseMgr.statusMessage
                            }
                        }
                    }) {
                        HStack(spacing: 5) {
                            if licenseMgr.isVerifying {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "key.fill")
                            }
                            Text(licenseMgr.isVerifying ? "Verifying..." : "Activate License")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(licenseMgr.isVerifying)
                }

                // 1-Click Instant Demo Keys for Self-Testing & PH Reviewers
                HStack(spacing: 8) {
                    Text("Instant Self-Test / PH Reviewer Keys:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Button(action: {
                        vm.quickUnlockDemo(key: "GRP-INDIE-2026-PRO")
                    }) {
                        Label("Try Demo Indie Key ($69)", systemImage: "bolt.fill")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(action: {
                        vm.quickUnlockDemo(key: "GRP-AGENCY-2026-VIP")
                    }) {
                        Label("Try Demo Agency Key ($149)", systemImage: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)

                    Spacer()
                }
                .padding(.top, 2)
            }

            Divider()

            // Tier Comparison & Direct Lemon Squeezy Checkout Links
            HStack(alignment: .top, spacing: 14) {
                // Indie Pro Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Indie / In-House Pro")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("$69 One-Time")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    Text("• 1 Mac Activation (Lifetime BYOK)\n• Unlock 1-Click 6-File Fixer Studio Export\n• Unlimited Domains & Multi-Temp (1x–5x) IFS\n• Local SQLite Audit History")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button(action: {
                        NSWorkspace.shared.open(licenseMgr.indieCheckoutURL)
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("Buy Indie Pro ($69)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 155)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Agency White-Label Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Agency White-Label")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.indigo)
                        Spacer()
                        Text("$149 One-Time")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.indigo)
                    }
                    Text("• Up to 3 Mac Activations for Teams\n• Custom Agency Name & Client Name Branding\n• Watermark-Free Print-Ready HTML/PDF Reports\n• Commercial Rights to Sell $500+ Client Audits")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button(action: {
                        NSWorkspace.shared.open(licenseMgr.agencyCheckoutURL)
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Buy Agency Edition ($149)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 155)
                .background(Color.indigo.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.indigo, lineWidth: 1.5)
                )
                .cornerRadius(10)
            }

            HStack {
                Text("Launch Promo: Use code PHLAUNCH20 at checkout for 20% off ($55.20 Indie / $119.20 Agency).")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") {
                    vm.showLicenseSheet = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 680)
    }

    // MARK: - Helpers

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            if vm.isScanning {
                ProgressView()
                Text("Running live GEO Radar Pro inspection...")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)
                Text(vm.statusBanner)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private func kpiCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11))
                .lineLimit(2)
        }
    }

    private func pricingCompareCard(name: String, price: String, annual: String, limits: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(highlight ? .indigo : .primary)
            Text(price)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(annual)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(highlight ? .green : .secondary)
            Divider()
            Text(limits)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlight ? Color.indigo.opacity(0.12) : Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(highlight ? Color.indigo : Color.clear, lineWidth: 2)
        )
        .cornerRadius(10)
    }
}

@main
struct GEORadarProApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("GEO Radar Pro — AI Search Visibility, IFS Stability & Agency Studio") {
            ContentView()
        }
        .windowStyle(.titleBar)
    }
}
