import Foundation

@propertyWrapper
struct ConcurrentSignaling<Action: Sendable> {
    private let continuation: AsyncStream<Action>.Continuation

    let projectedValue: AsyncStream<Action>
    var wrappedValue: AsyncStream<Action> {
        projectedValue
    }

    public func send(_ action: Action) {
        continuation.yield(action)
    }

    init() {
        (self.projectedValue, self.continuation) = AsyncStream.makeStream(of: Action.self)
    }
}

extension ConcurrentSignaling where Action == Void {
    func send() {
        send(())
    }
}
