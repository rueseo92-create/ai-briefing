import Foundation

/// 제휴처가 채워 보내는 제안 파일. 운영자는 offer-check로 검사한 뒤 CloudKit 공개 DB에 올린다.
/// 앱은 이 파일을 통째로 받아 검사를 통과한 제안만 실험으로 바꾼다.
public struct OfferFile: Codable, Equatable, Sendable {
    public var partner: Partner
    public var offers: [OfferEntry]

    public struct Partner: Codable, Equatable, Sendable {
        public var name: String
        public var contact: String?
    }

    public struct OfferPlace: Codable, Equatable, Sendable {
        public var name: String
        public var latitude: Double
        public var longitude: Double
        public var address: String?
    }

    public struct KitEntry: Codable, Equatable, Sendable {
        public var name: String
        public var contents: [String]
        public var price: Int
        public var leadDays: Int
        public var url: String?
    }

    public struct OfferEntry: Codable, Equatable, Sendable {
        public var id: String
        public var title: String
        public var detail: String
        /// rest, movement, food, breath, nature, senses, making, connection
        public var zone: String
        /// quiet, novel, solo, together, making, moving, outdoors, slow, sensory, learning, pretty, refreshing
        public var tags: [String]
        public var minutes: Int
        /// 체험 장소. 키트처럼 집에서 하면 비운다.
        public var place: OfferPlace?
        /// 원래 가격(원).
        public var price: Int
        public var benefit: String?
        public var priceAfterBenefit: Int?
        public var code: String?
        public var url: String?
        /// "2026-12-31"
        public var endsAt: String?
        public var needsCompany: Bool?
        public var seasons: [String]?
        public var kit: KitEntry?
    }

    public init(partner: Partner, offers: [OfferEntry]) {
        self.partner = partner
        self.offers = offers
    }
}

public struct OfferIssue: Equatable, Sendable, CustomStringConvertible {
    public enum Level: String, Sendable {
        case error = "오류"
        case warning = "주의"
    }

    public var offerID: String?
    public var level: Level
    public var message: String

    public var description: String {
        "[\(level.rawValue)] \(offerID.map { "\($0): " } ?? "")\(message)"
    }
}

public enum OfferValidator {
    /// 건강 효과를 약속하는 말. 웰니스 앱이지만 치료·예방을 말하지 않는다.
    public static let forbiddenWords = ["치료", "완치", "예방", "효능", "질병", "다이어트 효과", "면역력", "디톡스"]
    static let koreaLatitude = 33.0...38.7
    static let koreaLongitude = 124.5...131.9

    public static func validate(_ file: OfferFile, now: Date, calendar: Calendar = .current) -> [OfferIssue] {
        var issues: [OfferIssue] = []
        if file.partner.name.trimmingCharacters(in: .whitespaces).isEmpty {
            issues.append(OfferIssue(offerID: nil, level: .error, message: "partner.name이 비어 있어요"))
        }
        var seen = Set<String>()
        for offer in file.offers {
            func error(_ message: String) { issues.append(OfferIssue(offerID: offer.id, level: .error, message: message)) }
            func warn(_ message: String) { issues.append(OfferIssue(offerID: offer.id, level: .warning, message: message)) }

            if offer.id.isEmpty || !offer.id.allSatisfy({ $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") }) {
                error("id는 영어 소문자, 숫자, -만 쓸 수 있어요")
            }
            if !seen.insert(offer.id).inserted { error("id가 겹쳐요") }
            if offer.title.isEmpty || offer.title.count > 40 { error("제목은 1~40자여야 해요") }
            if offer.detail.count > 120 { error("설명은 120자 이내여야 해요") }
            if Domain(rawValue: offer.zone) == nil { error("zone '\(offer.zone)': 없는 구역이에요") }
            let tags = offer.tags.compactMap(Tag.init(rawValue:))
            if tags.count != offer.tags.count { error("모르는 tag가 있어요: \(offer.tags.filter { Tag(rawValue: $0) == nil }.joined(separator: ", "))") }
            if !(1...3).contains(offer.tags.count) { error("tag는 1~3개여야 해요") }
            if !(5...480).contains(offer.minutes) { error("시간은 5~480분이어야 해요") }
            if offer.price < 0 { error("가격이 음수예요") }
            for word in forbiddenWords where (offer.title + offer.detail + (offer.benefit ?? "")).contains(word) {
                error("건강 효과를 약속하는 말('\(word)')은 쓸 수 없어요")
            }
            if let seasons = offer.seasons, seasons.contains(where: { Season(rawValue: $0) == nil }) {
                error("seasons는 spring, summer, autumn, winter만 쓸 수 있어요")
            }

            let isSponsored = offer.benefit != nil
            if !isSponsored && offer.kit == nil { error("혜택(benefit)이나 키트(kit) 중 하나는 있어야 해요") }
            if isSponsored {
                guard let after = offer.priceAfterBenefit else { error("혜택이 있으면 priceAfterBenefit이 필요해요"); continue }
                if after > offer.price { error("혜택 뒤 가격이 원래 가격보다 비싸요") }
                if after < 0 { error("혜택 뒤 가격이 음수예요") }
                if let code = offer.code, !(4...12).contains(code.count) || !code.allSatisfy({ $0.isASCII && ($0.isUppercase || $0.isNumber) }) {
                    error("혜택 코드는 영어 대문자와 숫자 4~12자여야 해요")
                }
                if offer.code == nil { warn("혜택 코드가 없으면 사용 횟수를 셀 수 없어요") }
                if offer.place == nil { error("체험 제안에는 장소(place)가 필요해요") }
            }
            if let place = offer.place {
                if !koreaLatitude.contains(place.latitude) || !koreaLongitude.contains(place.longitude) {
                    error("장소 좌표가 한국 밖이에요(위도·경도가 바뀌었는지 확인해 주세요)")
                }
            }
            if let kit = offer.kit {
                if kit.price <= 0 { error("키트 가격이 필요해요") }
                if !(1...7).contains(kit.leadDays) { error("키트 배송일(leadDays)은 1~7일이어야 해요") }
                if kit.contents.isEmpty { error("키트 구성(contents)이 비어 있어요") }
            }
            if let text = offer.url, URL(string: text)?.scheme?.hasPrefix("http") != true { error("url은 http로 시작해야 해요") }
            if let ends = offer.endsAt {
                if let date = endDate(ends, calendar: calendar) {
                    if date <= now { error("이미 끝난 제안이에요(endsAt)") }
                    else if date.timeIntervalSince(now) < 7 * 86_400 { warn("일주일 안에 끝나요") }
                } else {
                    error("endsAt은 2026-12-31 모양이어야 해요")
                }
            }
        }
        return issues
    }

    /// 오류가 없는 제안만 실험으로 바꾼다.
    public static func experiments(from file: OfferFile, now: Date, calendar: Calendar = .current) -> [Experiment] {
        let broken = Set(validate(file, now: now, calendar: calendar).filter { $0.level == .error }.compactMap(\.offerID))
        return file.offers.filter { !broken.contains($0.id) }.compactMap { offer in
            guard let domain = Domain(rawValue: offer.zone) else { return nil }
            let place: Place = offer.place.map {
                .venue(Venue(name: $0.name, coordinate: Coordinate(latitude: $0.latitude, longitude: $0.longitude), address: $0.address))
            } ?? .home
            let sponsor = offer.benefit.map {
                Sponsorship(
                    brand: file.partner.name, benefit: $0, priceAfterBenefit: offer.priceAfterBenefit ?? offer.price,
                    code: offer.code, url: offer.url.flatMap(URL.init(string:)),
                    endsAt: offer.endsAt.flatMap { endDate($0, calendar: calendar) }
                )
            }
            let kit = offer.kit.map {
                Kit(name: $0.name, contents: $0.contents, price: $0.price, leadDays: $0.leadDays, url: $0.url.flatMap(URL.init(string:)))
            }
            return Experiment(
                id: (sponsor != nil ? "ad-" : "kit-") + offer.id,
                title: offer.title, detail: offer.detail, domain: domain,
                tags: offer.tags.compactMap(Tag.init(rawValue:)), minutes: offer.minutes, place: place,
                cost: offer.price, needsCompany: offer.needsCompany ?? false,
                sponsor: sponsor, kit: kit, seasons: offer.seasons?.compactMap(Season.init(rawValue:))
            )
        }
    }

    /// "2026-12-31"이면 그날이 끝나는 순간(다음 날 0시).
    static func endDate(_ text: String, calendar: Calendar) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, let day = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else { return nil }
        return calendar.date(byAdding: .day, value: 1, to: day)
    }
}

/// 제휴처가 보내는 혜택 코드 사용 기록(CSV: "2026-10-14,TEA40")을 코드·주별로 센다. 성과형 정산에 쓴다.
public enum RedemptionReport {
    public struct Row: Equatable, Sendable {
        public var code: String
        public var week: String
        public var count: Int
    }

    public static func summarize(csv: String, calendar: Calendar = .current) -> (rows: [Row], skipped: Int) {
        var counts: [String: [String: Int]] = [:]
        var skipped = 0
        for line in csv.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count >= 2, let date = OfferValidator.endDate(fields[0], calendar: calendar)?.addingTimeInterval(-1) else {
                if !line.lowercased().hasPrefix("date") { skipped += 1 }
                continue
            }
            counts[fields[1].uppercased(), default: [:]][Week.key(date, calendar: calendar), default: 0] += 1
        }
        let rows = counts.flatMap { code, weeks in weeks.map { Row(code: code, week: $0.key, count: $0.value) } }
            .sorted { ($0.code, $0.week) < ($1.code, $1.week) }
        return (rows, skipped)
    }
}
