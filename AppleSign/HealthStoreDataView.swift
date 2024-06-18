//
//  HealthStoreDataView.swift
//  AppleSign
//
//  Created by APPLE on 06/06/24.
//

import SwiftUI
import HealthKit
import Charts

struct HealthData: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let distance: Double
    let heartRate: Double
}

struct HealthStoreDataView: View {
    @State private var healthData = [HealthData]()
    let healthStore = HKHealthStore()
    @State private var isLoading = false
    @State private var isDataDisplayed = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Fetching Health Data...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5, anchor: .center)
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if healthData.isEmpty {
                Text("No Health Data Available")
                    .padding()
            } else {
                ScrollView {
                    VStack {
                        summaryCards
                            .padding()
                            .opacity(isDataDisplayed ? 1 : 0)
                            .animation(.easeInOut(duration: 1.0), value: isDataDisplayed)
                        stepsChart
                            .opacity(isDataDisplayed ? 1 : 0)
                            .animation(.easeInOut(duration: 1.0), value: isDataDisplayed)
                        distanceChart
                            .opacity(isDataDisplayed ? 1 : 0)
                            .animation(.easeInOut(duration: 1.2), value: isDataDisplayed)
                        heartRateChart
                            .opacity(isDataDisplayed ? 1 : 0)
                            .animation(.easeInOut(duration: 1.4), value: isDataDisplayed)
                        healthDataTable
                            .opacity(isDataDisplayed ? 1 : 0)
                            .animation(.easeInOut(duration: 1.6), value: isDataDisplayed)
                    }
                }
            }
            Button("Fetch Health Data") {
                withAnimation {
                    isLoading = true
                    isDataDisplayed = false
                    errorMessage = nil
                }
                fetchHealthData()
            }
            .padding()
        }
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 16) {
            summaryCard(title: "Total Steps", value: totalSteps, color: .blue)
            summaryCard(title: "Total Distance", value: String(format: "%.2f m", totalDistance), color: .green)
            summaryCard(title: "Average Heart Rate", value: String(format: "%.0f bpm", averageHeartRate), color: .red)
        }
    }

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            Text(value)
                .font(.largeTitle)
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    // MARK: - Calculations
    private var totalSteps: String {
        let total = healthData.reduce(0) { $0 + $1.steps }
        return "\(total)"
    }

    private var totalDistance: Double {
        healthData.reduce(0) { $0 + $1.distance }
    }

    private var averageHeartRate: Double {
        let total = healthData.reduce(0) { $0 + $1.heartRate }
        return total / Double(healthData.count)
    }

    // MARK: - Step Chart
    private var stepsChart: some View {
        VStack {
            Text("Steps Count").font(.headline)
            Chart(healthData) { data in
                BarMark(
                    x: .value("Date", data.date),
                    y: .value("Steps", data.steps)
                )
                .foregroundStyle(Color.blue)
            }
            .frame(height: 150)
        }
        .transition(.slide)
    }

    // MARK: - Distance Chart
    private var distanceChart: some View {
        VStack {
            Text("Distance").font(.headline)
            Chart(healthData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Distance", data.distance)
                )
                .foregroundStyle(Color.green)
            }
            .frame(height: 150)
        }
        .transition(.slide)
    }

    // MARK: - Heart Rate Chart
    private var heartRateChart: some View {
        VStack {
            Text("Heart Rate").font(.headline)
            Chart(healthData) { data in
                PointMark(
                    x: .value("Date", data.date),
                    y: .value("Heart Rate", data.heartRate)
                )
                .foregroundStyle(Color.red)
            }
            .frame(height: 150)
        }
        .transition(.slide)
    }

    // MARK: - Health Data Table
    private var healthDataTable: some View {
        VStack {
            Text("Health Data").font(.headline)
            List(healthData) { data in
                HStack {
                    Text(data.date, style: .date)
                    Spacer()
                    Text("Steps: \(data.steps)")
                    Spacer()
                    Text("Distance: \(String(format: "%.2f", data.distance)) m")
                    Spacer()
                    Text("Heart Rate: \(String(format: "%.0f", data.heartRate)) bpm")
                }
            }
        }
        .transition(.slide)
    }

    // MARK: - Fetch Health Data
    private func fetchHealthData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available")
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if success {
                queryHealthData()
            } else {
                print("Health data authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                withAnimation {
                    isLoading = false
                    errorMessage = error?.localizedDescription ?? "Authorization failed"
                }
            }
        }
    }

    private func queryHealthData() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                                                quantitySamplePredicate: nil,
                                                options: .cumulativeSum,
                                                anchorDate: startOfDay,
                                                intervalComponents: interval)

        query.initialResultsHandler = { query, results, error in
            if let statsCollection = results {
                statsCollection.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                    if let quantity = statistics.sumQuantity() {
                        let steps = Int(quantity.doubleValue(for: .count()))
                        self.queryOtherData(steps: steps, startDate: statistics.startDate, endDate: statistics.endDate)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error?.localizedDescription ?? "Failed to fetch step data"
                }
            }
        }

        healthStore.execute(query)
    }

    private func queryOtherData(steps: Int, startDate: Date, endDate: Date) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRatePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let heartRateQuery = HKStatisticsQuery(quantityType: heartRateType,
                                               quantitySamplePredicate: heartRatePredicate,
                                               options: .discreteAverage) { query, result, error in
            var heartRate: Double = 0
            if let result = result {
                heartRate = result.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
            }

            let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
            let distanceQuery = HKStatisticsQuery(quantityType: distanceType,
                                                  quantitySamplePredicate: heartRatePredicate,
                                                  options: .cumulativeSum) { query, result, error in
                var distance: Double = 0
                if let result = result {
                    distance = result.sumQuantity()?.doubleValue(for: HKUnit.meter()) ?? 0
                }

                DispatchQueue.main.async {
                    let data = HealthData(date: startDate, steps: steps, distance: distance, heartRate: heartRate)
                    self.healthData.append(data)
                    withAnimation {
                        self.isLoading = false
                        self.isDataDisplayed = true
                    }
                }
            }
            self.healthStore.execute(distanceQuery)
        }
        self.healthStore.execute(heartRateQuery)
    }
}

struct HealthStoreDataView_Previews: PreviewProvider {
    static var previews: some View {
        HealthStoreDataView()
    }
}
