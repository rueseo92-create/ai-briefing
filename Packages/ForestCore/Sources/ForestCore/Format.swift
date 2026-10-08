import Foundation

public enum Format {
    /// 54000 → "54,000원"
    public static func won(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        let number = formatter.string(from: NSNumber(value: value)) ?? String(value)
        return "\(number)원"
    }

    /// 지난 시간을 일수와 "04:23:11"로 나눈다.
    public static func elapsed(_ interval: TimeInterval) -> (days: Int, clock: String) {
        let total = max(0, Int(interval))
        let days = total / 86_400
        let rest = total % 86_400
        let clock = String(format: "%02d:%02d:%02d", rest / 3600, (rest % 3600) / 60, rest % 60)
        return (days, clock)
    }

    /// 남은 시간 → "09:59"
    public static func countdown(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
