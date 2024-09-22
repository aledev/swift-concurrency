//
//  TaskResultView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 21/9/24.
//

import SwiftUI

struct TaskResultView: View {
    // MARK: - Properties
    @State private var selection: ExampleOption = .select
    @State private var jokeText = ""

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Picker("Select a test example", selection: $selection) {
                        ForEach(ExampleOption.allCases, id: \.hashValue) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.menu)

                    Divider()

                    if !jokeText.isEmpty {
                        Text(jokeText)
                    }
                }
            }
        }
        .navigationTitle("Task: Part II")
        .onChange(of: selection) { newState in
            Task {
                await testExample(with: newState)
            }
        }
    }
}

// MARK: - Private Methods
private extension TaskResultView {
    func testExample(with option: ExampleOption) async {
        switch option {
        case .select:
            jokeText = ""
        case .result:
            await fetchQuotes()
        case .taskWithPriority:
            await fetchQuotesWithPriority()
        case .fetchJoke:
            fetchJoke()
        case .averageTemperature:
            await getAverageTemperature()
        case .averageTemperatureWithCancellation:
            await getAverageTemperatureWithCancellation()
        case .sleep:
            await sleep()
        case .suspendTask:
            let factors = await factors(for: 1_000_000)
            debugPrint("Found \(factors.count) factors for 1.000.000.")
        }
    }

    func fetchQuotes() async {
        let downloadTask = Task { () -> String in
            let url = URL(string: Endpoints.quotes.rawValue)!
            let data: Data

            do {
                (data, _) = try await URLSession.shared.data(from: url)
            } catch {
                throw LoadError.fetchFailed
            }

            if let string = String(data: data, encoding: .utf8) {
                return string
            } else {
                throw LoadError.decodeFailed
            }
        }

        let result = await downloadTask.result

        do {
            let string = try result.get()
            debugPrint(string)
        } catch LoadError.fetchFailed {
            debugPrint("Unable to fetch the quotes.")
        } catch LoadError.decodeFailed {
            debugPrint("Unable to convert quotes to text.")
        } catch {
            debugPrint("Unknown error.")
        }
    }

    func fetchQuotesWithPriority() async {
        let downloadTask = Task(priority: .high) { () -> String in
            let url = URL(string: Endpoints.quotes.rawValue)!
            let (data, _) = try await URLSession.shared.data(from: url)

            return String(decoding: data, as: UTF8.self)
        }

        do {
            let text = try await downloadTask.value
            debugPrint(text)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func fetchJoke() {
        Task {
            let url = URL(string: Endpoints.jokes.rawValue)!
            var request = URLRequest(url: url)
            request.setValue("Swift Concurrency by Example", forHTTPHeaderField: "User-Agent")
            request.setValue("text/plain", forHTTPHeaderField: "Accept")

            let (data, _) = try await URLSession.shared.data(for: request)

            debugPrint("Task priority: \(Task.currentPriority)")

            if let jokeString = String(data: data, encoding: .utf8) {
                jokeText = jokeString
            } else {
                jokeText = "Load failed."
            }
        }
    }

    func getAverageTemperature() async {
        let fetchTask = Task { () -> Double in
            let url = URL(string: Endpoints.temperature.rawValue)!
            // There's an implicit cancellation, because the network call will
            // check to see whether its task is still active before continuing.
            // This implicit check happens before the network call.
            let (data, _) = try await URLSession.shared.data(from: url)
            try Task.checkCancellation()
            let readings = try JSONDecoder().decode([Double].self, from: data)
            let sum = readings.reduce(0, +)
            return sum / Double(readings.count)
        }

        do {
            let result = try await fetchTask.value
            debugPrint("Average temperature: \(result)")
        } catch {
            debugPrint("Failed to get data.")
        }
    }

    func getAverageTemperatureWithCancellation() async {
        let fetchTask = Task { () -> Double in
            let url = URL(string: Endpoints.temperature.rawValue)!

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if Task.isCancelled {
                    return 0
                }

                let readings = try JSONDecoder().decode([Double].self, from: data)
                let sum = readings.reduce(0, +)
                return sum / Double(readings.count)
            } catch {
                return 0
            }
        }

        fetchTask.cancel()
    }

    func sleep() async {
        debugPrint("Sleep will begin..")
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        debugPrint("Sleep complete!")
    }

    func factors(for number: Int) async -> [Int] {
        var result = [Int]()

        for check in 1...number {
            if number.isMultiple(of: check) {
                result.append(check)
                // This will pause every time a multiple is found,
                // allowing other tasks with higher priority to run
                await Task.yield()
            }
        }

        return result
    }
}

// MARK: - Internal Objects
private extension TaskResultView {
    enum ExampleOption: String, CaseIterable {
        case select = "Select a test example"
        case result = "Task Result"
        case taskWithPriority = "Task with Priority"
        case fetchJoke = "Fetch Joke"
        case averageTemperature = "Average Temperature"
        case averageTemperatureWithCancellation = "Average Temperature with Cancellation"
        case sleep = "Task Sleep"
        case suspendTask = "Suspend a Task"
    }

    enum LoadError: Error {
        case fetchFailed, decodeFailed
    }
}

// MARK: - Previews
#Preview {
    TaskResultView()
}


