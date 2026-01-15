import Combine
/**
 * Property wrapper allows you to emit and subscribe to `Action` events.
 * - `_variable` to emit events
 * - `$variable` to subscribe to events from outside
 *
 * Example:
 *
 *
 *     final class ViewModel {
 *         enum Action {
 *             case showAlert
 *         }
 *
 *         @Signaling<Action> var actions
 *
 *         private func onTapButton() {
 *             _actions.send(.showAlert)
 *         }
 *     }
 *
 *     final class Coordinator {
 *         private var viewModel = ViewModel()
 *         private var cancellables = Set<AnyCancellable>()
 *
 *         init() {
 *             viewModel.$actions
 *                 .sink(receiveValue: {
 *                     switch $0 {
 *                     case .showAlert:
 *                         ()
 *                     }
 *                 })
 *                 .store(in: &cancellables)
 *         }
 *     }
 */
@propertyWrapper
public struct Signaling<Action> {
    private let dataSubject: PassthroughSubject<Action, Never>
    public let projectedValue: Signal<Action>
    public let wrappedValue: Action.Type = Action.self

    public init() {
        self.dataSubject = .init()
        self.projectedValue = dataSubject.asSignal()
    }

    public func send(_ action: Action) {
        dataSubject.send(action)
    }
}

public extension Signaling where Action == Void {
    func send() {
        send(())
    }
}
