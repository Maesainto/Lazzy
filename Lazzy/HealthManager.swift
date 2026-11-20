import Foundation
@preconcurrency import HealthKit

final class HealthManager {
    struct DailyActivity {
        let steps: Double?
        let distanceKilometers: Double?
        let activeKilocalories: Double?
    }

    private let healthStore = HKHealthStore()

    var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return HKHealthStore.isHealthDataAvailable()
        #endif
    }

    func requestAuthorization() async throws {
        let identifiers: [HKQuantityTypeIdentifier] = [.stepCount, .distanceWalkingRunning, .activeEnergyBurned]
        let readTypes: Set<HKObjectType> = Set(identifiers.compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchDailyActivity(date: Date, calendar: Calendar) async -> DailyActivity {
        let start = calendar.startOfDay(for: date)
        let end = calendar.dateInterval(of: .day, for: date)?.end ?? date

        async let steps = try? dailyTotal(for: .stepCount, unit: .count(), start: start, end: end) ?? 0
        async let distance = try? dailyTotal(for: .distanceWalkingRunning, unit: .meterUnit(with: .kilo), start: start, end: end)
        async let energy = try? dailyTotal(for: .activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        return await DailyActivity(steps: steps, distanceKilometers: distance, activeKilocalories: energy)
    }

    private func dailyTotal(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        // Les échantillons qui chevauchent minuit restent inclus dans la collection.
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: DateComponents(day: 1)
        )
        do {
            let statistics = try await query.result(for: healthStore)
            let total = statistics.statistics(for: start)?.sumQuantity()?.doubleValue(for: unit)
            guard let total, total.isFinite, total >= 0 else { return nil }
            return total
        } catch let error as HKError where error.code == .errorNoData {
            return nil
        }
    }
}
