import Foundation
@preconcurrency import HealthKit

final class HealthManager {
    private let healthStore = HKHealthStore()
    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return HKHealthStore.isHealthDataAvailable()
        #endif
    }
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable, let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(false); return
        }
        // HealthKit ne révèle pas si l'utilisateur a refusé la lecture.
        healthStore.requestAuthorization(toShare: [], read: [type]) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
    func fetchTodaySteps(completion: @escaping (Double) -> Void) {
        fetchTodayStepsResult { result in completion((try? result.get()) ?? 0) }
    }
    func fetchTodayStepsResult(completion: @escaping (Result<Double, Error>) -> Void) {
        guard isAvailable, let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(HealthError.unavailable)); return
        }
        let dayStart = Calendar.current.startOfDay(for: Date())
        let query = Self.dailyStepsQuery(type: type, date: dayStart)
        let store = healthStore
        query.initialResultsHandler = { query, result, error in
            // La collection répartit les échantillons dans les journées, y compris
            // ceux qui chevauchent minuit. Ne pas additionner les sources à la main.
            let steps = result?.statistics(for: dayStart)?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            store.stop(query)
            DispatchQueue.main.async {
                if let error { completion(.failure(error)) } else { completion(.success(steps)) }
            }
        }
        healthStore.execute(query)
    }
    static func dailyStepsQuery(type: HKQuantityType, date: Date, calendar: Calendar = .current) -> HKStatisticsCollectionQuery {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        // Inclure les échantillons qui chevauchent la journée. Un début strict
        // à minuit écarterait entièrement ceux commencés la veille.
        let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd, options: [])
        return HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate,
                                           options: .cumulativeSum, anchorDate: dayStart,
                                           intervalComponents: DateComponents(day: 1))
    }
    func fetchStepDiagnostics(completion: @escaping (String) -> Void) {
        guard isAvailable, let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion("Santé indisponible sur cet appareil."); return
        }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let store = healthStore
        // Lecture de référence sans filtre d’échantillons : seule la tranche
        // journalière de la collection est utilisée. Ne pas modifier le compteur
        // avant d’avoir identifié la cause d’un éventuel écart.
        let reference = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil,
                                                     options: .cumulativeSum, anchorDate: start,
                                                     intervalComponents: DateComponents(day: 1))
        reference.initialResultsHandler = { query, collection, error in
            store.stop(query)
            let total = collection?.statistics(for: start)?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            let referenceText = error.map { "Erreur : \($0.localizedDescription)" } ?? "\(Int(total)) pas"
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
            let sources = HKSourceQuery(sampleType: type, samplePredicate: predicate) { _, sources, sourceError in
                let names = sources?.map(\.name).sorted().joined(separator: ", ") ?? ""
                DispatchQueue.main.async {
                    let day = start.formatted(.dateTime.day().month().year().locale(Locale(identifier: "fr_FR")))
                    let sourceText = sourceError.map { "Erreur : \($0.localizedDescription)" }
                        ?? (names.isEmpty ? "Aucune source accessible" : names)
                    completion("Journée : \(day)\nFuseau : \(calendar.timeZone.identifier)\n\nLecture de référence HealthKit : \(referenceText)\n\nSources accessibles : \(sourceText)\n\nCompare ces sources avec celles de Santé > Pas > Sources de données et accès.")
                }
            }
            store.execute(sources)
        }
        store.execute(reference)
    }
    enum HealthError: Error { case unavailable }
}
