import XCTest
@testable import ConcurrencySignaling

final class ConcurrencySignalingTests: XCTestCase {
    private final class ViewModel {
        enum Action: Equatable {
            case first
            case second(Int)
        }

        @ConcurrentSignaling<Action> var actions

        func makeSimpleAction() {
            _actions.send(.first)
        }

        func makeAttributedAction(with value: Int) {
            _actions.send(.second(value))
        }
    }

    private var viewModel: ViewModel!

    override func setUp() {
        super.setUp()

        viewModel = ViewModel()
    }

    override func tearDown() {
        viewModel = nil

        super.tearDown()
    }

    @MainActor
    func testSimpleAction() {
        // :given
        var action: ViewModel.Action?
        let expectation = XCTestExpectation(description: "Receive action")

        Task {
            for await value in viewModel.actions {
                action = value
                expectation.fulfill()
                break
            }
        }

        // :when
        viewModel.makeSimpleAction()

        // :then
        wait(for: [expectation])
        XCTAssertEqual(action, .first)
    }

    @MainActor
    func testAssociatedAction() {
        // :given
        let refNumber = 42
        var action: ViewModel.Action?
        let expectation = XCTestExpectation(description: "Receive action")

        Task {
            for await value in viewModel.actions {
                action = value
                expectation.fulfill()
                break
            }
        }

        // :when
        viewModel.makeAttributedAction(with: refNumber)

        // :then
        wait(for: [expectation])
        XCTAssertEqual(action, .second(refNumber))
    }
}
