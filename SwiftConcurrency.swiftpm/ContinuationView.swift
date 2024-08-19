//
//  Continuation.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 3/8/24.
//

import SwiftUI

struct ContinuationView: View {
    @State var messages: [Message] = []
    @State var selection: ExampleOption = .select

    var body: some View {
        VStack {
            Picker("Select a test example", selection: $selection) {
                ForEach(ExampleOption.allCases, id: \.hashValue) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.menu)

            Divider()

            List(messages) { message in
                HStack {
                    Text("\(message.id)")
                    Spacer()
                    Text(message.from)
                    Spacer()
                    Text(message.message)
                }
            }
        }
        .onChange(of: selection) { newState in
            Task {
                debugPrint(selection)
                await testExample(with: newState)
            }
        }
    }
}

// MARK: - Functions
extension ContinuationView {
    func testExample(with option: ExampleOption) async {
        switch option {
        case .select:
            messages = []
        case .continuation:
            messages = await fetchMessages()
        case .continuationWithException:
            do {
                let fetchedMessages = try await fetchMessagesWithException()
                messages = fetchedMessages
            } catch {
                debugPrint(error)
            }
        }
    }

    func fetchMessages(completion: @escaping ([Message]) -> Void){
        let url = URL(string: "https://hws.dev/user-messages.json")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data,
               let messages = try? JSONDecoder().decode([Message].self, from: data) {
                completion(messages)
                return
            }

            completion([])
        }.resume()
    }

    func fetchMessages() async -> [Message] {
        await withCheckedContinuation { continuation in
            fetchMessages { messages in
                continuation.resume(returning: messages)
                // Because it's a checked continuation, there must be only one resume
                // nor zero, nor two... just one!
                // In case there's no resume, you will get a compiler warning message
                // In case there's two resumes, the app will crash.
                // Uncomment the following line to double check it.
                //continuation.resume(returning: [])
            }
        }
    }

    func fetchMessagesWithException() async throws -> [Message] {
        try await withCheckedThrowingContinuation { continuation in
            fetchMessages { messages in
                if messages.isEmpty {
                    continuation.resume(throwing: FetchError.noMessages)
                    return
                }

                continuation.resume(returning: messages)
            }
        }
    }
}

// MARK: - Internal objects
extension ContinuationView {
    enum FetchError: Error {
        case noMessages
    }

    enum ExampleOption: String, CaseIterable {
        case select = "Select a test example"
        case continuation = "Continuation"
        case continuationWithException = "Continuation with Exception"
    }

    struct Message: Decodable, Identifiable {
        let id: Int
        let from: String
        let message: String
    }
}

// MARK: - Previews
struct ContinuationView_Previews: PreviewProvider {
    static var previews: some View {
        ContinuationView()
    }
}
