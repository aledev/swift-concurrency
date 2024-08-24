//
//  AsyncSequenceOperationsView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 18/8/24.
//
import SwiftUI

struct AsyncSequenceOperationsView: View {
    // MARK: - Properties
    @State private var selection: ExampleOption = .select
    @State private var quotes: [Quote] = []

    private let url = URL(string: "https://hws.dev/quotes.txt")!

    let convertToInt: @Sendable (String) async -> Int? = { text in
        return Int(text)
    }

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
        .onChange(of: selection) { newState in
            Task {
                await testExample(with: newState)
            }
        }
    }
}

// MARK: - Private Methods
private extension AsyncSequenceOperationsView {
    func testExample(with option: ExampleOption) async {
        switch option {
        case .select:
            quotes = []
        case .shoutQuotes:
            try? await shoutQuotes()
        case .printAllQuotes:
            try? await printQuotes()
        case .printAnonymousQuotes:
            try? await printAnonymousQuotes()
        case .printTopUpperAnonymousQuotes:
            try? await printUppercasedTopQuotes()
        case .checkForShortQuotes:
            try? await checkQuotes()
        case .printHighestNumber:
            try? await printHighestNumber()
        case .sumRandomNumbers:
            try? await sumRandomNumbers()
        }
    }

    func shoutQuotes() async throws {
        let uppercaseLines = url.lines.map(\.localizedUppercase)
        try await showResult(for: uppercaseLines)
    }

    func printQuotes() async throws {
        let mappedQuotes = url.lines.map(Quote.init)
        try await showResult(for: mappedQuotes)
    }

    func printAnonymousQuotes() async throws {
        let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }
        try await showResult(for: anonymousQuotes)
    }

    func printTopQuotes() async throws {
        let topQuotes = url.lines.prefix(5)
        try await showResult(for: topQuotes)
    }

    func printUppercasedTopQuotes() async throws {
        let anonymousQuotes = url.lines.filter { $0.contains("Anonymous") }
        let topAnonymousQuotes = anonymousQuotes.prefix(5)
        let shoutingTopAnonymouesQuotes = topAnonymousQuotes.map(\.localizedUppercase)
        try await showResult(for: shoutingTopAnonymouesQuotes)
    }

    func checkQuotes() async throws {
        let noShortQuotes = try await url.lines.allSatisfy { $0.count > 30 }
        debugPrint(noShortQuotes)
    }

    func printHighestNumber() async throws {
        let url = URL(string: "https://hws.dev/random-numbers.txt")!
        if let highest = try await url.lines.compactMap(convertToInt).max() {
            debugPrint("Highest number: \(highest)")
        } else {
            debugPrint("No number was the highest.")
        }
    }

    func sumRandomNumbers() async throws {
        let url = URL(string: "https://hws.dev/random-numbers.txt")!
        let sum = try await url.lines.compactMap(convertToInt).reduce(0, +)
        debugPrint(sum)
    }

    func showResult(for result: any AsyncSequence) async throws {
        quotes = []
        for try await line in result {
            if let quote = line as? Quote {
                quotes.append(quote)
                continue
            }

            quotes.append(Quote(text: line as! String))
        }
    }
}

// MARK: - Internal Objects
private extension AsyncSequenceOperationsView {
    enum ExampleOption: String, CaseIterable {
        case select = "Select a test example"
        case shoutQuotes = "Shout Quotes"
        case printAllQuotes = "Print All Quotes"
        case printAnonymousQuotes = "Print Anonymous Quotes"
        case printTopUpperAnonymousQuotes = "Print Top Uppercased Anonymous Quotes"
        case checkForShortQuotes = "Check if there's short quotes"
        case printHighestNumber = "Print highest number"
        case sumRandomNumbers = "Sum random numbers"
    }

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
