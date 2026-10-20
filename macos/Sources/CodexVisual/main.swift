import AppKit
import Foundation

enum LanguageMode: String, CaseIterable {
    case system
    case english
    case chinese
    case japanese

    static func fromLocale(_ code: String) -> LanguageMode {
        if code.lowercased().hasPrefix("zh") { return .chinese }
        if code.lowercased().hasPrefix("ja") { return .japanese }
        return .english
    }

    static let defaultsKey = "languageMode"

    static var current: LanguageMode {
        get {
            if let override = ProcessInfo.processInfo.environment["CODEX_VISUAL_LANGUAGE"] {
                return fromLocale(override)
            }

            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let mode = LanguageMode(rawValue: rawValue) {
                return mode
            }

            return .system
        }
        set {
            if newValue == .system {
                UserDefaults.standard.removeObject(forKey: defaultsKey)
            } else {
                UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            }
        }
    }
}

enum RefreshMode: String, CaseIterable {
    case smart
    case everyFiveSeconds
    case everyFifteenSeconds
    case everySixtySeconds
    case everyFiveMinutes
    case manual

    static let defaultsKey = "refreshMode"

    static var current: RefreshMode {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let mode = RefreshMode(rawValue: rawValue) {
                return mode
            }

            return .everySixtySeconds
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }

    var baseInterval: TimeInterval? {
        switch self {
        case .smart:
            return 15
        case .everyFiveSeconds:
            return 5
        case .everyFifteenSeconds:
            return 15
        case .everySixtySeconds:
            return 60
        case .everyFiveMinutes:
            return 300
        case .manual:
            return nil
        }
    }
}

enum MenuBarDisplayMode: String, CaseIterable {
    case bars
    case numbers

    static let defaultsKey = "menuBarDisplayMode"

    static var current: MenuBarDisplayMode {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let mode = MenuBarDisplayMode(rawValue: rawValue) {
                return mode
            }

            return .bars
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }
}

enum MenuBarTextGroup: String, CaseIterable {
    case bar
    case label
    case percent
    case reset

    var defaultsKey: String {
        "menuBarTextColor.\(rawValue)"
    }

    var defaultColor: MenuBarTextColor {
        switch self {
        case .label, .reset, .percent:
            return .automatic
        case .bar:
            return .green
        }
    }

    var currentColor: MenuBarTextColor {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let color = MenuBarTextColor(rawValue: rawValue) {
                return color
            }

            return defaultColor
        }
        nonmutating set {
            if newValue == defaultColor {
                UserDefaults.standard.removeObject(forKey: defaultsKey)
            } else {
                UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            }
        }
    }
}

enum MenuBarTextColor: String, CaseIterable {
    case automatic
    case quota
    case white
    case blue
    case green
    case yellow
    case red
    case gray

    func resolved(for remaining: Int) -> NSColor {
        switch self {
        case .automatic:
            return .labelColor
        case .quota:
            return QuotaColor.statusText(for: remaining)
        case .white:
            return NSColor.white.withAlphaComponent(0.96)
        case .blue:
            return NSColor(calibratedRed: 0.42, green: 0.72, blue: 1.00, alpha: 1)
        case .green:
            return .systemGreen
        case .yellow:
            return NSColor(calibratedRed: 1.00, green: 0.78, blue: 0.24, alpha: 1)
        case .red:
            return NSColor(calibratedRed: 1.00, green: 0.42, blue: 0.38, alpha: 1)
        case .gray:
            return NSColor.white.withAlphaComponent(0.68)
        }
    }

    func resolvedForBar(for remaining: Int) -> NSColor {
        switch self {
        case .quota:
            return QuotaColor.fill(for: remaining)
        default:
            return resolved(for: remaining)
        }
    }

    var previewColors: [NSColor] {
        switch self {
        case .quota:
            return [
                QuotaColor.fill(for: 90),
                QuotaColor.fill(for: 70),
                QuotaColor.fill(for: 35),
                QuotaColor.fill(for: 10)
            ]
        default:
            return [resolved(for: 100)]
        }
    }
}

enum AppStrings {
    static var resolvedLanguage: LanguageMode {
        let mode = LanguageMode.current
        return mode == .system
            ? LanguageMode.fromLocale(preferredAppleLanguage ?? Locale.preferredLanguages.first ?? "en")
            : mode
    }

    private static var preferredAppleLanguage: String? {
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String] {
            return languages.first
        }

        if let languages = UserDefaults.standard.stringArray(forKey: "AppleLanguages") {
            return languages.first
        }

        return UserDefaults.standard.string(forKey: "AppleLanguages")
    }

    static func text(_ chinese: String, _ english: String, _ japanese: String) -> String {
        switch resolvedLanguage {
        case .chinese: return chinese
        case .japanese: return japanese
        default: return english
        }
    }

    static var dateLocale: Locale {
        Locale(identifier: text("zh_Hans_US", "en_US_POSIX", "ja_JP"))
    }

    static var dateFormat: String {
        text("M月d日 E HH:mm", "EEE MMM d HH:mm", "M月d日 E HH:mm")
    }

    static var shortTimeFormat: String {
        "HH:mm:ss"
    }

    static let statusTitlePlaceholder = "Codex --%"
    static var statusToolTip: String { text("Codex 额度", "Codex quota", "Codex 利用枠") }
    static var displayOrder: String { text("显示: 五小时 / 每周", "Display: 5-hour / weekly when available", "表示：5時間 / 週間") }
    static var refreshNow: String { text("立即刷新", "Refresh Now", "今すぐ更新") }
    static var quit: String { text("退出", "Quit", "終了") }
    static var openDashboard: String { text("打开控制窗口", "Open Control Window", "管理ウインドウを開く") }
    static var uninstall: String { text("卸载额度可视化", "Uninstall CodexVisual", "CodexVisual をアンインストール") }
    static var uninstallTitle: String { text("卸载额度可视化？", "Uninstall CodexVisual?", "CodexVisual をアンインストールしますか？") }
    static var uninstallMessage: String {
        text("这会退出应用，并删除本机安装的 CodexVisual.app 与本地缓存。Codex 登录信息和 Codex 日志不会被删除。", "This will quit the app and remove the installed CodexVisual.app plus local cache. Codex login data and Codex logs will not be removed.", "アプリを終了し、インストール済みの CodexVisual.app とローカルキャッシュを削除します。Codex のログイン情報とログは削除しません。")
    }
    static var uninstallConfirm: String { text("卸载", "Uninstall", "アンインストール") }
    static var cancel: String { text("取消", "Cancel", "キャンセル") }
    static var uninstallDone: String { text("额度可视化已卸载", "CodexVisual has been uninstalled", "CodexVisual をアンインストールしました") }
    static var refreshFrequency: String { text("刷新频率", "Refresh Frequency", "更新間隔") }
    static var refreshSmart: String { text("智能刷新", "Smart", "自動") }
    static var refreshEvery5Seconds: String { text("每 5 秒", "Every 5 seconds", "5秒ごと") }
    static var refreshEvery15Seconds: String { text("每 15 秒", "Every 15 seconds", "15秒ごと") }
    static var refreshEvery60Seconds: String { text("每 60 秒", "Every 60 seconds", "60秒ごと") }
    static var refreshEvery5Minutes: String { text("每 5 分钟", "Every 5 minutes", "5分ごと") }
    static var refreshManual: String { text("手动", "Manual", "手動") }
    static var menuBarDisplay: String { text("菜单栏显示方式", "Menu Bar Display", "メニューバーの表示") }
    static var menuBarDisplayBars: String { text("进度条", "Progress Bar", "プログレスバー") }
    static var menuBarDisplayNumbers: String { text("数字", "Numbers", "数値") }
    static var menuBarTextColor: String { text("菜单栏颜色", "Menu Bar Colors", "メニューバーの色") }
    static var menuBarTextBar: String { text("进度条", "Progress Bar", "プログレスバー") }
    static var menuBarTextLabel: String { text("时间标签", "Time Label", "期間ラベル") }
    static var menuBarTextPercent: String { text("百分比", "Percentage", "パーセント") }
    static var menuBarTextReset: String { text("刷新时间", "Reset Time", "回復時刻") }
    static var colorQuota: String { text("跟随额度", "By Quota", "残量に合わせる") }
    static var colorWhite: String { text("白色", "White", "白") }
    static var colorBlue: String { text("蓝色", "Blue", "青") }
    static var colorGreen: String { text("绿色", "Green", "緑") }
    static var colorYellow: String { text("黄色", "Yellow", "黄") }
    static var colorRed: String { text("红色", "Red", "赤") }
    static var colorGray: String { text("灰色", "Gray", "グレー") }
    static var checkForUpdates: String { text("检查更新", "Check for Updates", "更新を確認") }
    static var language: String { text("语言", "Language", "言語") }
    static var languageSystem: String { text("跟随系统", "System", "システムに合わせる") }
    static var languageEnglish: String { "English" }
    static var languageChinese: String { "中文" }
    static var languageJapanese: String { "日本語" }
    static var unknown: String { text("未知", "Unknown", "不明") }
    static var codexAccount: String { text("当前账号", "Codex account", "現在のアカウント") }
    static var codexSessions: String { text("Codex 会话", "Codex sessions", "Codex セッション") }
    static var codexLogs: String { text("Codex 日志", "Codex logs", "Codex ログ") }
    static var localCache: String { text("本地缓存", "local cache", "ローカルキャッシュ") }
    static var migratedCache: String { text("旧版缓存", "legacy cache", "旧キャッシュ") }
    static var quotaOverview: String { text("使用额度", "Codex Quota", "Codex 利用枠") }
    static var controlWindowTitle: String { text("额度可视化控制窗口", "CodexVisual Control Window", "CodexVisual 管理ウインドウ") }
    static var noQuotaYet: String { text("还没有读取到 Codex 额度。请打开 Codex 并发送一条消息，然后点击刷新。", "No Codex quota has been read yet. Open Codex, send one message, then click Refresh.", "Codex の利用枠を取得できていません。Codex でメッセージを送信してから更新してください。") }
    static var fiveHourQuota: String { text("5 小时", "5-hour", "5時間") }
    static var weeklyQuota: String { text("每周", "Weekly", "週間") }
    static var fiveHourCompact: String { text("5时", "5h", "5h") }
    static var weeklyCompact: String { text("7日", "7d", "7d") }
    static var remaining: String { text("剩余", "remaining", "残り") }
    static var historicalData: String { text("历史数据", "Historical data", "過去のデータ") }
    static func dataUpdated(_ value: String) -> String {
        text("数据更新：\(value)", "Data updated: \(value)", "データ更新：\(value)")
    }

    static func missingDatabase(_ path: String) -> String {
        text("未找到 Codex 日志数据库: \(path)", "Codex log database not found: \(path)", "Codex ログのデータベースが見つかりません：\(path)")
    }

    static func sqliteFailed(_ message: String) -> String {
        text("读取 SQLite 失败: \(message)", "Failed to read SQLite: \(message)", "SQLite の読み取りに失敗しました：\(message)")
    }

    static var missingEvent: String {
        text("还没有读到当前有效的 codex.rate_limits 事件。请在当前登录的 Codex 账号中发送一条消息后再刷新。", "No current codex.rate_limits event has been found yet. Send one message from the currently signed-in Codex account, then refresh.", "現在有効な codex.rate_limits が見つかりません。ログイン中の Codex アカウントでメッセージを送信してから更新してください。")
    }

    static var invalidLogRow: String {
        text("日志行格式无法解析", "Could not parse the log row", "ログ行を解析できません")
    }

    static var invalidJSON: String {
        text("额度事件 JSON 无法解析", "Could not parse the quota event JSON", "利用枠イベントの JSON を解析できません")
    }

    static func cannotRunSQLite(_ message: String) -> String {
        text("无法运行 sqlite3: \(message)", "Could not run sqlite3: \(message)", "sqlite3 を実行できません：\(message)")
    }

    static func quotaToolTip(fiveHour: Int?, weekly: Int) -> String {
        guard let fiveHour else {
            return text("每周剩余: \(weekly)%", "Weekly remaining: \(weekly)%", "週間の残り：\(weekly)%")
        }

        return text("5小时 / 每周剩余: \(fiveHour)% / \(weekly)%", "5-hour / weekly remaining: \(fiveHour)% / \(weekly)%", "5時間 / 週間の残り：\(fiveHour)% / \(weekly)%")
    }

    static func plan(_ value: String) -> String {
        text("计划: \(value)", "Plan: \(value)", "プラン：\(value)")
    }

    static func planName(_ rawValue: String?) -> String {
        guard let rawValue else { return unknown }
        switch rawValue.lowercased() {
        case "plus", "chatgpt_plus", "chatgpt-plus", "chatgptplus":
            return text("增强版", "PLUS", "PLUS")
        case "pro", "chatgpt_pro", "chatgpt-pro", "chatgptpro":
            return text("专业版", "PRO", "PRO")
        default:
            return rawValue.uppercased()
        }
    }


    static func dataSource(source: String, time: String) -> String {
        text("数据来源: \(source), \(time)", "Data source: \(source), \(time)", "データソース：\(source)、\(time)")
    }

    static func lastRead(_ value: String) -> String {
        text("最后读取: \(value)", "Last read: \(value)", "最終取得：\(value)")
    }

    static func usedCompact(_ value: Int) -> String {
        text("已用 \(value)%", "Used \(value)%", "使用済み \(value)%")
    }

    static func resetCompact(_ value: String) -> String {
        text("重置 \(value)", "Reset \(value)", "回復 \(value)")
    }

    static var resetPending: String {
        text("等待 Codex 更新", "waiting for Codex update", "Codex の更新待ち")
    }

    static func sourceCompact(source: String, readTime: String) -> String {
        text("来源: \(source) · 更新: \(readTime)", "Source: \(source) · Updated: \(readTime)", "取得元：\(source) · 更新：\(readTime)")
    }
}

enum SnapshotSource: String, Sendable {
    case codexAccount
    case codexSessions
    case codexLogs
    case localCache
    case migratedCache

    var title: String {
        switch self {
        case .codexAccount:
            return AppStrings.codexAccount
        case .codexSessions:
            return AppStrings.codexSessions
        case .codexLogs:
            return AppStrings.codexLogs
        case .localCache:
            return AppStrings.localCache
        case .migratedCache:
            return AppStrings.migratedCache
        }
    }
}

struct RateLimitEvent: Codable, Sendable {
    let type: String
    let planType: String?
    let rateLimits: RateLimits

    enum CodingKeys: String, CodingKey {
        case type
        case planType = "plan_type"
        case rateLimits = "rate_limits"
    }

    var fiveHourQuota: QuotaWindow? {
        rateLimits.fiveHour
    }
}

struct RateLimits: Codable, Sendable {
    let limitID: String?
    let allowed: Bool
    let limitReached: Bool
    let primary: QuotaWindow?
    let secondary: QuotaWindow?

    var weekly: QuotaWindow? {
        [primary, secondary]
            .compactMap { $0 }
            .filter { $0.windowMinutes == 10_080 }
            .max { $0.windowMinutes < $1.windowMinutes }
    }

    var fiveHour: QuotaWindow? {
        [primary, secondary]
            .compactMap { $0 }
            .first { $0.windowMinutes == 300 }
    }

    enum CodingKeys: String, CodingKey {
        case limitID = "limit_id"
        case allowed
        case limitReached = "limit_reached"
        case primary
        case secondary
    }
}

struct QuotaWindow: Codable, Sendable {
    let usedPercent: Int
    let windowMinutes: Int
    let resetAfterSeconds: Int?
    let resetAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case windowMinutes = "window_minutes"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }

    var remainingPercent: Int {
        min(100, max(0, 100 - effectiveUsedPercent))
    }

    var effectiveUsedPercent: Int {
        usedPercent
    }

    var resetDate: Date {
        Date(timeIntervalSince1970: resetAt)
    }
}

struct QuotaSnapshot: Sendable {
    let event: RateLimitEvent
    let logDate: Date
    let readDate: Date
    let source: SnapshotSource

    var isHistorical: Bool { source != .codexAccount }

    var historicalCopy: QuotaSnapshot {
        QuotaSnapshot(event: event, logDate: logDate, readDate: readDate, source: .localCache)
    }
}

enum QuotaReadError: Error, LocalizedError, Sendable {
    case missingDatabase(String)
    case sqliteFailed(String)
    case missingEvent
    case invalidLogRow
    case invalidJSON
    case cannotRunSQLite(String)

    var errorDescription: String? {
        switch self {
        case .missingDatabase(let path):
            return AppStrings.missingDatabase(path)
        case .sqliteFailed(let message):
            return AppStrings.sqliteFailed(message)
        case .missingEvent:
            return AppStrings.missingEvent
        case .invalidLogRow:
            return AppStrings.invalidLogRow
        case .invalidJSON:
            return AppStrings.invalidJSON
        case .cannotRunSQLite(let message):
            return AppStrings.cannotRunSQLite(message)
        }
    }
}

private final class CodexAppServerExchange: @unchecked Sendable {
    private let process = Process()
    private let input = Pipe()
    private let output = Pipe()
    private let lock = NSLock()
    private let completion = DispatchSemaphore(value: 0)
    private var buffer = Data()
    private var snapshot: QuotaSnapshot?
    private var isFinished = false
    private var didInitialize = false

    init(executableURL: URL) {
        process.executableURL = executableURL
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
    }

    func run(timeout: TimeInterval = 8) -> QuotaSnapshot? {
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                self?.finish(snapshot: nil)
                return
            }
            self?.consume(data)
        }
        process.terminationHandler = { [weak self] _ in
            self?.finish(snapshot: nil)
        }

        do {
            try process.run()
            writeJSONLine([
                "id": 1,
                "method": "initialize",
                "params": [
                    "clientInfo": [
                        "name": "codexvisual",
                        "title": "CodexVisual",
                        "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
                    ],
                    "capabilities": ["experimentalApi": true]
                ]
            ])
        } catch {
            cleanup()
            return nil
        }

        if completion.wait(timeout: .now() + timeout) == .timedOut {
            finish(snapshot: nil)
        }

        lock.lock()
        let result = snapshot
        lock.unlock()
        cleanup()
        return result
    }

    private func consume(_ data: Data) {
        lock.lock()
        buffer.append(data)
        var lines: [Data] = []
        while let newline = buffer.firstIndex(of: 0x0A) {
            lines.append(buffer.prefix(upTo: newline))
            buffer.removeSubrange(...newline)
        }
        lock.unlock()

        for line in lines where !line.isEmpty {
            processLine(line)
        }
    }

    private func processLine(_ data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let identifier = (object["id"] as? NSNumber)?.intValue else {
            return
        }

        if identifier == 1 {
            lock.lock()
            let shouldContinue = !didInitialize && !isFinished
            didInitialize = true
            lock.unlock()
            guard shouldContinue else { return }

            writeJSONLine(["method": "initialized"])
            writeJSONLine(["id": 2, "method": "account/rateLimits/read", "params": NSNull()])
            return
        }

        guard identifier == 2 else { return }
        finish(snapshot: Self.decodeSnapshot(from: object))
    }

    static func decodeSnapshot(from response: [String: Any]) -> QuotaSnapshot? {
        guard let result = response["result"] as? [String: Any] else {
            return nil
        }

        let legacy = (result["rateLimits"] as? [String: Any]).flatMap { limits in
            ((limits["limitId"] as? String)?.lowercased() ?? "codex") == "codex" ? limits : nil
        }
        let selected: [String: Any]?
        if let buckets = result["rateLimitsByLimitId"] as? [String: Any],
           let codex = buckets["codex"] as? [String: Any] {
            selected = codex
        } else if let legacy {
            selected = legacy
        } else {
            selected = nil
        }

        guard let selected else { return nil }
        let primary = decodeWindow(selected["primary"])
        let secondary = decodeWindow(selected["secondary"])

        let reachedType = selected["rateLimitReachedType"]
        let isReached = reachedType != nil && !(reachedType is NSNull)
        let event = RateLimitEvent(
            type: "codex.rate_limits",
            planType: (selected["planType"] as? String) ?? (legacy?["planType"] as? String),
            rateLimits: RateLimits(
                limitID: (selected["limitId"] as? String) ?? "codex",
                allowed: !isReached,
                limitReached: isReached,
                primary: primary,
                secondary: secondary
            )
        )
        let now = Date()
        return QuotaSnapshot(event: event, logDate: now, readDate: now, source: .codexAccount)
    }

    private static func decodeWindow(_ value: Any?) -> QuotaWindow? {
        guard let object = value as? [String: Any],
              let usedNumber = object["usedPercent"] as? NSNumber,
              let resetNumber = object["resetsAt"] as? NSNumber,
              let durationNumber = object["windowDurationMins"] as? NSNumber,
              durationNumber.intValue > 0 else {
            return nil
        }

        let resetAt = resetNumber.doubleValue
        let windowMinutes = durationNumber.intValue
        return QuotaWindow(
            usedPercent: min(100, max(0, Int(ceil(usedNumber.doubleValue)))),
            windowMinutes: windowMinutes,
            resetAfterSeconds: max(0, Int(resetAt - Date().timeIntervalSince1970)),
            resetAt: resetAt
        )
    }

    private func writeJSONLine(_ object: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(object),
              var data = try? JSONSerialization.data(withJSONObject: object) else {
            return
        }
        data.append(0x0A)
        input.fileHandleForWriting.write(data)
    }

    private func finish(snapshot: QuotaSnapshot?) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }
        if let snapshot {
            self.snapshot = snapshot
        }
        isFinished = true
        lock.unlock()
        completion.signal()
    }

    private func cleanup() {
        output.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
        try? input.fileHandleForWriting.close()
        if process.isRunning {
            process.terminate()
        }
    }
}

final class QuotaReader: @unchecked Sendable {
    private let sqlitePath = "/usr/bin/sqlite3"
    private let databasePaths: [String]
    private let sessionsDirectory: URL
    private var latestAccountSnapshot: QuotaSnapshot?
    private var lastAccountAttempt: Date?
    private let accountRefreshInterval: TimeInterval = 5
    private let accountCacheMaxAge: TimeInterval = 10 * 60

    init(databasePaths: [String]? = nil) {
        let home = NSHomeDirectory()
        if let override = ProcessInfo.processInfo.environment["CODEX_VISUAL_SESSIONS_DIR"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.sessionsDirectory = URL(fileURLWithPath: override)
        } else {
            self.sessionsDirectory = URL(fileURLWithPath: home + "/.codex/sessions")
        }

        if let override = ProcessInfo.processInfo.environment["CODEX_VISUAL_LOG_DB"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.databasePaths = [override]
        } else if let databasePaths {
            self.databasePaths = databasePaths
        } else {
            self.databasePaths = [
                home + "/.codex/logs_2.sqlite",
                home + "/.codex/sqlite/logs_2.sqlite",
                home + "/.codex/logs.sqlite",
                home + "/.codex/sqlite/logs.sqlite"
            ]
        }
    }

    func readLatest(allowCache: Bool = true) throws -> QuotaSnapshot {
        let accountReadingDisabled = ProcessInfo.processInfo.environment["CODEX_VISUAL_DISABLE_APP_SERVER"] == "1"
        let forceAccountRefresh = !allowCache
        let shouldRefreshAccount = forceAccountRefresh
            || lastAccountAttempt == nil
            || Date().timeIntervalSince(lastAccountAttempt ?? .distantPast) >= accountRefreshInterval

        if !accountReadingDisabled, shouldRefreshAccount {
            lastAccountAttempt = Date()
            if let accountSnapshot = readFromCodexAccount() {
                latestAccountSnapshot = accountSnapshot
                saveCache(snapshot: accountSnapshot)
                return accountSnapshot
            }
            if let latestAccountSnapshot,
               Date().timeIntervalSince(latestAccountSnapshot.readDate) <= accountCacheMaxAge,
               (latestAccountSnapshot.event.rateLimits.weekly?.resetDate ?? .distantPast) > Date() {
                return latestAccountSnapshot.historicalCopy
            }
            if let cachedAccountSnapshot = readAccountCache(maxAge: accountCacheMaxAge) {
                latestAccountSnapshot = cachedAccountSnapshot
                return cachedAccountSnapshot
            }
        } else if !accountReadingDisabled, let latestAccountSnapshot,
                  Date().timeIntervalSince(latestAccountSnapshot.readDate) <= accountCacheMaxAge,
                  (latestAccountSnapshot.event.rateLimits.weekly?.resetDate ?? .distantPast) > Date() {
            return latestAccountSnapshot
        }

        var existingDatabaseSeen = false
        var sqliteErrors: [String] = []
        var liveSnapshots: [QuotaSnapshot] = []

        for databasePath in databasePaths {
            guard FileManager.default.fileExists(atPath: databasePath) else {
                continue
            }

            existingDatabaseSeen = true

            do {
                if let liveSnapshot = try readFromLogs(databasePath: databasePath) {
                    liveSnapshots.append(liveSnapshot)
                }
            } catch QuotaReadError.sqliteFailed(let message) {
                sqliteErrors.append("\(databasePath): \(message)")
            } catch {
                throw error
            }
        }

        if let sessionSnapshot = readFromSessions() {
            liveSnapshots.append(sessionSnapshot)
        }

        if let latestSnapshot = liveSnapshots.max(by: { $0.logDate < $1.logDate }) {
            saveCache(snapshot: latestSnapshot)
            return latestSnapshot
        }

        if allowCache, let cachedSnapshot = readCache() {
            return cachedSnapshot
        }

        if !sqliteErrors.isEmpty {
            throw QuotaReadError.sqliteFailed(sqliteErrors.joined(separator: "\n"))
        }

        if !existingDatabaseSeen {
            throw QuotaReadError.missingDatabase(databasePaths.joined(separator: ", "))
        }

        throw QuotaReadError.missingEvent
    }

    private func readFromCodexAccount() -> QuotaSnapshot? {
        let environment = ProcessInfo.processInfo.environment
        if environment["CODEX_VISUAL_DISABLE_APP_SERVER"] == "1" {
            return nil
        }

        if let fixturePath = environment["CODEX_VISUAL_ACCOUNT_RESPONSE_FILE"],
           let data = try? Data(contentsOf: URL(fileURLWithPath: fixturePath)),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return CodexAppServerExchange.decodeSnapshot(from: object)
        }

        let candidates: [String]
        if let override = environment["CODEX_VISUAL_CODEX_EXECUTABLE"], !override.isEmpty {
            candidates = [override]
        } else {
            let appRoots = ["/Applications", NSHomeDirectory() + "/Applications"]
            let appNames = ["ChatGPT.app", "Codex.app"]
            let relativePaths = [
                "Contents/Resources/codex-cli/bin/codex",
                "Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
                "Contents/Resources/codex"
            ]
            candidates = appRoots.flatMap { root in
                appNames.flatMap { app in
                    relativePaths.map { root + "/" + app + "/" + $0 }
                }
            } + ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"]
        }

        for executable in candidates.filter({
            FileManager.default.isExecutableFile(atPath: $0)
        }) {
            let exchange = CodexAppServerExchange(executableURL: URL(fileURLWithPath: executable))
            if let snapshot = exchange.run() { return snapshot }
        }
        return nil
    }

    private func readFromSessions() -> QuotaSnapshot? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sessionsDirectory.path) else {
            return nil
        }

        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
        guard let enumerator = fileManager.enumerator(
            at: sessionsDirectory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        let cutoff = Date().addingTimeInterval(-14 * 24 * 60 * 60)
        var files: [(url: URL, modified: Date, size: UInt64)] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl",
                  let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  values.isRegularFile == true else {
                continue
            }

            let modified = values.contentModificationDate ?? .distantPast
            guard modified >= cutoff else {
                continue
            }

            files.append((fileURL, modified, UInt64(values.fileSize ?? 0)))
        }

        let sortedFiles = files.sorted { $0.modified > $1.modified }.prefix(40)
        var latestSnapshot: QuotaSnapshot?

        for file in sortedFiles {
            if let latestSnapshot, file.modified < latestSnapshot.logDate {
                break
            }

            if let snapshot = readFromSessionFile(url: file.url, size: file.size) {
                if let currentSnapshot = latestSnapshot {
                    if snapshot.logDate > currentSnapshot.logDate {
                        latestSnapshot = snapshot
                    }
                } else {
                    latestSnapshot = snapshot
                }
            }
        }

        return latestSnapshot
    }

    private func readFromSessionFile(url: URL, size: UInt64) -> QuotaSnapshot? {
        if isSubagentSessionFile(url: url) {
            return nil
        }

        let maxTailBytes: UInt64 = 4 * 1024 * 1024
        let data: Data

        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            if size > maxTailBytes {
                try handle.seek(toOffset: size - maxTailBytes)
                data = try handle.readToEnd() ?? Data()
            } else {
                data = try handle.readToEnd() ?? Data()
            }
        } catch {
            return nil
        }

        guard var text = String(data: data, encoding: .utf8), !text.isEmpty else {
            return nil
        }

        if size > maxTailBytes, let firstNewline = text.firstIndex(of: "\n") {
            text.removeSubrange(text.startIndex...firstNewline)
        }

        for line in text.split(separator: "\n", omittingEmptySubsequences: true).reversed() {
            guard line.contains("\"rate_limits\""),
                  line.contains("\"token_count\""),
                  let snapshot = decodeSessionRateLimitLine(String(line)) else {
                continue
            }

            if isCurrentRateLimitEvent(snapshot.event), isUsefulRateLimitEvent(snapshot.event) {
                return snapshot
            }
        }

        return nil
    }

    private func isSubagentSessionFile(url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer {
            try? handle.close()
        }

        let headData = (try? handle.read(upToCount: 64 * 1024)) ?? Data()
        guard let headText = String(data: headData, encoding: .utf8),
              let firstLine = headText.split(separator: "\n", omittingEmptySubsequences: true).first,
              let data = String(firstLine).data(using: .utf8),
              let entry = try? JSONDecoder().decode(SessionMetaLogEntry.self, from: data),
              entry.type == "session_meta" else {
            return false
        }

        return entry.payload.threadSource == "subagent" || entry.payload.source?.isSubagent == true
    }

    private func isUsefulRateLimitEvent(_ event: RateLimitEvent) -> Bool {
        let limits = event.rateLimits
        guard let weekly = limits.weekly else {
            return false
        }

        if let limitID = limits.limitID?.lowercased() {
            return limitID == "codex"
        }

        return weekly.usedPercent > 0 || limits.limitReached
    }

    private func decodeSessionRateLimitLine(_ line: String) -> QuotaSnapshot? {
        guard let data = line.data(using: .utf8),
              let entry = try? JSONDecoder().decode(SessionLogEntry.self, from: data),
              entry.payload.type == "token_count",
              let sessionRateLimits = entry.payload.rateLimits else {
            return nil
        }

        let primary = quotaWindow(from: sessionRateLimits.primary)
        let secondary = quotaWindow(from: sessionRateLimits.secondary)
        guard primary != nil || secondary != nil else {
            return nil
        }

        let event = RateLimitEvent(
            type: "codex.rate_limits",
            planType: sessionRateLimits.planType,
            rateLimits: RateLimits(
                limitID: sessionRateLimits.limitID,
                allowed: true,
                limitReached: sessionRateLimits.rateLimitReachedType != nil,
                primary: primary,
                secondary: secondary
            )
        )

        return QuotaSnapshot(
            event: event,
            logDate: parseSessionTimestamp(entry.timestamp) ?? Date(),
            readDate: Date(),
            source: .codexSessions
        )
    }

    private func quotaWindow(from window: SessionQuotaWindow?) -> QuotaWindow? {
        guard let window else {
            return nil
        }
        let usedPercent = min(100, max(0, Int(ceil(window.usedPercent))))

        return QuotaWindow(
            usedPercent: usedPercent,
            windowMinutes: window.windowMinutes,
            resetAfterSeconds: max(0, Int(window.resetsAt - Date().timeIntervalSince1970)),
            resetAt: window.resetsAt
        )
    }

    private func parseSessionTimestamp(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }

    private func readFromLogs(databasePath: String) throws -> QuotaSnapshot? {
        guard let schema = try loadLogSchema(databasePath: databasePath) else {
            return nil
        }

        let body = quoteIdentifier(schema.bodyColumn)
        let exactEventClause = """
        (
          \(body) like 'Received message {"type":"codex.rate_limits"%'
          or \(body) like 'Received message {\\\"type\\\":\\\"codex.rate_limits\\\"%'
          or (
            \(body) like '%responses_websocket.stream_request%'
            and (
              \(body) like '%: websocket event: {"type":"codex.rate_limits"%'
              or \(body) like '%: websocket event: {\\\"type\\\":\\\"codex.rate_limits\\\"%'
            )
          )
        )
        and \(body) not like '%exec_command%'
        and \(body) not like '%tool exec_command%'
        and \(body) not like '%*** Begin Patch%'
        and \(body) not like '%Sources/CodexVisual%'
        """
        return try readFromLogs(databasePath: databasePath, schema: schema, whereClause: exactEventClause, limit: 100)
    }

    private func readFromLogs(databasePath: String, schema: LogSchema, whereClause: String, limit: Int) throws -> QuotaSnapshot? {
        let ts = quoteIdentifier(schema.timestampColumn)
        let body = quoteIdentifier(schema.bodyColumn)
        let id = quoteIdentifier(schema.idColumn ?? "rowid")
        let orderColumns = [schema.timestampColumn, schema.timestampNanosColumn, schema.idColumn]
            .compactMap { $0 }
            .map { "\(quoteIdentifier($0)) desc" }
            .joined(separator: ", ")
        let recentLimit = max(limit * 20, 10_000)
        let query = """
        with recent_ids as (
            select \(id)
            from logs
            order by \(orderColumns)
            limit \(recentLimit)
        )
        select
            \(ts),
            substr(
                \(body),
                case when instr(\(body), 'codex.rate_limits') > 128 then instr(\(body), 'codex.rate_limits') - 128 else 1 end,
                100000
            )
        from logs
        where \(id) in recent_ids
          and \(whereClause)
        order by \(orderColumns)
        limit \(limit)
        ;
        """

        let output = try runSQLite(databasePath: databasePath, query: query)
        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, let timestamp = TimeInterval(parts[0]) else {
                continue
            }

            let body = String(parts[1])
            if let event = extractRateLimitEvent(from: body) {
                let snapshot = QuotaSnapshot(
                    event: event,
                    logDate: date(fromDatabaseTimestamp: timestamp),
                    readDate: Date(),
                    source: .codexLogs
                )

                if isCurrentRateLimitEvent(event) {
                    return snapshot
                }
            }
        }

        return nil
    }

    private func loadLogSchema(databasePath: String) throws -> LogSchema? {
        let output = try runSQLite(databasePath: databasePath, query: "pragma table_info(logs);")
        let columns = output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> SQLiteColumn? in
                let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard parts.count >= 3 else {
                    return nil
                }
                return SQLiteColumn(name: String(parts[1]), type: String(parts[2]))
            }

        guard !columns.isEmpty else {
            return nil
        }

        let names = columns.map(\.name)
        let timestampColumn = firstExisting(in: names, candidates: ["ts", "timestamp", "created_at", "time", "date"]) ?? "ts"
        let nanosColumn = firstExisting(in: names, candidates: ["ts_nanos", "timestamp_nanos", "nanos"])
        let idColumn = firstExisting(in: names, candidates: ["id", "rowid"])
        let bodyColumn = firstExisting(
            in: names,
            candidates: ["feedback_log_body", "body", "message", "text", "payload", "event", "json"]
        ) ?? columns.first { column in
            column.type.localizedCaseInsensitiveContains("text")
                && ["body", "message", "payload", "event", "json", "log"].contains { namePart in
                    column.name.localizedCaseInsensitiveContains(namePart)
                }
        }?.name

        guard names.contains(timestampColumn), let bodyColumn, names.contains(bodyColumn) else {
            return nil
        }

        return LogSchema(
            timestampColumn: timestampColumn,
            timestampNanosColumn: nanosColumn,
            idColumn: idColumn,
            bodyColumn: bodyColumn
        )
    }

    private func isCurrentRateLimitEvent(_ event: RateLimitEvent) -> Bool {
        (event.rateLimits.weekly?.resetDate ?? .distantPast) > Date()
    }

    private func runSQLite(databasePath: String, query: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sqlitePath)
        process.arguments = ["-readonly", "-separator", "\t", databasePath, query]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw QuotaReadError.cannotRunSQLite(error.localizedDescription)
        }
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw QuotaReadError.sqliteFailed(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }

    private func firstExisting(in names: [String], candidates: [String]) -> String? {
        for candidate in candidates {
            if names.contains(candidate) {
                return candidate
            }
        }

        return nil
    }

    private func quoteIdentifier(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func date(fromDatabaseTimestamp timestamp: TimeInterval) -> Date {
        if timestamp > 10_000_000_000 {
            return Date(timeIntervalSince1970: timestamp / 1000)
        }

        return Date(timeIntervalSince1970: timestamp)
    }

    private func extractRateLimitEvent(from body: String) -> RateLimitEvent? {
        let needles = ["{\"type\":\"codex.rate_limits\"", "{\\\"type\\\":\\\"codex.rate_limits\\\""]
        let maxCandidateLength = 100_000

        for needle in needles {
            var searchStart = body.startIndex
            while let range = body.range(of: needle, range: searchStart..<body.endIndex) {
                let candidateEnd = body.index(
                    range.lowerBound,
                    offsetBy: maxCandidateLength,
                    limitedBy: body.endIndex
                ) ?? body.endIndex
                let rawCandidate = String(body[range.lowerBound..<candidateEnd])
                let candidate: String
                if needle.contains("\\\"") {
                    candidate = rawCandidate
                        .replacingOccurrences(of: "\\\"", with: "\"")
                        .replacingOccurrences(of: "\\\\", with: "\\")
                } else {
                    candidate = rawCandidate
                }

                if let event = decodeJSONPrefix(candidate), event.type == "codex.rate_limits" {
                    return event
                }

                searchStart = body.index(after: range.lowerBound)
            }
        }

        return nil
    }

    private func decodeJSONPrefix(_ text: String) -> RateLimitEvent? {
        let decoder = JSONDecoder()
        var depth = 0
        var inString = false
        var isEscaped = false

        for (offset, character) in text.enumerated() {
            if inString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    inString = false
                }
                continue
            }

            if character == "\"" {
                inString = true
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    let endIndex = text.index(text.startIndex, offsetBy: offset + 1)
                    let jsonText = String(text[..<endIndex])
                    guard let data = jsonText.data(using: .utf8) else {
                        return nil
                    }
                    return try? decoder.decode(RateLimitEvent.self, from: data)
                }
            }
        }

        return nil
    }

    func diagnostics() -> String {
        var lines = [
            "CodexVisual diagnostics",
            "Home: \(NSHomeDirectory())",
            "Sessions: \(sessionsDirectory.path)",
            "Sessions exists: \(FileManager.default.fileExists(atPath: sessionsDirectory.path))",
            "Checked databases:"
        ]

        if let sessionSnapshot = readFromSessions() {
            if let weekly = sessionSnapshot.event.rateLimits.weekly {
                lines.append("Latest session weekly quota: \(weekly.remainingPercent)%")
            }
            lines.append("Latest session quota read date: \(sessionSnapshot.logDate)")
        }

        for databasePath in databasePaths {
            let exists = FileManager.default.fileExists(atPath: databasePath)
            lines.append("- \(databasePath)")
            lines.append("  exists: \(exists)")

            guard exists else {
                continue
            }

            if let attributes = try? FileManager.default.attributesOfItem(atPath: databasePath) {
                if let size = attributes[.size] as? NSNumber {
                    lines.append("  size: \(size.int64Value) bytes")
                }
                if let modified = attributes[.modificationDate] as? Date {
                    lines.append("  modified: \(modified)")
                }
            }

            if let total = try? runSQLite(databasePath: databasePath, query: "select count(*) from logs;")
                .trimmingCharacters(in: .whitespacesAndNewlines) {
                lines.append("  log rows: \(total)")
            }

            if let schema = try? loadLogSchema(databasePath: databasePath) {
                lines.append("  detected timestamp column: \(schema.timestampColumn)")
                lines.append("  detected body column: \(schema.bodyColumn)")
                if let candidates = try? runSQLite(
                    databasePath: databasePath,
                    query: "select count(*) from logs where \(quoteIdentifier(schema.bodyColumn)) like '%codex.rate_limits%';"
                ).trimmingCharacters(in: .whitespacesAndNewlines) {
                    lines.append("  codex.rate_limits candidates: \(candidates)")
                }
            }
        }

        lines.append("Cache: \(cacheURL.path)")
        lines.append("Cache exists: \(FileManager.default.fileExists(atPath: cacheURL.path))")
        lines.append("Legacy cache: \(legacyCacheURL.path)")
        lines.append("Legacy cache exists: \(FileManager.default.fileExists(atPath: legacyCacheURL.path))")
        return lines.joined(separator: "\n")
    }

    private var cacheURL: URL {
        if let directory = ProcessInfo.processInfo.environment["CODEX_VISUAL_CACHE_DIR"] {
            return URL(fileURLWithPath: directory).appendingPathComponent("latest-rate-limit.json")
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("CodexVisual/latest-rate-limit.json")
    }

    private var legacyCacheURL: URL {
        if let directory = ProcessInfo.processInfo.environment["CODEX_VISUAL_CACHE_DIR"] {
            return URL(fileURLWithPath: directory).appendingPathComponent("legacy-rate-limit.json")
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("CodexQuotaBar/latest-rate-limit.json")
    }

    private func saveCache(snapshot: QuotaSnapshot) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let payload = CachedSnapshot(
                schemaVersion: CachedSnapshot.currentSchemaVersion,
                event: snapshot.event,
                logTimestamp: snapshot.logDate.timeIntervalSince1970,
                cachedTimestamp: Date().timeIntervalSince1970,
                source: snapshot.source.rawValue
            )
            let data = try encoder.encode(payload)
            try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            // Cache failures should not hide live quota data.
        }
    }

    private func readCache() -> QuotaSnapshot? {
        readCache(at: cacheURL, source: .localCache)
            ?? readCache(at: legacyCacheURL, source: .migratedCache)
    }

    private func readAccountCache(maxAge: TimeInterval) -> QuotaSnapshot? {
        do {
            let data = try Data(contentsOf: cacheURL)
            let cached = try JSONDecoder().decode(CachedSnapshot.self, from: data)
            guard cached.schemaVersion == CachedSnapshot.currentSchemaVersion,
                  cached.source == SnapshotSource.codexAccount.rawValue,
                  Date().timeIntervalSince1970 - cached.cachedTimestamp <= maxAge,
                  isCurrentRateLimitEvent(cached.event),
                  isUsefulRateLimitEvent(cached.event) else {
                return nil
            }
            return QuotaSnapshot(
                event: cached.event,
                logDate: Date(timeIntervalSince1970: cached.logTimestamp),
                readDate: Date(timeIntervalSince1970: cached.cachedTimestamp),
                source: .localCache
            )
        } catch {
            return nil
        }
    }

    private func readCache(at url: URL, source: SnapshotSource) -> QuotaSnapshot? {
        do {
            let data = try Data(contentsOf: url)
            let cached = try JSONDecoder().decode(CachedSnapshot.self, from: data)
            guard cached.schemaVersion == CachedSnapshot.currentSchemaVersion,
                  cached.source == SnapshotSource.codexAccount.rawValue
                    || cached.source == SnapshotSource.codexLogs.rawValue
                    || cached.source == SnapshotSource.codexSessions.rawValue else {
                return nil
            }
            guard isCurrentRateLimitEvent(cached.event), isUsefulRateLimitEvent(cached.event) else {
                return nil
            }
            return QuotaSnapshot(
                event: cached.event,
                logDate: Date(timeIntervalSince1970: cached.logTimestamp),
                readDate: Date(),
                source: source
            )
        } catch {
            return nil
        }
    }
}

struct SQLiteColumn {
    let name: String
    let type: String
}

struct LogSchema {
    let timestampColumn: String
    let timestampNanosColumn: String?
    let idColumn: String?
    let bodyColumn: String
}

struct SessionMetaLogEntry: Decodable {
    let type: String
    let payload: SessionMetaPayload
}

struct SessionMetaPayload: Decodable {
    let threadSource: String?
    let source: SessionSource?

    enum CodingKeys: String, CodingKey {
        case threadSource = "thread_source"
        case source
    }
}

enum SessionSource: Decodable {
    case string(String)
    case object(hasSubagent: Bool)

    var isSubagent: Bool {
        switch self {
        case .string:
            return false
        case .object(let hasSubagent):
            return hasSubagent
        }
    }

    init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }

        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self = .object(hasSubagent: container.contains(DynamicCodingKey(stringValue: "subagent")!))
    }
}

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

struct SessionLogEntry: Decodable {
    let timestamp: String
    let payload: SessionPayload
}

struct SessionPayload: Decodable {
    let type: String?
    let rateLimits: SessionRateLimits?

    enum CodingKeys: String, CodingKey {
        case type
        case rateLimits = "rate_limits"
    }
}

struct SessionRateLimits: Decodable {
    let limitID: String?
    let planType: String?
    let primary: SessionQuotaWindow?
    let secondary: SessionQuotaWindow?
    let rateLimitReachedType: String?

    enum CodingKeys: String, CodingKey {
        case limitID = "limit_id"
        case planType = "plan_type"
        case primary
        case secondary
        case rateLimitReachedType = "rate_limit_reached_type"
    }
}

struct SessionQuotaWindow: Decodable {
    let usedPercent: Double
    let windowMinutes: Int
    let resetsAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case windowMinutes = "window_minutes"
        case resetsAt = "resets_at"
    }
}

struct CachedSnapshot: Codable {
    static let currentSchemaVersion = 5

    let schemaVersion: Int
    let event: RateLimitEvent
    let logTimestamp: TimeInterval
    let cachedTimestamp: TimeInterval
    let source: String
}

enum QuotaColor {
    static func fill(for remaining: Int) -> NSColor {
        if remaining < 20 {
            return NSColor(calibratedRed: 1.00, green: 0.23, blue: 0.19, alpha: 1)
        }

        if remaining <= 50 {
            return NSColor(calibratedRed: 1.00, green: 0.64, blue: 0.00, alpha: 1)
        }

        if remaining <= 80 {
            return NSColor(calibratedRed: 0.02, green: 0.48, blue: 1.00, alpha: 1)
        }

        return NSColor(calibratedRed: 0.12, green: 0.84, blue: 0.42, alpha: 1)
    }

    static func statusText(for remaining: Int) -> NSColor {
        if remaining < 20 {
            return NSColor(calibratedRed: 1.00, green: 0.38, blue: 0.36, alpha: 1)
        }

        if remaining <= 50 {
            return NSColor(calibratedRed: 1.00, green: 0.76, blue: 0.20, alpha: 1)
        }

        if remaining <= 80 {
            return NSColor(calibratedRed: 0.36, green: 0.68, blue: 1.00, alpha: 1)
        }

        return NSColor(calibratedRed: 0.34, green: 0.94, blue: 0.62, alpha: 1)
    }

    static func background(for remaining: Int) -> NSColor {
        fill(for: remaining).withAlphaComponent(remaining < 20 ? 0.13 : 0.11)
    }
}

final class QuotaProgressView: NSView {
    private let trackLayer = CALayer()
    private let fillLayer = CALayer()
    private var value: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        wantsLayer = true
        layer?.masksToBounds = false
        trackLayer.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.45).cgColor
        fillLayer.backgroundColor = NSColor.controlAccentColor.cgColor
        layer?.addSublayer(trackLayer)
        layer?.addSublayer(fillLayer)
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let cornerRadius = bounds.height / 2
        trackLayer.frame = bounds
        trackLayer.cornerRadius = cornerRadius
        fillLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * value, height: bounds.height)
        fillLayer.cornerRadius = cornerRadius
        CATransaction.commit()
    }

    func update(remaining: Int, color: NSColor) {
        value = CGFloat(min(100, max(0, remaining))) / 100
        fillLayer.backgroundColor = color.cgColor
        needsLayout = true
    }
}

final class QuotaWindowView: NSView {
    private let nameLabel = NSTextField(labelWithString: "")
    private let percentValueLabel = NSTextField(labelWithString: "")
    private let percentSymbolLabel = NSTextField(labelWithString: "%")
    private let usedLabel = NSTextField(labelWithString: "")
    private let resetLabel = NSTextField(labelWithString: "")
    private let progress = QuotaProgressView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 72)
    }

    private func configure() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.10).cgColor

        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .labelColor

        percentValueLabel.font = .monospacedDigitSystemFont(ofSize: 25, weight: .bold)
        percentValueLabel.textColor = .labelColor
        percentValueLabel.alignment = .right
        percentValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        percentSymbolLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        percentSymbolLabel.textColor = .labelColor
        percentSymbolLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        usedLabel.font = .systemFont(ofSize: 11, weight: .medium)
        usedLabel.textColor = .secondaryLabelColor
        usedLabel.lineBreakMode = .byTruncatingTail
        usedLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        resetLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        resetLabel.textColor = .secondaryLabelColor
        resetLabel.alignment = .right
        resetLabel.lineBreakMode = .byTruncatingTail
        resetLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let percentStack = NSStackView(views: [percentValueLabel, percentSymbolLabel])
        percentStack.orientation = .horizontal
        percentStack.alignment = .firstBaseline
        percentStack.spacing = 3

        percentStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let topStack = NSStackView(views: [nameLabel, NSView(), percentStack])
        topStack.orientation = .horizontal
        topStack.alignment = .centerY
        topStack.spacing = 6

        let detailStack = NSStackView(views: [usedLabel, NSView(), resetLabel])
        detailStack.orientation = .horizontal
        detailStack.alignment = .centerY
        detailStack.spacing = 8

        let stack = NSStackView(views: [topStack, progress, detailStack])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9),
            progress.widthAnchor.constraint(equalTo: stack.widthAnchor),
            progress.heightAnchor.constraint(equalToConstant: 5),
            detailStack.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    func update(name: String, remaining: Int, used: Int, resetText: String) {
        nameLabel.stringValue = name
        percentValueLabel.stringValue = "\(remaining)"
        usedLabel.stringValue = AppStrings.usedCompact(used)
        resetLabel.stringValue = AppStrings.resetCompact(resetText)
        progress.update(remaining: remaining, color: QuotaColor.fill(for: remaining))
        layer?.backgroundColor = QuotaColor.background(for: remaining).cgColor
    }
}

final class QuotaOverviewView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let planLabel = NSTextField(labelWithString: "")
    private let fiveHourView = QuotaWindowView()
    private let weeklyView = QuotaWindowView()
    private let sourceLabel = NSTextField(labelWithString: "")
    private var showsFiveHourQuota = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 420, height: showsFiveHourQuota ? 230 : 150)
    }

    private func configure() {
        frame.size = intrinsicContentSize

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor

        planLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        planLabel.textColor = .secondaryLabelColor
        planLabel.alignment = .right

        sourceLabel.font = .systemFont(ofSize: 10.5, weight: .regular)
        sourceLabel.textColor = .secondaryLabelColor
        sourceLabel.lineBreakMode = .byTruncatingTail
        sourceLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let header = NSStackView(views: [titleLabel, NSView(), planLabel])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 10

        fiveHourView.isHidden = true

        let stack = NSStackView(views: [header, fiveHourView, weeklyView, sourceLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            fiveHourView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            weeklyView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            fiveHourView.heightAnchor.constraint(equalToConstant: 72),
            weeklyView.heightAnchor.constraint(equalToConstant: 72),
            sourceLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    func update(snapshot: QuotaSnapshot, plan: String, timeFormatter: DateFormatter, shortTimeFormatter: DateFormatter) {
        guard let weekly = snapshot.event.rateLimits.weekly else {
            return
        }

        let fiveHour = snapshot.event.fiveHourQuota
        showsFiveHourQuota = fiveHour != nil
        fiveHourView.isHidden = fiveHour == nil
        invalidateIntrinsicContentSize()
        frame.size = intrinsicContentSize

        titleLabel.stringValue = AppStrings.quotaOverview
        planLabel.stringValue = AppStrings.plan(plan)
        if let fiveHour {
            fiveHourView.update(
                name: AppStrings.fiveHourQuota,
                remaining: fiveHour.remainingPercent,
                used: fiveHour.effectiveUsedPercent,
                resetText: resetText(for: fiveHour.resetDate, timeFormatter: timeFormatter)
            )
        }
        weeklyView.update(
            name: AppStrings.weeklyQuota,
            remaining: weekly.remainingPercent,
            used: weekly.effectiveUsedPercent,
            resetText: resetText(for: weekly.resetDate, timeFormatter: timeFormatter)
        )
        sourceLabel.stringValue = AppStrings.sourceCompact(
            source: snapshot.isHistorical ? AppStrings.historicalData : snapshot.source.title,
            readTime: timeFormatter.string(from: snapshot.logDate)
        )
    }

    private func resetText(for date: Date, timeFormatter: DateFormatter) -> String {
        let seconds = date.timeIntervalSinceNow
        if seconds > 0, seconds < 3600 {
            let rounded = max(0, Int(ceil(seconds)))
            return String(format: "%02d:%02d", rounded / 60, rounded % 60)
        }

        if seconds <= 0 {
            return AppStrings.resetPending
        }

        let hourMinuteFormatter = DateFormatter()
        hourMinuteFormatter.locale = timeFormatter.locale
        hourMinuteFormatter.dateFormat = "HH:mm"

        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.locale = timeFormatter.locale
        dateTimeFormatter.dateFormat = AppStrings.dateFormat

        if Calendar.current.isDateInToday(date) {
            return AppStrings.text("今天 \(dateTimeFormatter.string(from: date))", "Today \(hourMinuteFormatter.string(from: date))", "今日 \(hourMinuteFormatter.string(from: date))")
        }

        if Calendar.current.isDateInTomorrow(date) {
            return AppStrings.text("明天 \(dateTimeFormatter.string(from: date))", "Tomorrow \(dateTimeFormatter.string(from: date))", "明日 \(dateTimeFormatter.string(from: date))")
        }

        return timeFormatter.string(from: date)
    }
}

enum QuotaStatusImage {
    static let size = NSSize(width: 166, height: 22)

    static func make(fiveHour: Int?, weekly: Int?, fiveHourReset: Date?, weeklyReset: Date?) -> NSImage {
        let image = NSImage(size: size, flipped: false) { _ in
            drawRow(label: "5h", remaining: fiveHour, resetText: resetText(for: fiveHourReset, weekly: false), y: 11)
            drawRow(label: "7d", remaining: weekly, resetText: resetText(for: weeklyReset, weekly: true), y: 0)
            return true
        }
        image.cacheMode = .never
        image.isTemplate = false
        return image
    }

    static func resetText(for date: Date?, weekly: Bool) -> String {
        guard let date, date > Date() else { return "--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = weekly ? "MM/dd" : "HH:mm"
        return formatter.string(from: date)
    }

    static func currentWindow(_ window: QuotaWindow?, snapshot: QuotaSnapshot?) -> QuotaWindow? {
        guard let snapshot, !snapshot.isHistorical, let window, window.resetDate > Date() else { return nil }
        return window
    }

    private static func drawRow(label: String, remaining: Int?, resetText: String, y: CGFloat) {
        let value = remaining ?? 0
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: MenuBarTextGroup.label.currentColor.resolved(for: value)
        ]
        let percentAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: MenuBarTextGroup.percent.currentColor.resolved(for: value)
        ]
        let resetAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
            .foregroundColor: MenuBarTextGroup.reset.currentColor.resolved(for: value)
        ]

        (label as NSString).draw(at: NSPoint(x: 3, y: y), withAttributes: labelAttributes)
        let barRect = NSRect(x: 24, y: y + 3.5, width: 55, height: 4)
        NSColor.labelColor.withAlphaComponent(0.20).setFill()
        NSBezierPath(roundedRect: barRect, xRadius: 2, yRadius: 2).fill()
        let fillRect = NSRect(x: barRect.minX, y: barRect.minY,
                              width: barRect.width * CGFloat(min(100, max(0, value))) / 100, height: barRect.height)
        MenuBarTextGroup.bar.currentColor.resolvedForBar(for: value).setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: 2, yRadius: 2).fill()

        let percent = remaining.map { "\($0)%" } ?? "--"
        (percent as NSString).draw(at: NSPoint(x: 86, y: y), withAttributes: percentAttributes)
        (resetText as NSString).draw(at: NSPoint(x: 122, y: y), withAttributes: resetAttributes)
    }
}

private enum QuotaRefreshResult: Sendable {
    case success(QuotaSnapshot)
    case failure(String)
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let reader = QuotaReader()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let overviewItem = NSMenuItem()
    private let overviewView = QuotaOverviewView()
    private let orderItem = NSMenuItem()
    private let planItem = NSMenuItem()
    private let logTimeItem = NSMenuItem()
    private let readTimeItem = NSMenuItem()
    private let errorItem = NSMenuItem()
    private let languageItem = NSMenuItem()
    private let languageMenu = NSMenu()
    private let systemLanguageItem = NSMenuItem()
    private let englishLanguageItem = NSMenuItem()
    private let chineseLanguageItem = NSMenuItem()
    private let japaneseLanguageItem = NSMenuItem()
    private let refreshFrequencyItem = NSMenuItem()
    private let refreshFrequencyMenu = NSMenu()
    private let smartRefreshItem = NSMenuItem()
    private let fiveSecondRefreshItem = NSMenuItem()
    private let fifteenSecondRefreshItem = NSMenuItem()
    private let sixtySecondRefreshItem = NSMenuItem()
    private let fiveMinuteRefreshItem = NSMenuItem()
    private let manualRefreshItem = NSMenuItem()
    private let menuBarDisplayItem = NSMenuItem()
    private let menuBarDisplayMenu = NSMenu()
    private let barsDisplayItem = NSMenuItem()
    private let numbersDisplayItem = NSMenuItem()
    private let menuBarTextColorItem = NSMenuItem()
    private let menuBarTextColorMenu = NSMenu()
    private var menuBarTextColorItems: [MenuBarTextGroup: [MenuBarTextColor: NSMenuItem]] = [:]
    private let openDashboardItem = NSMenuItem()
    private let refreshItem = NSMenuItem()
    private let checkUpdatesItem = NSMenuItem()
    private let uninstallItem = NSMenuItem()
    private let quitItem = NSMenuItem()
    private var timer: Timer?
    private var isRefreshing = false
    private var latestSnapshot: QuotaSnapshot?
    private var controlWindow: NSWindow?
    private let windowOverviewView = QuotaOverviewView()
    private let windowErrorLabel = NSTextField(wrappingLabelWithString: AppStrings.noQuotaYet)
    private let windowRefreshButton = NSButton()
    private let windowUpdateButton = NSButton()
    private let windowUninstallButton = NSButton()
    private let windowQuitButton = NSButton()

    private var quotaDetailItems: [NSMenuItem] {
        [overviewItem]
    }

    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = AppStrings.dateLocale
        formatter.dateFormat = AppStrings.dateFormat
        return formatter
    }()

    private lazy var shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = AppStrings.dateLocale
        formatter.dateFormat = AppStrings.shortTimeFormat
        return formatter
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureMenu()
        refresh(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showControlWindow()
        return false
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === controlWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func configureMenu() {
        configureStatusButton()
        statusItem.menu = menu
        overviewItem.view = overviewView
        overviewItem.isHidden = true
        menu.addItem(overviewItem)

        errorItem.isHidden = true
        errorItem.isEnabled = false
        errorItem.title = " "
        menu.addItem(errorItem)

        menu.addItem(.separator())
        configureLanguageMenu()
        menu.addItem(languageItem)
        configureRefreshFrequencyMenu()
        menu.addItem(refreshFrequencyItem)
        configureMenuBarDisplayMenu()
        menu.addItem(menuBarDisplayItem)
        configureMenuBarTextColorMenu()
        menu.addItem(menuBarTextColorItem)

        menu.addItem(.separator())
        openDashboardItem.action = #selector(openDashboard(_:))
        openDashboardItem.target = self
        menu.addItem(openDashboardItem)

        refreshItem.action = #selector(refresh(_:))
        refreshItem.keyEquivalent = "r"
        refreshItem.target = self
        menu.addItem(refreshItem)

        checkUpdatesItem.action = #selector(checkForUpdates(_:))
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)

        menu.addItem(.separator())
        uninstallItem.action = #selector(uninstall(_:))
        uninstallItem.target = self
        menu.addItem(uninstallItem)

        quitItem.action = #selector(quit(_:))
        quitItem.keyEquivalent = "q"
        quitItem.target = self
        menu.addItem(quitItem)

        updateStaticMenuText()
        updateLanguageMenuState()
        updateRefreshModeMenuState()
        updateMenuBarDisplayModeMenuState()
        updateMenuBarTextColorMenuState()
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        statusItem.length = NSStatusItem.variableLength
        button.title = ""
        button.image = nil
        button.imagePosition = .noImage
        button.imageScaling = .scaleProportionallyDown
        updateStatusButton()
    }

    private func configureLanguageMenu() {
        languageItem.submenu = languageMenu

        systemLanguageItem.action = #selector(selectSystemLanguage(_:))
        systemLanguageItem.target = self
        englishLanguageItem.action = #selector(selectEnglishLanguage(_:))
        englishLanguageItem.target = self
        chineseLanguageItem.action = #selector(selectChineseLanguage(_:))
        chineseLanguageItem.target = self

        japaneseLanguageItem.action = #selector(selectJapaneseLanguage(_:))
        japaneseLanguageItem.target = self

        languageMenu.addItem(systemLanguageItem)
        languageMenu.addItem(englishLanguageItem)
        languageMenu.addItem(chineseLanguageItem)
        languageMenu.addItem(japaneseLanguageItem)
    }

    private func configureRefreshFrequencyMenu() {
        refreshFrequencyItem.submenu = refreshFrequencyMenu

        let pairs: [(NSMenuItem, RefreshMode)] = [
            (smartRefreshItem, .smart),
            (fiveSecondRefreshItem, .everyFiveSeconds),
            (fifteenSecondRefreshItem, .everyFifteenSeconds),
            (sixtySecondRefreshItem, .everySixtySeconds),
            (fiveMinuteRefreshItem, .everyFiveMinutes),
            (manualRefreshItem, .manual)
        ]

        for (item, mode) in pairs {
            item.action = #selector(selectRefreshMode(_:))
            item.target = self
            item.representedObject = mode.rawValue
            refreshFrequencyMenu.addItem(item)
        }
    }

    private func configureMenuBarDisplayMenu() {
        menuBarDisplayItem.submenu = menuBarDisplayMenu

        let pairs: [(NSMenuItem, MenuBarDisplayMode)] = [
            (barsDisplayItem, .bars),
            (numbersDisplayItem, .numbers)
        ]

        for (item, mode) in pairs {
            item.action = #selector(selectMenuBarDisplayMode(_:))
            item.target = self
            item.representedObject = mode.rawValue
            menuBarDisplayMenu.addItem(item)
        }
    }

    private func configureMenuBarTextColorMenu() {
        menuBarTextColorItem.submenu = menuBarTextColorMenu

        for group in MenuBarTextGroup.allCases {
            let groupItem = NSMenuItem()
            let groupMenu = NSMenu()
            groupItem.submenu = groupMenu

            var colorItems: [MenuBarTextColor: NSMenuItem] = [:]
            for color in MenuBarTextColor.allCases {
                let item = NSMenuItem()
                item.action = #selector(selectMenuBarTextColor(_:))
                item.target = self
                item.representedObject = "\(group.rawValue)|\(color.rawValue)"
                item.image = menuColorPreview(for: color)
                groupMenu.addItem(item)
                colorItems[color] = item
            }

            menuBarTextColorMenu.addItem(groupItem)
            menuBarTextColorItems[group] = colorItems
        }
    }

    private func updateDateFormatters() {
        timeFormatter.locale = AppStrings.dateLocale
        timeFormatter.dateFormat = AppStrings.dateFormat
        shortTimeFormatter.locale = AppStrings.dateLocale
        shortTimeFormatter.dateFormat = AppStrings.shortTimeFormat
    }

    private func updateStaticMenuText() {
        updateDateFormatters()
        statusItem.button?.toolTip = latestSnapshot.flatMap { snapshot in
            snapshot.event.rateLimits.weekly.map { weekly in
                AppStrings.quotaToolTip(
                    fiveHour: snapshot.event.fiveHourQuota?.remainingPercent,
                    weekly: weekly.remainingPercent
                )
            }
        } ?? AppStrings.statusToolTip
        orderItem.title = AppStrings.displayOrder
        languageItem.title = AppStrings.language
        systemLanguageItem.title = AppStrings.languageSystem
        englishLanguageItem.title = AppStrings.languageEnglish
        chineseLanguageItem.title = AppStrings.languageChinese
        japaneseLanguageItem.title = AppStrings.languageJapanese
        refreshFrequencyItem.title = AppStrings.refreshFrequency
        smartRefreshItem.title = AppStrings.refreshSmart
        fiveSecondRefreshItem.title = AppStrings.refreshEvery5Seconds
        fifteenSecondRefreshItem.title = AppStrings.refreshEvery15Seconds
        sixtySecondRefreshItem.title = AppStrings.refreshEvery60Seconds
        fiveMinuteRefreshItem.title = AppStrings.refreshEvery5Minutes
        manualRefreshItem.title = AppStrings.refreshManual
        menuBarDisplayItem.title = AppStrings.menuBarDisplay
        barsDisplayItem.title = AppStrings.menuBarDisplayBars
        numbersDisplayItem.title = AppStrings.menuBarDisplayNumbers
        menuBarTextColorItem.title = AppStrings.menuBarTextColor
        for group in MenuBarTextGroup.allCases {
            menuBarTextColorMenu.items.first(where: { $0.submenu?.items.contains(where: { item in
                (item.representedObject as? String)?.hasPrefix("\(group.rawValue)|") == true
            }) == true })?.title = title(for: group)

            for color in MenuBarTextColor.allCases {
                menuBarTextColorItems[group]?[color]?.title = title(for: color)
            }
        }
        openDashboardItem.title = AppStrings.openDashboard
        refreshItem.title = AppStrings.refreshNow
        checkUpdatesItem.title = AppStrings.checkForUpdates
        uninstallItem.title = AppStrings.uninstall
        quitItem.title = AppStrings.quit
        windowRefreshButton.title = AppStrings.refreshNow
        windowUpdateButton.title = AppStrings.checkForUpdates
        windowUninstallButton.title = AppStrings.uninstall
        windowQuitButton.title = AppStrings.quit
        windowErrorLabel.stringValue = AppStrings.noQuotaYet
        controlWindow?.title = AppStrings.controlWindowTitle
    }

    private func updateLanguageMenuState() {
        let currentMode = LanguageMode.current
        systemLanguageItem.state = currentMode == .system ? .on : .off
        englishLanguageItem.state = currentMode == .english ? .on : .off
        chineseLanguageItem.state = currentMode == .chinese ? .on : .off
        japaneseLanguageItem.state = currentMode == .japanese ? .on : .off
    }

    private func updateRefreshModeMenuState() {
        let currentMode = RefreshMode.current
        let pairs: [(NSMenuItem, RefreshMode)] = [
            (smartRefreshItem, .smart),
            (fiveSecondRefreshItem, .everyFiveSeconds),
            (fifteenSecondRefreshItem, .everyFifteenSeconds),
            (sixtySecondRefreshItem, .everySixtySeconds),
            (fiveMinuteRefreshItem, .everyFiveMinutes),
            (manualRefreshItem, .manual)
        ]

        for (item, mode) in pairs {
            item.state = currentMode == mode ? .on : .off
        }
    }

    private func updateMenuBarDisplayModeMenuState() {
        let currentMode = MenuBarDisplayMode.current
        let pairs: [(NSMenuItem, MenuBarDisplayMode)] = [
            (barsDisplayItem, .bars),
            (numbersDisplayItem, .numbers)
        ]

        for (item, mode) in pairs {
            item.state = currentMode == mode ? .on : .off
        }
    }

    private func updateMenuBarTextColorMenuState() {
        for group in MenuBarTextGroup.allCases {
            let currentColor = group.currentColor
            for color in MenuBarTextColor.allCases {
                menuBarTextColorItems[group]?[color]?.state = currentColor == color ? .on : .off
            }
        }
    }

    private func title(for group: MenuBarTextGroup) -> String {
        switch group {
        case .bar:
            return AppStrings.menuBarTextBar
        case .label:
            return AppStrings.menuBarTextLabel
        case .percent:
            return AppStrings.menuBarTextPercent
        case .reset:
            return AppStrings.menuBarTextReset
        }
    }

    private func title(for color: MenuBarTextColor) -> String {
        switch color {
        case .automatic:
            return AppStrings.text("跟随菜单栏", "Menu Bar Appearance", "メニューバーに合わせる")
        case .quota:
            return AppStrings.colorQuota
        case .white:
            return AppStrings.colorWhite
        case .blue:
            return AppStrings.colorBlue
        case .green:
            return AppStrings.colorGreen
        case .yellow:
            return AppStrings.colorYellow
        case .red:
            return AppStrings.colorRed
        case .gray:
            return AppStrings.colorGray
        }
    }

    private func menuColorPreview(for color: MenuBarTextColor) -> NSImage {
        let size = NSSize(width: 18, height: 14)
        let image = NSImage(size: size)

        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = NSRect(x: 2, y: 3, width: 14, height: 8)
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        if color == .quota {
            let colors = color.previewColors
            let segmentWidth = rect.width / CGFloat(colors.count)
            NSGraphicsContext.saveGraphicsState()
            path.addClip()
            for (index, previewColor) in colors.enumerated() {
                let segmentRect = NSRect(
                    x: rect.minX + CGFloat(index) * segmentWidth,
                    y: rect.minY,
                    width: index == colors.count - 1 ? rect.maxX - (rect.minX + CGFloat(index) * segmentWidth) : segmentWidth,
                    height: rect.height
                )
                previewColor.setFill()
                segmentRect.fill()
            }
            NSGraphicsContext.restoreGraphicsState()
        } else {
            color.previewColors.first?.setFill()
            path.fill()
        }

        NSColor.separatorColor.withAlphaComponent(0.75).setStroke()
        path.lineWidth = 0.8
        path.stroke()

        image.isTemplate = false
        return image
    }

    @objc private func refresh(_ sender: Any?) {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshItem.isEnabled = false
        windowRefreshButton.isEnabled = false
        let allowCache = sender == nil

        Task { @MainActor [weak self, reader] in
            let result = await Task.detached(priority: .utility) {
                do {
                    return QuotaRefreshResult.success(try reader.readLatest(allowCache: allowCache))
                } catch {
                    return QuotaRefreshResult.failure(error.localizedDescription)
                }
            }.value
            self?.finishRefresh(result)
        }
    }

    private func finishRefresh(_ result: QuotaRefreshResult) {
        isRefreshing = false
        refreshItem.isEnabled = true
        windowRefreshButton.isEnabled = true

        switch result {
        case .success(let snapshot):
            update(snapshot)
        case .failure(let message):
            latestSnapshot = nil
            updateStatusButton()
            statusItem.button?.toolTip = message
            for item in quotaDetailItems {
                item.isHidden = true
            }
            errorItem.title = message
            errorItem.isHidden = false
            updateWindow(error: message)
        }

        scheduleNextRefresh()
    }

    private func scheduleNextRefresh() {
        timer?.invalidate()
        timer = nil

        guard let interval = nextRefreshInterval() else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.refresh(nil)
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func nextRefreshInterval() -> TimeInterval? {
        guard var interval = RefreshMode.current.baseInterval else {
            return nil
        }

        if let snapshot = latestSnapshot {
            let resetDates = [
                snapshot.event.fiveHourQuota?.resetDate,
                snapshot.event.rateLimits.weekly?.resetDate
            ].compactMap { $0 }

            for resetDate in resetDates {
                let secondsUntilReset = resetDate.timeIntervalSinceNow
                if secondsUntilReset > 0, secondsUntilReset < interval {
                    interval = max(2, secondsUntilReset + 2)
                }
            }
        }

        return interval
    }

    @objc private func openDashboard(_ sender: Any?) {
        showControlWindow()
    }

    private func showControlWindow() {
        if controlWindow == nil {
            configureControlWindow()
        }

        if let snapshot = latestSnapshot {
            updateWindow(snapshot)
        } else {
            windowOverviewView.isHidden = true
            windowErrorLabel.isHidden = false
        }

        NSApp.setActivationPolicy(.regular)
        controlWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureControlWindow() {
        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        windowOverviewView.translatesAutoresizingMaskIntoConstraints = false
        windowOverviewView.isHidden = true

        windowErrorLabel.font = .systemFont(ofSize: 13, weight: .regular)
        windowErrorLabel.textColor = .secondaryLabelColor
        windowErrorLabel.alignment = .center
        windowErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        configureWindowButton(windowRefreshButton, action: #selector(refresh(_:)))
        configureWindowButton(windowUpdateButton, action: #selector(checkForUpdates(_:)))
        configureWindowButton(windowUninstallButton, action: #selector(uninstall(_:)))
        configureWindowButton(windowQuitButton, action: #selector(quit(_:)))

        let buttonStack = NSStackView(views: [
            windowRefreshButton,
            windowUpdateButton,
            windowUninstallButton,
            windowQuitButton
        ])
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [windowOverviewView, windowErrorLabel, buttonStack])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            windowOverviewView.widthAnchor.constraint(equalToConstant: 420),
            windowErrorLabel.widthAnchor.constraint(equalToConstant: 420),
            windowErrorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            buttonStack.widthAnchor.constraint(equalToConstant: 420)
        ])

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 456, height: 316),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppStrings.controlWindowTitle
        window.contentView = contentView
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        controlWindow = window
        updateStaticMenuText()
    }

    private func configureWindowButton(_ button: NSButton, action: Selector) {
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    @objc private func checkForUpdates(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://github.com/sunfhs/codex-usage-compact/releases/latest")!)
    }

    @objc private func uninstall(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = AppStrings.uninstallTitle
        alert.informativeText = AppStrings.uninstallMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: AppStrings.uninstallConfirm)
        alert.addButton(withTitle: AppStrings.cancel)

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        launchUninstaller()
        NSApp.terminate(nil)
    }

    @objc private func selectRefreshMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = RefreshMode(rawValue: rawValue) else {
            return
        }

        RefreshMode.current = mode
        updateRefreshModeMenuState()
        scheduleNextRefresh()
    }

    @objc private func selectMenuBarDisplayMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = MenuBarDisplayMode(rawValue: rawValue) else {
            return
        }

        MenuBarDisplayMode.current = mode
        updateMenuBarDisplayModeMenuState()
        updateStatusButton()
    }

    @objc private func selectMenuBarTextColor(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String else {
            return
        }

        let parts = rawValue.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let group = MenuBarTextGroup(rawValue: parts[0]),
              let color = MenuBarTextColor(rawValue: parts[1]) else {
            return
        }

        group.currentColor = color
        updateMenuBarTextColorMenuState()
        updateStatusButton()
    }

    private func launchUninstaller() {
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("uninstall-codexvisual-\(UUID().uuidString).sh")
        let script = """
        #!/bin/zsh
        /bin/sleep 1
        /usr/bin/pkill -x "CodexVisual" 2>/dev/null || true
        /usr/bin/pkill -x "CodexQuotaBar" 2>/dev/null || true
        /bin/rm -rf "$HOME/Applications/CodexVisual.app"
        /bin/rm -rf "$HOME/Applications/CodexQuotaBar.app"
        /bin/rm -rf "$HOME/Applications/Codex Visual.app"
        /bin/rm -rf "$HOME/Library/Application Support/CodexVisual"
        /bin/rm -rf "$HOME/Library/Application Support/CodexQuotaBar"
        /bin/rm -rf "$HOME/Library/Caches/com.orangeshushu.CodexVisual"
        /bin/rm -rf "$HOME/Library/Caches/CodexVisual"
        /bin/rm -f "$HOME/Library/Preferences/com.orangeshushu.CodexVisual.plist"
        /bin/rm -rf "$HOME/Library/HTTPStorages/com.orangeshushu.CodexVisual"
        /bin/rm -rf "$HOME/Library/WebKit/com.orangeshushu.CodexVisual"
        /bin/rm -rf "$HOME/Library/Containers/com.orangeshushu.CodexVisual"
        /bin/rm -rf "/Applications/CodexVisual.app" 2>/dev/null || true
        /bin/rm -rf "/Applications/CodexQuotaBar.app" 2>/dev/null || true
        /bin/rm -rf "/Applications/Codex Visual.app" 2>/dev/null || true
        /usr/bin/osascript -e 'display notification "\(AppStrings.uninstallDone)" with title "CodexVisual"' 2>/dev/null || true
        /bin/rm -f "$0"
        """

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = [scriptURL.path]
            try process.run()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    private func update(_ snapshot: QuotaSnapshot) {
        latestSnapshot = snapshot
        updateStaticMenuText()
        updateStatusButton()
        guard let weekly = snapshot.event.rateLimits.weekly else {
            overviewItem.isHidden = true
            updateWindow(error: "7d --")
            return
        }
        let fiveHour = snapshot.event.fiveHourQuota
        statusItem.button?.toolTip = AppStrings.quotaToolTip(
            fiveHour: fiveHour?.remainingPercent,
            weekly: weekly.remainingPercent
        ) + "\n" + (snapshot.isHistorical ? AppStrings.historicalData + "\n" : "")
            + AppStrings.dataUpdated(timeFormatter.string(from: snapshot.logDate))

        let plan = AppStrings.planName(snapshot.event.planType)
        for item in quotaDetailItems {
            item.isHidden = false
        }
        overviewView.update(
            snapshot: snapshot,
            plan: plan,
            timeFormatter: timeFormatter,
            shortTimeFormatter: shortTimeFormatter
        )
        updateWindow(snapshot)
        errorItem.isHidden = true
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        let fiveHour = QuotaStatusImage.currentWindow(latestSnapshot?.event.fiveHourQuota, snapshot: latestSnapshot)
        let weekly = QuotaStatusImage.currentWindow(latestSnapshot?.event.rateLimits.weekly, snapshot: latestSnapshot)
        let fiveText = fiveHour.map { "\($0.remainingPercent)%" } ?? "--"
        let weekText = weekly.map { "\($0.remainingPercent)%" } ?? "--"
        let fiveReset = QuotaStatusImage.resetText(for: fiveHour?.resetDate, weekly: false)
        let weekReset = QuotaStatusImage.resetText(for: weekly?.resetDate, weekly: true)
        button.setAccessibilityLabel("5h \(fiveText) \(fiveReset), 7d \(weekText) \(weekReset)")

        switch MenuBarDisplayMode.current {
        case .bars:
            statusItem.length = QuotaStatusImage.size.width + 8
            button.title = ""
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleNone
            button.image = QuotaStatusImage.make(
                fiveHour: fiveHour?.remainingPercent,
                weekly: weekly?.remainingPercent,
                fiveHourReset: fiveHour?.resetDate,
                weeklyReset: weekly?.resetDate
            )
            button.needsDisplay = true
        case .numbers:
            statusItem.length = NSStatusItem.variableLength
            button.image = nil
            button.imagePosition = .noImage
            button.title = "5h \(fiveText) / 7d \(weekText)"
        }
    }

    private func updateWindow(_ snapshot: QuotaSnapshot) {
        windowOverviewView.isHidden = false
        windowErrorLabel.isHidden = true
        let plan = AppStrings.planName(snapshot.event.planType)
        windowOverviewView.update(
            snapshot: snapshot,
            plan: plan,
            timeFormatter: timeFormatter,
            shortTimeFormatter: shortTimeFormatter
        )
        controlWindow?.setContentSize(NSSize(width: 456, height: snapshot.event.fiveHourQuota == nil ? 316 : 396))
    }

    private func updateWindow(error: String) {
        windowOverviewView.isHidden = true
        windowErrorLabel.isHidden = false
        windowErrorLabel.stringValue = error
    }

    @objc private func selectSystemLanguage(_ sender: Any?) {
        setLanguageMode(.system)
    }

    @objc private func selectEnglishLanguage(_ sender: Any?) {
        setLanguageMode(.english)
    }

    @objc private func selectChineseLanguage(_ sender: Any?) {
        setLanguageMode(.chinese)
    }

    @objc private func selectJapaneseLanguage(_ sender: Any?) {
        setLanguageMode(.japanese)
    }

    private func setLanguageMode(_ mode: LanguageMode) {
        LanguageMode.current = mode
        updateLanguageMenuState()
        updateStaticMenuText()
        updateRefreshModeMenuState()

        if let snapshot = latestSnapshot {
            update(snapshot)
        } else {
            refresh(nil)
        }
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}

if CommandLine.arguments.contains("--diagnostics") {
    print(QuotaReader().diagnostics())
} else if CommandLine.arguments.contains("--print") {
    do {
        let snapshot = try QuotaReader().readLatest()
        if let weekly = snapshot.event.rateLimits.weekly {
            print("weekly_remaining=\(weekly.remainingPercent)")
            print("weekly_reset=\(weekly.resetDate)")
        } else {
            print("weekly_remaining=--")
            print("weekly_reset=--")
        }
        print("plan_type=\(snapshot.event.planType ?? "")")
        print("five_hour_visible=\(snapshot.event.fiveHourQuota != nil)")
        if let fiveHour = snapshot.event.fiveHourQuota {
            print("five_hour_remaining=\(fiveHour.remainingPercent)")
            print("five_hour_reset=\(fiveHour.resetDate)")
        }
        print("source=\(snapshot.source.title)")
        print("historical=\(snapshot.isHistorical)")
        print("data_updated=\(ISO8601DateFormatter().string(from: snapshot.logDate))")
        let fiveHour = QuotaStatusImage.currentWindow(snapshot.event.fiveHourQuota, snapshot: snapshot)
        let weekly = QuotaStatusImage.currentWindow(snapshot.event.rateLimits.weekly, snapshot: snapshot)
        print("menu_5h=\(fiveHour.map { "\($0.remainingPercent)%" } ?? "--") \(QuotaStatusImage.resetText(for: fiveHour?.resetDate, weekly: false))")
        print("menu_7d=\(weekly.map { "\($0.remainingPercent)%" } ?? "--") \(QuotaStatusImage.resetText(for: weekly?.resetDate, weekly: true))")
    } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        exit(1)
    }
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
