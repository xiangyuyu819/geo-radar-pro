# GEO Radar Pro — macOS SwiftUI Client v2.0 Upgrade Notes

## 1. Summary of Changes
- **Removed Hardcoded Paths**: Eliminated `/Users/yu/work/apple-apps/apps/geo-radar-pro/...` from `Sources/GEORadarPro/main.swift` and replaced with `AppPaths`.
- **Self-Contained App Bundle & Dev Path Resolution (`AppPaths`)**:
  - **Engine Script (`resolveEngineScript()`)**:
    1. `Bundle.main.resourceURL/geo_engine.py` (or `scripts/geo_engine.py`)
    2. `../Resources/geo_engine.py` relative to `Bundle.main.executableURL`
    3. Walking up from current working directory (`FileManager.default.currentDirectoryPath`) and `#filePath` to find `scripts/geo_engine.py` (covers `swift run` / Xcode dev builds at `/Users/yu/work/apple-apps/apps/geo-radar-pro/scripts/geo_engine.py`)
    4. `~/Library/Application Support/GEORadarPro/geo_engine.py`
  - **Python Executable (`resolvePythonExecutable()`)**:
    - Checks `/usr/bin/python3`, `/opt/homebrew/bin/python3`, `/usr/local/bin/python3` in order using `FileManager.default.isExecutableFile(atPath:)`.
  - **Exports & SQLite History (`exportBaseDir`, `historyDB`)**:
    - Prioritizes `~/Library/Application Support/GEORadarPro/exports` (auto-created with `withIntermediateDirectories: true`).
    - Falls back to `<projectRoot>/exports` in development mode if Application Support is unavailable.
    - SQLite database stored at `exportBaseDir/geo_radar_history.sqlite3`.
- **Multi-Temperature IFS Sampling (`--samples`)**:
  - Added `@Published var sampleCount: Int = 3` (`Stepper` range `1...5` in the BYOK sidebar section) and passed `--samples` on every audit run.
- **White-Label Agency Report (`--agency-name`, `--client-name`)**:
  - Added `agencyName` and `clientName` fields in the sidebar.
  - Added 1-click **Open Agency HTML Report** (`NSWorkspace.shared.open`) in the Sidebar, Executive Radar tab, Fixer Studio tab, and History rows. If `agency-audit-report.html` has not yet been exported to disk, `openAgencyHTML(for:)` materializes the in-memory `fixers.agency_report_html` to `exportBaseDir/<domain>/agency-audit-report.html` and opens it in the default browser.
  - Extended Fixer Studio segmented picker from 4 to 6 tabs (added `5. Agency Report (MD)` and `6. Agency Report (HTML)`).
- **Local SQLite Audit History Panel (`--list-history` + `--db-path`)**:
  - Added `AuditHistoryItem` and `AuditHistoryEnvelope` (compatible with `{"runs": [...]}`, `{"items": [...]}`, or plain JSON array `[...]`).
  - Added Tab 5 (`5. Audit History`) and sidebar shortcut button with `Refresh History`, `Open Report`, and `Re-run` actions.
- **Backward-Compatible Codable Models**:
  - `FixerArtifacts` uses custom `init(from:)` with `decodeIfPresent` defaulting to `""` for `agency_report_md` and `agency_report_html`.
  - `GEOAuditResponse` and `PromptProbe` include optional fields (`probe_mode`, `history_run_id`, `history_db_path`, `sample_count`, `brand_mentions`, `competitor_mentions`) with `Sendable` conformance for Swift 6 strict concurrency.

## 2. How to Build & Package on macOS
Run from the repository root on your Mac:

```bash
cd /Users/yu/work/apple-apps/apps/geo-radar-pro
./build_mac_app.sh
open GEORadarPro.app
```

Or run directly in development mode via Swift Package Manager:

```bash
cd /Users/yu/work/apple-apps/apps/geo-radar-pro
swift run
```
