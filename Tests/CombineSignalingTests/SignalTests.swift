import XCTest
import Combine
import CombineSchedulers
@testable import CombineSignaling

final class SignalTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!
    private var scheduler: TestSchedulerOf<DispatchQueue>!

    override func setUp() {
        super.setUp()
        cancellables = []
        scheduler = DispatchQueue.test
    }

    override func tearDown() {
        scheduler = nil
        cancellables = nil
        super.tearDown()
    }

    func testSignal_PropagatesValuesFromOriginalPublisher() {
        // :given
        let refArray = [1, 2, 3]
        let timeStride = 100
        let publisher = refArray.map { ($0, $0 * timeStride) }
            .delayedPublisher(scheduler: scheduler.eraseToAnyScheduler())

        let signal = publisher.asSignal()

        // :when
        var result: [Int] = []
        signal
            .sink {
                result.append($0)
            }
            .store(in: &cancellables)

        // :then
        scheduler.advance(by: .milliseconds(refArray.last! * timeStride)) // 300
        XCTAssertEqual(result, refArray)
    }

    func testSignal_EmitsElementsOnMainQueue() {
        // :given
        let publisher = [1].publisher
            .receive(on: DispatchQueue.testQueue)

        let signal = publisher.asSignal()
        let exp = expectation(description: "Wait for call on main queue")

        // :when
        signal
            .sink(receiveValue: { _ in
                if Thread.isMainThread {
                    exp.fulfill()
                }
            })
            .store(in: &cancellables)

        // :then
        wait(for: [exp])
    }

    func testSignal_EmitsElementsOnSameRunLoopCycle_IfElementEmitsOnMainQueueOriginally() {
        // :given
        let refArray = [1, 2, 3]
        let publisher = refArray.publisher
        let signal = publisher.asSignal()

        // :when
        var result: [Int] = []
        signal
            .sink {
                result.append($0)
            }
            .store(in: &cancellables)

        // :then
        XCTAssertEqual(result, refArray)
    }

    func testSignal_SharesInitialPublisher_UnlikeTheAnyPublisher() {
        // :given
        let latestFiringTimeInMillisecs = 400
        let initialPublisher = [(1, 0), (2, 300), (3, latestFiringTimeInMillisecs)]
            .delayedPublisher(scheduler: scheduler.eraseToAnyScheduler())
        let signal = initialPublisher.asSignal()

        let publisher = initialPublisher

        var firstSignalArray: [Int] = []
        var firstPublisherArray: [Int] = []
        var secondSignalArray: [Int] = []
        var secondPublisherArray: [Int] = []

        // first subscription for the signal
        signal
            .sink { firstSignalArray.append($0) }
            .store(in: &cancellables)

        // first subscription for the publisher
        publisher
            .sink { firstPublisherArray.append($0) }
            .store(in: &cancellables)

        // :when
        scheduler.advance(by: .milliseconds(100)) // receive first event (value 1 with zero delay) for both signal and publisher

        // second subscription for the signal
        signal
            .sink { secondSignalArray.append($0) }
            .store(in: &cancellables)

        // second subscription for the publisher
        publisher
            .sink { secondPublisherArray.append($0) }
            .store(in: &cancellables)

        // :then
        scheduler.advance(by: .milliseconds(latestFiringTimeInMillisecs))
        XCTAssertEqual(firstSignalArray, firstPublisherArray)
        XCTAssertEqual(firstPublisherArray, secondPublisherArray) // publishers do not share subscriptions (unlike signals)
        XCTAssertEqual(firstSignalArray, [1, 2, 3])
        XCTAssertEqual(secondSignalArray, [2, 3])
    }

    func testSignal_EmitsCompletionOnMainQueue_IfInitialPublisherReceivesOnAnotherQueue() {
        // :given
        let publisher = [Int]().publisher
            .receive(on: DispatchQueue.testQueue)

        let signal = publisher.asSignal()
        let exp = expectation(description: "Wait for completion on main queue")

        // :when
        signal
            .sink(
                receiveCompletion: { _ in
                    if Thread.isMainThread {
                        exp.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        // :then
        wait(for: [exp])
    }

    func testSignal_EmitsCompletionOnMainQueue_IfValuesAndCompletionReceivedAsyncAfterSubscription() {
        // :given
        let subject = PassthroughSubject<Int, Never>()
        let signal = subject.asSignal()
        let completionTime = DispatchQueue.SchedulerTimeType(.now() + .milliseconds(100))

        let scheduler = DispatchQueue.test
        scheduler.schedule(after: .init(.now() + .milliseconds(1))) {
            subject.send(1)
        }

        scheduler.schedule(after: completionTime) {
            subject.send(completion: .finished)
        }

        let exp = expectation(description: "Wait for call on main queue")

        // :when
        signal
            .sink(
                receiveCompletion: { _ in
                    if Thread.isMainThread {
                        exp.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        scheduler.advance(to: completionTime)

        // :then
        wait(for: [exp])
    }
}

extension DispatchQueue {
    static let testQueue = DispatchQueue(label: "test queue", qos: .userInitiated)
}

extension Array {
    func delayedPublisher<E>(scheduler: AnySchedulerOf<DispatchQueue> = .main) -> AnyPublisher<E, Never> where Element == (E, Int) {
        publisher
            .flatMap { e -> AnyPublisher<E, Never> in
                let (element, delay) = e
                return AnyPublisher.just(element)
                    .delay(for: .milliseconds(delay), scheduler: scheduler)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
