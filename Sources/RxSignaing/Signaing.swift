import RxRelay
import RxCocoa
/**
 * Property wrapper allows you to emit and subscribe to `Action` events.
 * - `_variable` to emit events
 * - `$variable` to subscribe to events from outside
 *
 * Example:
 *
 *      final class ViewModel {
 *          enum Action {
 *            case close
 *          }
 *
 *          @Signaling<Action> var foo
 *          ...
 *
 *          private func onTapButton() {
 *              _foo.accept(.close)
 *          }
 *      }
 *
 *      let viewModel = ViewModel()
 *      viewModel.$foo
 *         .emit(onNext: { (action: Action) in
 *              switch action {
 *                case .close:
 *                  ...
 *              }
 *         })
 *         .disposed(by: disposeBag)
 */
@propertyWrapper
public struct Signaling<Action> {
    private let relay: PublishRelay<Action>
    public let projectedValue: RxCocoa.Signal<Action>
    public let wrappedValue: Action.Type = Action.self

    public init() {
        self.relay = .init()
        self.projectedValue = relay.asSignal()
    }

    public func accept(_ action: Action) {
        relay.accept(action)
    }
}

public extension Signaling where Action == Void {
    func accept() {
        accept(())
    }
}
