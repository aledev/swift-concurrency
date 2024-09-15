//
//  CustomAsyncSequence.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 15/9/24.
//

import SwiftUI

struct CustomAsyncSequenceView: View {
    // MARK: - Properties
    @State private var selection: ExampleOption = .select
    @State private var users: [User] = []

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

                    ForEach(users, id: \.id) { user in
                        Text(user.name)
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("CustomAsyncSequence")
        .onChange(of: selection) { newState in
            Task {
                await testExample(with: newState)
            }
        }
    }
}

// MARK: - Private Methods
private extension CustomAsyncSequenceView {
    func testExample(with option: ExampleOption) async {
        switch option {
        case .select:
            users = []
        case .doubleGenerator:
            await testDoubleGenerator()
        case .urlWatcher:
            await fetchUsers()
        case .asyncSequenceToSequence:
            let result = try? await getNumberArray()
            debugPrint(result ?? [])
        }
    }

    func fetchUsers() async {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "users", withExtension: ".json") else {
            debugPrint("The file users.json couldn't be found in the module")
            return
        }

        let urlWatcher = URLWatcher(url: url, delay: 3)

        do {
            for try await data in urlWatcher {
                try withAnimation {
                    users = try JSONDecoder().decode([User].self, from: data)
                }
            }
        } catch {
            debugPrint("Error: \(error)")
        }
    }

    func testDoubleGenerator() async {
        let sequence = DoubleGenerator()
        for await number in sequence {
            debugPrint(number)
        }
    }

    func getNumberArray() async throws -> [Int] {
        let url = URL(string: Endpoints.randomNumbers.rawValue)!
        let numbers = url.lines.compactMap { Int($0) }
        return try await numbers.collect()
    }
}

// MARK: - Internal Objects
private extension CustomAsyncSequenceView {
    enum ExampleOption: String, CaseIterable {
        case select = "Select a test example"
        case doubleGenerator = "Test double generator"
        case urlWatcher = "Test url watcher"
        case asyncSequenceToSequence = "AsyncSequence to Sequence"
    }

    struct User: Identifiable, Decodable {
        let id: Int
        let name: String
    }

    struct DoubleGenerator: AsyncSequence, AsyncIteratorProtocol {
        typealias Element = Int
        var current = 1

        mutating func next() async -> Element? {
            defer { current &*= 2 }
            return current < 0 ? nil : current
        }

        func makeAsyncIterator() -> DoubleGenerator {
            self
        }
    }

    struct URLWatcher: AsyncSequence, AsyncIteratorProtocol {
        typealias Element = Data

        let url: URL
        let delay: Int
        private var comparisonData: Data?
        private var isActive = true

        init(url: URL, delay: Int = 10) {
            self.url = url
            self.delay = delay
        }

        mutating func next() async throws -> Element? {
            // Once we're inactive always return nil immediately
            guard isActive else { return nil }
            
            if comparisonData == nil {
                // If this is our first iteration, return the initial value
                comparisonData = try await fetchData()
            } else {
                // Otherwise, sleep for a while and see if our data changed
                while true {
                    try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
                    let latestData = try await fetchData()

                    if latestData != comparisonData {
                        // New data is different from previous data,
                        // So we update previoius data and send it back
                        comparisonData = latestData
                        break
                    }
                }
            }

            if comparisonData == nil {
                isActive = false
                return nil
            } else {
                return comparisonData
            }
        }

        private func fetchData() async throws -> Element {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }

        func makeAsyncIterator() -> URLWatcher {
            self
        }
    }
}

// MARK: - AsyncSequence into Sequence Converter
extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

// MARK: - Previews
#Preview {
    CustomAsyncSequenceView()
}

