import Foundation
import TasteCore

/// 제휴처 도구.
///   offer-check validate offers.json      제안 파일 검사
///   offer-check redemptions codes.csv     혜택 코드 사용 횟수를 코드·주별로 정리
let arguments = CommandLine.arguments.dropFirst()

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

guard arguments.count == 2, let command = arguments.first, let path = arguments.last else {
    fail("사용법: offer-check validate offers.json | offer-check redemptions codes.csv")
}
guard let data = FileManager.default.contents(atPath: path) else { fail("파일을 열 수 없어요: \(path)") }

switch command {
case "validate":
    let file: OfferFile
    do {
        file = try JSONDecoder().decode(OfferFile.self, from: data)
    } catch {
        fail("JSON 모양이 템플릿과 달라요: \(error)")
    }
    let issues = OfferValidator.validate(file, now: Date())
    issues.forEach { print($0) }
    let usable = OfferValidator.experiments(from: file, now: Date())
    print("\(file.partner.name): 제안 \(file.offers.count)개 중 \(usable.count)개를 앱에 올릴 수 있어요.")
    if issues.contains(where: { $0.level == .error }) { exit(1) }
case "redemptions":
    let summary = RedemptionReport.summarize(csv: String(decoding: data, as: UTF8.self))
    print("code,week,count")
    summary.rows.forEach { print("\($0.code),\($0.week),\($0.count)") }
    let total = summary.rows.reduce(0) { $0 + $1.count }
    print("합계 \(total)건" + (summary.skipped > 0 ? ", 읽지 못한 줄 \(summary.skipped)개" : ""))
default:
    fail("모르는 명령이에요: \(command)")
}
