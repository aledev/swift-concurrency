//
//  TaskView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 15/9/24.
//

import SwiftUI

struct TaskView: View {
    // MARK: - Properties
    @State private var selection: ExampleOption = .select
    @State private var messages: [Message] = []

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

                    ForEach(messages, id: \.id) { message in
                        VStack(alignment: .leading) {
                            Text(message.from)
                                .font(.headline)

                            Text(message.text)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                    }

                }
            }
        }
        .navigationTitle("Task")
        .onChange(of: selection) { newState in
            Task {
                await testExample(with: newState)
            }
        }
    }
}

// MARK: - Private Methods
private extension TaskView {
    func testExample(with option: ExampleOption) async {
        switch option {
        case .select:
            messages = []
        case .fetchUpdates:
            await fetchUpdates()
        case .loadMessages:
            await loadMessages()
        }
    }

    func fetchUpdates() async {
        let newsTask = Task { () -> [NewsItem] in
            let url = URL(string: Endpoints.headlines.rawValue)!
            let (data, _) = try await URLSession.shared.data(from: url)

            return try JSONDecoder().decode([NewsItem].self, from: data)
        }

        let highScoreTask = Task { () -> [HighScore] in
            let url = URL(string: Endpoints.scores.rawValue)!
            let (data, _) = try await URLSession.shared.data(from: url)

            return try JSONDecoder().decode([HighScore].self, from: data)
        }

        do {
            let news = try await newsTask.value
            let highScores = try await highScoreTask.value
            debugPrint("Latest news loaded with \(news.count) items.")

            if let topScore = highScores.first {
                debugPrint("\(topScore.name) has the highest score with \(topScore.score), out of \(highScores.count) total results.")
            }
        } catch {
            debugPrint("There was an error loading user data.")
        }
    }

    func loadMessages() async {
        do {
            let url = URL(string: Endpoints.messages.rawValue)!
            let (data, _) = try await URLSession.shared.data(from: url)
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            messages = [
                Message(
                    id: 0,
                    from: "Failed to load inbox.",
                    text: "Please try again later."
                )
            ]
        }
    }
}

// MARK: - Internal Objects
private extension TaskView {
    enum ExampleOption: String, CaseIterable {
        case select = "Select a test example"
        case fetchUpdates = "Fetch Updates"
        case loadMessages = "Load Messages"
    }

    struct NewsItem: Decodable {
        let id: Int
        let title: String
        let url: URL
    }

    struct HighScore: Decodable {
        let name: String
        let score: Int
    }

    struct Message: Decodable, Identifiable {
        let id: Int
        let from: String
        let text: String
    }
}

// MARK: - Previews
#Preview {
    AsyncSequenceView()
}

