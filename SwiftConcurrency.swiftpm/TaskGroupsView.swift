//
//  TaskGroupsView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 21/9/24.
//

import SwiftUI

struct TaskGroupsView: View {
    // MARK: - Properties
    @State private var selection: ExampleOption = .select
    @State private var stories = [NewsStory]()

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

                    ForEach(stories, id: \.id) { story in
                        VStack(alignment: .leading) {
                            Text(story.title)
                                .font(.headline)

                            Text(story.strap)
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Task: Part III")
        .onChange(of: selection) { newState in
            Task {
                await testExample(with: newState)
            }
        }
    }
}

// MARK: - Private Methods
private extension TaskGroupsView {
    func testExample(with option: ExampleOption) async {
        switch option {
        case .select:
            stories = []
        case .taskGroup:
            await printMessage()
        case .taskGroupWithThrowingTask:
            await loadStories()
        case .taskGroupWithCancellation:
            await loadStoriesUpdated()
        case .cancelAllTest:
            await cancelAllTest()
        case .cancelAllTestUpdated:
            await cancelAllTestUpdated()
        case .taskGroupWithException:
            await testCancellation()
        case .differentResultTypes:
            await loadUser()
        }
    }

    func printMessage() async {
        // Tasks created using withTaskGroup cannot throw errors.
        // For those scenarios we can use: withThrowingTaskGroup
        let string = await withTaskGroup(of: String.self) { group -> String in
            group.addTask { "Hello" }
            group.addTask { "From" }
            group.addTask { "A" }
            group.addTask { "Task" }
            group.addTask { "Group" }

            var collected = [String]()

            // Task groups conforms to AsyncSequence
            for await value in group {
                collected.append(value)
            }

            return collected.joined(separator: " ")
        }

        // The results are sent back in completion order and not creation order
        debugPrint(string)
    }

    func loadStories() async {
        do {
            stories = try await withThrowingTaskGroup(of: [NewsStory].self) { group -> [NewsStory] in
                for i in 1...5 {
                    group.addTask {
                        let url = URL(string: "https://hws.dev/news-\(i).json")!
                        let (data, _) = try await URLSession.shared.data(from: url)

                        return try JSONDecoder().decode([NewsStory].self, from: data)
                    }
                }

                let allStories = try await group.reduce(into: [NewsStory]()) { $0 += $1 }
                return allStories.sorted { $0.id > $1.id }
            }
        } catch {
            debugPrint("Failed to load stories.")
        }
    }

    func cancelAllTest() async {
        let result = await withThrowingTaskGroup(of: String.self) { group -> String in
            group.addTask { return "Testing" }
            group.addTask { return "Group" }
            group.addTask { return "Cancellation" }

            group.cancelAll()
            var collected = [String]()

            do {
                for try await value in group {
                    collected.append(value)
                }
            } catch {
                debugPrint(error.localizedDescription)
            }

            return collected.joined(separator: " ")
        }

        debugPrint(result)
    }

    func cancelAllTestUpdated() async {
        let result = await withThrowingTaskGroup(of: String.self) { group -> String in
            group.addTask {
                try Task.checkCancellation()
                return "Testing"
            }
            group.addTask {
                return "Group"
            }
            group.addTask {
                return "Cancellation"
            }

            group.cancelAll()
            var collected = [String]()

            do {
                for try await value in group {
                    collected.append(value)
                }
            } catch {
                debugPrint(error.localizedDescription)
            }

            return collected.joined(separator: " ")
        }

        debugPrint(result)
    }

    func loadStoriesUpdated() async {
        do {
            stories = []
            try await withThrowingTaskGroup(of: [NewsStory].self) { group -> Void in
                for i in 1...5 {
                    group.addTask {
                        let url = URL(string: "https://hws.dev/news-\(i).json")!
                        let (data, _) = try await URLSession.shared.data(from: url)
                        try Task.checkCancellation()
                        return try JSONDecoder().decode([NewsStory].self, from: data)
                    }
                }

                for try await result in group {
                    if result.isEmpty {
                        group.cancelAll()
                    } else {
                        stories.append(contentsOf: result)
                    }
                }

                stories.sort { $0.id < $1.id }
            }
        } catch {
            debugPrint("Failed to load stories: \(error.localizedDescription)")
        }
    }

    func testCancellation() async {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group -> Void in
                group.addTask {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    throw ExampleError.badURL
                }

                group.addTask {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    debugPrint("Task is cancelled: \(Task.isCancelled)")
                }

                try await group.next()
            }
        } catch {
            debugPrint("Error thrown: \(error.localizedDescription)")
        }
    }

    func loadUser() async {
        // Each of our tasks will return one FetchResult,
        // and the whole group will send back a User.
        let user = await withThrowingTaskGroup(of: FetchResult.self) { group -> User in
            // Fetch our username string
            group.addTask {
                let url = URL(string: Endpoints.username.rawValue)!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = String(decoding: data, as: UTF8.self)

                // Send back FetchResult.username, placing the string inside
                return .username(result)
            }

            // Fetch our favorites set
            group.addTask {
                let url = URL(string: Endpoints.userFavorites.rawValue)!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode(Set<Int>.self, from: data)

                // Send back FetchResult.favorites, placing the set inside
                return .favorites(result)
            }

            // Fetch our messages array
            group.addTask {
                let url = URL(string: Endpoints.userMessages.rawValue)!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode([Message].self, from: data)

                // Send back FetchResult.messages, placing the message array inside
                return .messages(result)
            }

            // At this point we've started all our tasks,
            // so now we need to stitch them together into
            // a single User instance. First, we set up
            // some default values:
            var username = "Anonymous"
            var favorites = Set<Int>()
            var messages = [Message]()

            // Now we read out each value, figure out
            // which case it represents, and copy its
            // associated value into the right variable.
            do {
                for try await value in group {
                    switch value {
                    case .username(let value):
                        username = value
                    case .favorites(let value):
                        favorites = value
                    case .messages(let value):
                        messages = value
                    }
                }
            } catch {
                // If any of the fetches went wrong, we might
                // at least have partial data we can send back.
                debugPrint("Fetch at least partially failed; sending back what we have so far. \(error.localizedDescription)")
            }

            // Send back our user, either filled with
            // default values or using the data we
            // fetched from the server.
            return User(username: username, favorites: favorites, messages: messages)
        }

        // Now do something with the finished user data.
        debugPrint("User \(user.username) has \(user.messages.count) messages and \(user.favorites.count) favorites.")
        debugPrint(user)
    }
}

// MARK: - Internal Objects
private extension TaskGroupsView {
    enum ExampleOption: String, CaseIterable {
        case select = "Select a test example"
        case taskGroup = "Task Group"
        case taskGroupWithThrowingTask = "Task Group withThrowingTask"
        case taskGroupWithCancellation = "Task Group withThrowingTask and Cancellation"
        case cancelAllTest = "cancelAll() Test"
        case cancelAllTestUpdated = "cancelAll() Test (updated)"
        case taskGroupWithException = "Task Group with an inner exception thrown"
        case differentResultTypes = "Different result types"
    }

    struct NewsStory: Identifiable, Decodable {
        let id: Int
        let title: String
        let strap: String
        let url: URL
    }

    struct Message: Decodable {
        let id: Int
        let from: String
        let message: String
    }

    struct User {
        let username: String
        let favorites: Set<Int>
        let messages: [Message]
    }

    enum FetchResult {
        case username(String)
        case favorites(Set<Int>)
        case messages([Message])
    }

    enum ExampleError: Error {
        case badURL
    }
}

// MARK: - Previews
#Preview {
    TaskGroupsView()
}



