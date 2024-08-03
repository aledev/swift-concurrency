import SwiftUI

struct BookExample {
    let name: String
    let view: AnyView

    init(name: String, view: some View) {
        self.name = name
        self.view = AnyView(view)
    }
}

@main
struct MyApp: App {
    let examples: [BookExample] = [
        BookExample(name: "Async Property", view: AsyncPropsView()),
        BookExample(name: "Async Let", view: AsyncLetView())
    ]

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List(examples, id: \.name) { example in
                    NavigationLink {
                        example.view
                    } label: {
                        Text(example.name)
                    }
                }
                .navigationTitle("Swift Concurrency Examples")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
