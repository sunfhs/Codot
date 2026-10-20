import AppKit
let savedLanguage = LanguageMode.current
let savedOverride = ProcessInfo.processInfo.environment["CODEX_VISUAL_LANGUAGE"]
unsetenv("CODEX_VISUAL_LANGUAGE")
precondition(LanguageMode.fromLocale("ja-JP") == .japanese)
precondition(LanguageMode.fromLocale("zh-Hans") == .chinese)
precondition(LanguageMode.fromLocale("en-US") == .english)
for (mode, refresh) in [(LanguageMode.chinese, "立即刷新"), (.japanese, "今すぐ更新"), (.english, "Refresh Now")] {
    LanguageMode.current = mode
    precondition(LanguageMode.current == mode, "The language selection must persist")
    precondition(AppStrings.refreshNow == refresh, "The menu must use the selected language")
    precondition(AppStrings.dateLocale.language.languageCode?.identifier == (mode == .japanese ? "ja" : mode == .chinese ? "zh" : "en"), "Date formatting must follow the selected language")
}
LanguageMode.current = savedLanguage
if let savedOverride { setenv("CODEX_VISUAL_LANGUAGE", savedOverride, 1) }
func testTwoRowsFitStandardMenuBarHeight() {
    let image = QuotaStatusImage.make(
        fiveHour: 55, weekly: 93,
        fiveHourReset: .distantFuture, weeklyReset: .distantFuture
    )
    precondition(image.size.height == 22, "Two rows must fit 22 points without scaling")
}

func testReturnedFiveHourWindowIsVisibleForAnyPlan() {
    let window = QuotaWindow(usedPercent: 45, windowMinutes: 300,
                             resetAfterSeconds: nil, resetAt: Date.distantFuture.timeIntervalSince1970)
    let event = RateLimitEvent(type: "codex.rate_limits", planType: "pro",
        rateLimits: RateLimits(limitID: "codex", allowed: true, limitReached: false,
                               primary: window, secondary: nil))
    precondition(event.fiveHourQuota?.remainingPercent == 55, "Do not hide returned windows by plan")
}
testTwoRowsFitStandardMenuBarHeight()
testReturnedFiveHourWindowIsVisibleForAnyPlan()
let shortOnly: [String: Any] = ["result": ["rateLimitsByLimitId": ["codex": [
    "primary": ["usedPercent": 45, "windowDurationMins": 300, "resetsAt": 4102444800],
    "secondary": NSNull()
]]]]
precondition(CodexAppServerExchange.decodeSnapshot(from: shortOnly)?.event.rateLimits.fiveHour?.remainingPercent == 55,
             "A missing weekly window must not discard the current account reading")
let empty: [String: Any] = ["result": ["rateLimitsByLimitId": ["codex": [
    "primary": NSNull(), "secondary": NSNull()
]]]]
precondition(CodexAppServerExchange.decodeSnapshot(from: empty) != nil,
             "Missing windows must not fall back to another session")
let expired = QuotaWindow(usedPercent: 45, windowMinutes: 300, resetAfterSeconds: nil, resetAt: 1)
precondition(expired.remainingPercent == 55, "An old reset time must never fabricate 100 percent")
let snapshot = CodexAppServerExchange.decodeSnapshot(from: shortOnly)!
precondition(QuotaStatusImage.currentWindow(snapshot.event.fiveHourQuota, snapshot: snapshot)?.remainingPercent == 55)
precondition(QuotaStatusImage.currentWindow(snapshot.event.fiveHourQuota, snapshot: snapshot.historicalCopy) == nil)
precondition(QuotaStatusImage.currentWindow(expired, snapshot: snapshot) == nil)
precondition(QuotaStatusImage.currentWindow(nil, snapshot: snapshot) == nil)
precondition(QuotaStatusImage.resetText(for: nil, weekly: false) == "--")
precondition(QuotaStatusImage.resetText(for: expired.resetDate, weekly: true) == "--")
let originalZone = ProcessInfo.processInfo.environment["TZ"]
setenv("TZ", "Asia/Tokyo", 1)
NSTimeZone.resetSystemTimeZone()
let reset = Date(timeIntervalSince1970: 4102444800)
precondition(QuotaStatusImage.resetText(for: reset, weekly: false) == "09:00")
precondition(QuotaStatusImage.resetText(for: reset, weekly: true) == "01/01")
setenv("TZ", "America/Los_Angeles", 1)
NSTimeZone.resetSystemTimeZone()
precondition(QuotaStatusImage.resetText(for: reset, weekly: false) == "16:00")
precondition(QuotaStatusImage.resetText(for: reset, weekly: true) == "12/31")
if let originalZone { setenv("TZ", originalZone, 1) } else { unsetenv("TZ") }
NSTimeZone.resetSystemTimeZone()

let image = QuotaStatusImage.make(fiveHour: 55, weekly: 93, fiveHourReset: reset, weeklyReset: reset)
var labelBrightness: [CGFloat] = []
for name in [NSAppearance.Name.aqua, .darkAqua] {
    NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 332, pixelsHigh: 44,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current!.cgContext.scaleBy(x: 2, y: 2)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        var brightness: CGFloat = 0
        var count: CGFloat = 0
        for x in 0..<40 {
            for y in 0..<bitmap.pixelsHigh {
                let color = bitmap.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
                if color.alphaComponent > 0.5 {
                    brightness += color.redComponent
                    count += 1
                }
            }
        }
        precondition(count > 0, "Both row labels must be visible")
        labelBrightness.append(brightness / count)
        try! bitmap.representation(using: .png, properties: [:])!
            .write(to: URL(fileURLWithPath: ".build/menubar-tests/\(name.rawValue).png"))
        let missing = QuotaStatusImage.make(fiveHour: nil, weekly: nil, fiveHourReset: nil, weeklyReset: nil)
        precondition(missing.size == image.size)
    }
}
precondition(labelBrightness[1] > labelBrightness[0] + 0.5, "The same image must adapt its text to light and dark appearances")
print("Menu bar tests passed.")
