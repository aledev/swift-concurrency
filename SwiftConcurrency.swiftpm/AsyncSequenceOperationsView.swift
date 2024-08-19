//
//  AsyncSequenceOperationsView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 18/8/24.
//
import SwiftUI

struct AsyncSequenceOperationsView: View {
    // MARK: - Properties
    @State private var quotes: [Quote] = []

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(quotes, id: \.id) { quote in
                        HStack {
                            Text(quote.text)
                                .font(.body)
                                .multilineTextAlignment(.center)
                        }
                        .padding(10)
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("AsyncSequence Ops")
        .toolbar {
            Button(action: {
                Task {
                    do {
                        try await shoutQuotes()
                        try await printQuotes()
                    } catch {
                        debugPrint("An exception was thrown. Details: \(error)")
                    }
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Private Methods
private extension AsyncSequenceOperationsView {
    func shoutQuotes() async throws {
        let url = URL(string: "https://hws.dev/quotes.txt")!
        let uppercaseLines = url.lines.map(\.localizedUppercase)

        for try await line in uppercaseLines {
            debugPrint(line)
        }
    }

    func printQuotes() async throws {
        quotes = []
        let url = URL(string: "https://hws.dev/quotes.txt")!
        let mappedQuotes = url.lines.map(Quote.init)

        for try await quote in mappedQuotes {
            quotes.append(quote)
        }
    }

    func printAnonymousQuotes() async throws {
        let url = URL(string: "https://hws.dev/quotes.txt")!
    }
}

// MARK: - Internal Objects
private extension AsyncSequenceOperationsView {
    struct Quote: Hashable {
        let id = UUID()
        let text: String

        @Sendable init(text: String) {
            self.text = text
        }
    }
}

// MARK: - Previews
#Preview {
    AsyncSequenceOperationsView()
}
