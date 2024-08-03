//
//  AsyncLet.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 7/21/24.
//

import SwiftUI

struct AsyncLetView: View {
    @State private var userData: User?
    @State private var favorites: [Int]?
    @State private var messages: [Message]?

    var formattedFavorites: String? {
        guard let favorites else { return nil }
        return favorites.map { "\($0)" }.joined(separator: ",")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if let userData {
                        VStack {
                            Text("User data")
                                .font(.title3)

                            Divider()

                            HStack {
                                Text("Id:")
                                Spacer()
                                Text("\(userData.id)")
                                    .font(.callout)
                                    .lineLimit(1)
                            }
                            HStack {
                                Text("Name:")
                                Spacer()
                                Text(userData.name)
                            }
                            HStack {
                                Text("Age:")
                                Spacer()
                                Text("\(userData.age)")
                            }

                            if let formattedFavorites {
                                HStack {
                                    Text("Favorites:")
                                    Spacer()
                                    Text(formattedFavorites)
                                }
                            }
                        }
                    }

                    Spacer()

                    if let messages {
                        VStack {
                            Text("Messages")
                                .font(.title3)

                            Divider()

                            ForEach(messages) { message in
                                VStack {
                                    HStack {
                                        Text("From:")
                                        Spacer()
                                        Text(message.from)
                                    }
                                    HStack {
                                        Text("Message:")
                                        Spacer()
                                        Text(message.message)
                                            .font(.callout)
                                            .multilineTextAlignment(.trailing)
                                    }

                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Async Let")
            .toolbar {
                Button(action: {
                    Task {
                        await loadData()
                    }
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

// MARK: - Internal usage
extension AsyncLetView {
    struct User: Decodable {
        let id: UUID
        let name: String
        let age: Int
    }

    struct Message: Decodable, Identifiable {
        let id: Int
        let from: String
        let message: String
    }

    func loadData() async {
        async let (userData, _) = URLSession.shared.data(
            from: URL(string: "https://hws.dev/user-24601.json")!
        )

        async let (messageData, _) = URLSession.shared.data(
            from: URL(string: "https://hws.dev/user-messages.json")!
        )

        do {
            let decoder = JSONDecoder()
            let user = try await decoder.decode(User.self, from: userData)
            let favorites = await fetchFavorites(for: user)
            let messages = try await decoder.decode([Message].self, from: messageData)

            self.userData = user
            self.messages = messages
            self.favorites = favorites
        } catch {
            debugPrint("Sorry, there was a network problem")
        }
    }

    func fetchFavorites(for user: User) async -> [Int] {
        debugPrint("Fetching favorites for \(user.name)")

        do {
            let url = URL(string: "https://hws.dev/user-favorites.json")!
            async let (favorites, _) = URLSession.shared.data(from: url)

            return try await JSONDecoder().decode([Int].self, from: favorites)
        } catch {
            return []
        }
    }
}

// MARK: - Previews
struct AsyncLetView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncLetView()
    }
}
