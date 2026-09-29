//
//  HealthManager.swift
//  Lazzy
//
//  Created by etudiant on 29/09/2026.
//

import Foundation
import HealthKit
// fait avec l'ia, pour récuperer le nombre de pas depuis l'appli sante du telephone
class HealthManager{
    let healthStore = HKHealthStore()
        
        // 1. Demander l'autorisation à l'utilisateur
        func requestAuthorization(completion: @escaping (Bool) -> Void) {
            guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
                completion(false)
                return
            }
            
            healthStore.requestAuthorization(toShare: [], read: [stepCountType]) { success, error in
                completion(success)
            }
        }
        
        // 2. Récupérer les pas depuis minuit
        func fetchTodaySteps(completion: @escaping (Double) -> Void) {
            guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
            
            let now = Date()
            let startOfDay = Calendar.current.startOfDay(for: now)
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(0)
                    return
                }
                completion(sum.doubleValue(for: HKUnit.count()))
            }
            healthStore.execute(query)
        }
}
