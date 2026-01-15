import XCTest
import Combine
@testable import CombineSignaling

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
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        viewModel = ViewModel()
        cancellables = .init()
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil

        super.tearDown()
    }

    func testSimpleAction() {
        // :given
        var action: ViewModel.Action?
        viewModel.$actions
            .sink(receiveValue: {
                action = $0
            })
            .store(in: &cancellables)

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
            .sink(receiveValue: {
                action = $0
            })
            .store(in: &cancellables)

        // :when
        viewModel.makeAttributedAction(with: refNumber)

        // :then
        XCTAssertEqual(action, .attributedAction(refNumber))
    }
}
