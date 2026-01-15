import XCTest
import RxSwift
@testable import RxSignaing

final class SignaingTests: XCTestCase {
    private final class ViewModel {
        enum Action: Equatable {
            case simpleAction
            case attributedAction(Int)
        }

        @Signaling<Action> var actions

        func makeSimpleAction() {
            _actions.accept(.simpleAction)
        }

        func makeAttributedAction(with value: Int) {
            _actions.accept(.attributedAction(value))
        }
    }

    private var viewModel: ViewModel!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()

        viewModel = ViewModel()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        viewModel = nil

        super.tearDown()
    }

    func testSimpleAction() {
        // :given
        var action: ViewModel.Action?
        viewModel.$actions
            .emit(onNext: {
                action = $0
            })
            .disposed(by: disposeBag)

        // :when
        viewModel.makeSimpleAction()

        // :then
        XCTAssertEqual(action, .simpleAction)
    }

    func testAssociatedAction() {
        // :given
        let refNumber = 42
        var action: ViewModel.Action?
        viewModel.$actions
            .emit(onNext: {
                action = $0
            })
            .disposed(by: disposeBag)

        // :when
        viewModel.makeAttributedAction(with: refNumber)

        // :then
        XCTAssertEqual(action, .attributedAction(refNumber))
    }
}
