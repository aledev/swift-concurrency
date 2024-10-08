import SwiftUI

extension URLSession {
    // First, a URLSession instance that never uses cache
    static let noCacheSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        return URLSession(configuration: config)
    }()
}

struct AsyncPropsView: View {
    // MARK: - Properties
    private let source = RemoteFile(
        url: URL(string: "https://hws.dev/inbox.json")!,
        type: [Message].self
    )

    @State private var messages = [Message]()

    // MARK: - Body
    var body: some View {
        NavigationStack {
            List(messages) { message in
                VStack(alignment: .leading) {
                    Text(message.user)
                        .font(.headline)
                    Text(message.text)
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                Button(action: refresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .onAppear(perform: refresh)
        }
    }

    func refresh() {
        Task {
            do {
                messages = try await source.contents
            } catch {
                debugPrint("Message update failed.")
            }
        }
    }
}

// MARK: - Internal class functions
extension AsyncPropsView {
    // Now our struct that will fetch and decode a URL every time we read its `contents` property
    struct RemoteFile<T: Decodable> {
        let url: URL
        let type: T.Type

        var contents: T {
            get async throws {
                let (data, _) = try await URLSession.noCacheSession.data(from: url)
                return try JSONDecoder().decode(T.self, from: data)
            }
        }
    }

    struct Message: Decodable, Identifiable {
        let id: Int
        let user: String
        let text: String
    }
}

struct AsyncPropsView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncPropsView()
    }
}
