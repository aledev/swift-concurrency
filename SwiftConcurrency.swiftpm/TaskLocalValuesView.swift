//
//  TaskLocalValuesView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 22/9/24.
//

import SwiftUI

struct TaskLocalValuesView: View {
    // MARK: - Properties
    @State private var selection: ExampleOption = .select
    @State private var messages = [Message]()
    @State private var selectedBox = "Inbox"
    let messageBoxes = ["Inbox", "Sent"]

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

                    if !messages.isEmpty {
                        ForEach(messages, id: \.id) { message in
                            VStack(alignment: .leading) {
                                Text(message.user)
                                    .font(.headline)

                                Text(message.text)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Task: Part IV")
        .onChange(of: selection) { newState in
            Task {
                await testExample(with: newState)
            }
        }
    }
}

// MARK: - Private Methods
private extension TaskLocalValuesView {
    func testExample(with option: ExampleOption) async {
        switch option {
        case .select:
            debugPrint("Select")
        case .taskLocalValueTest:
            try? await TaskLocalValuesView.taskLocalTest()
        case .taskLocalValueRealWorldTest:
            try? await TaskLocalValuesView.testLogger()
        case .fetchInbox:
            selectedBox = "Inbox"
            await fetchData()
        case .fetchSent:
            selectedBox = "Sent"
            await fetchData()
        }
    }

    @MainActor
    static func taskLocalTest() async throws {
        Task {
            try await User.$id.withValue("Piper") {
                debugPrint("Start of task: \(User.id)")
                try await Task.sleep(nanoseconds: 1_000_000)
                debugPrint("End of task: \(User.id)")
            }
        }

        Task {
            try await User.$id.withValue("Alex") {
                debugPrint("Start of task: \(User.id)")
                try await Task.sleep(nanoseconds: 1_000_000)
                debugPrint("End of task: \(User.id)")
            }
        }

        debugPrint("Outside of tasks: \(User.id)")
    }

    @MainActor
    static func testLogger() async throws {
        Task {
            try await Logger.$logLevel.withValue(.debug) {
                try await fetch(url: "https://hws.dev/news-1.json")
            }
        }

        Task {
            try await Logger.$logLevel.withValue(.error) {
                try await fetch(url: "https:\\hws.dev/news-1.json")
            }
        }
    }

    @MainActor
    static func fetch(url urlString: String) async throws -> String? {
        Logger.shared.write("Preparing request: \(urlString)", level: .debug)

        if let url = URL(string: urlString) {
            let (data, _) = try await URLSession.shared.data(from: url)
            Logger.shared.write("Received \(data.count) bytes", level: .info)
            return String(decoding: data, as: UTF8.self)
        } else {
            Logger.shared.write("URL \(urlString) is invalid", level: .error)
            return nil
        }
    }

    func fetchData() async {
        do {
            let url = URL(string: "https://hws.dev/\(selectedBox.lowercased()).json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            messages = [
                Message(
                    id: 0,
                    user: "Failed to load message box.",
                    text: "Please try again later."
                )
            ]
        }
    }
}

// MARK: - Internal Objects
private extension TaskLocalValuesView {
    enum ExampleOption: String, CaseIterable {
        case select = "Select a test example"
        case taskLocalValueTest = "Task-Local Value Test"
        case taskLocalValueRealWorldTest = "Task-Local Value Real-World Test"
        case fetchInbox = "Fetch Inbox"
        case fetchSent = "Fetch Sent"
    }

    enum User {
        @TaskLocal static var id = "Anonymous"
    }

    // Our five log levels, marked Comparable so we can use < and > with them
    enum LogLevel: Comparable {
        case debug, info, warn, error, fatal
    }

    struct Logger {
        // The log level for an individual task
        @TaskLocal static var logLevel = LogLevel.info

        // Make this struct a singleton
        private init() {}
        static let shared = Logger()

        // Print out a message only if it meets or exceeds our log level.
        func write(_ message: String, level: LogLevel) {
            if level >= Logger.logLevel {
                debugPrint(message)
            }
        }
    }

    struct Message: Decodable, Identifiable {
        let id: Int
        let user: String
        let text: String
    }
}

// MARK: - Previews
#Preview {
    TaskLocalValuesView()
}




