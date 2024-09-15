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
        BookExample(name: "Async Let", view: AsyncLetView()),
        BookExample(name: "Continuations", view: ContinuationView()),
        BookExample(name: "Stored Continuations", view: StoredContinuationsView()),
        BookExample(name: "AsyncSequence", view: AsyncSequenceView()),
        BookExample(name: "AsyncSequence Ops", view: AsyncSequenceOperationsView()),
        BookExample(name: "CustomAsyncSequence", view: CustomAsyncSequenceView()),
        BookExample(name: "Task", view: TaskView())
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
