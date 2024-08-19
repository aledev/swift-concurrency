//
//  AsyncSequenceView.swift
//  SwiftConcurrency
//
//  Created by Alejandro Aliaga on 18/8/24.
//

import SwiftUI

struct AsyncSequenceView: View {
    // MARK: - Properties
    @State private var users: [User] = []

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(users, id: \.id) { user in
                        HStack {
                            Text("\(user.id)")
                            Spacer()
                            Text("\(user.firstName) \(user.lastName)")
                            Spacer()
                            Text(user.country)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("AsyncSequence")
        .toolbar {
            Button(action: {
                Task {
                    do {
                        try await fetchUsers()
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
private extension AsyncSequenceView {
    func fetchUsers() async throws {
        users = []
        let url = URL(string: "https://hws.dev/users.csv")!

        for try await line in url.lines {
            let parts = line.split(separator: ",")
            guard parts.count == 4 else { continue }

            guard let id = Int(parts[0]) else { continue }
            let firstName = String(parts[1])
            let lastName = String(parts[2])
            let country = String(parts[3])

            users.append(
                User(
                    id: id,
                    firstName: firstName,
                    lastName: lastName,
                    country: country
                )
            )
        }
    }
}

// MARK: - Internal Objects
private extension AsyncSequenceView {
    struct User {
        let id: Int
        let firstName: String
        let lastName: String
        let country: String
    }
}

// MARK: - Previews
#Preview {
    AsyncSequenceView()
}
