import Foundation

struct Trophy: Identifiable {
    enum Metric { case dailySteps, totalSteps, goalDays }
    let id: String
    let name: String
    let badge: String
    let target: Int
    let metric: Metric
    var requirement: String {
        switch metric {
        case .dailySteps: return "Faire \(target.stepsText) pas en une journée"
        case .totalSteps: return "Cumuler \(target.stepsText) pas enregistrés"
        case .goalDays: return "Atteindre son minimum quotidien \(target) jour\(target > 1 ? "s" : "")"
        }
    }
    static let all: [Trophy] = {
        let daily: [(Int, String, String)] = [(100,"Premiers pas","🌱"),(500,"En route","👟"),(1000,"Le premier millier","🍃"),
            (2000,"Petit tour","🌼"),(3000,"Au grand air","🌳"),(5000,"Bon rythme","🔥"),(7500,"La balade s’allonge","🧭"),
            (10000,"Les dix mille","🏅"),(12500,"Marche prolongée","🦊"),(15000,"Grande randonnée","⛰️"),(20000,"Vingt mille pas","🦅"),(30000,"Longue distance","🏔️")]
        let total: [(Int, String, String)] = [(25000,"Pas après pas","🥉"),(50000,"Cinquante mille","🥈"),(100000,"Cent mille","🥇"),(250000,"Quart de million","💎")]
        let days: [(Int, String, String)] = [(1,"Minimum atteint","🎯"),(3,"Trois jours validés","⭐"),(7,"Sept jours validés","🌟"),(30,"Trente jours validés","👑")]
        return daily.map { Trophy(id: "day-\($0.0)", name: $0.1, badge: $0.2, target: $0.0, metric: .dailySteps) }
            + total.map { Trophy(id: "total-\($0.0)", name: $0.1, badge: $0.2, target: $0.0, metric: .totalSteps) }
            + days.map { Trophy(id: "goals-\($0.0)", name: $0.1, badge: $0.2, target: $0.0, metric: .goalDays) }
    }()
    static func find(_ id: String?) -> Trophy? { all.first { $0.id == id } }
    static func dayIDs(steps: Int) -> [String] { all.filter { $0.metric == .dailySteps && steps >= $0.target }.map(\.id) }
}

final class TrophyStore {
    struct Day: Codable { var steps: Int; var goal: Int; var goalReached: Bool? }
    private struct State: Codable {
        var days: [String: Day] = [:]
        var earned: Set<String> = []
        var equipped: String?
    }
    static let shared = TrophyStore()
    private let defaults: UserDefaults
    private var state: State
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        state = defaults.data(forKey: "lazzy.trophies").flatMap { try? JSONDecoder().decode(State.self, from: $0) } ?? State()
    }
    var earned: [Trophy] { Trophy.all.filter { state.earned.contains($0.id) } }
    var equipped: Trophy? { state.earned.contains(state.equipped ?? "") ? Trophy.find(state.equipped) : nil }
    func value(for metric: Trophy.Metric) -> Int {
        switch metric {
        case .dailySteps: return state.days.values.map(\.steps).max() ?? 0
        case .totalSteps: return state.days.values.reduce(0) { result, day in
            let sum = result.addingReportingOverflow(day.steps); return sum.overflow ? Int.max : sum.partialValue
        }
        case .goalDays: return state.days.values.filter { $0.goalReached ?? ($0.steps >= $0.goal) }.count
        }
    }
    func record(steps: Int, goal: Int, date: Date = Date(), calendar: Calendar = .current) {
        guard steps >= 0, goal > 0 else { return }
        let c = calendar.dateComponents([.era, .year, .month, .day], from: date)
        let key = "\(c.era ?? 1)-\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
        let old = state.earned
        let reached = (state.days[key]?.goalReached == true) || steps >= goal
        state.days[key] = Day(steps: steps, goal: goal, goalReached: reached)
        for trophy in Trophy.all where value(for: trophy.metric) >= trophy.target { state.earned.insert(trophy.id) }
        save()
        if old != state.earned { NotificationCenter.default.post(name: .lazzyProfileChanged, object: nil) }
    }
    @discardableResult
    func equip(_ id: String?) -> Bool {
        if let id { guard state.earned.contains(id), Trophy.find(id) != nil else { return false } }
        state.equipped = id
        save()
        NotificationCenter.default.post(name: .lazzyProfileChanged, object: nil)
        return true
    }
    private func save() {
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: "lazzy.trophies") }
    }
}
