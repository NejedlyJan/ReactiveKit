//
//  OperatorTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 12/04/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
import ReactiveKit
import Dispatch

enum TestError: Swift.Error {
    case Error
}

class SignalTests: XCTestCase {

    func testPerformance() {
        self.measure {
            (0..<1000).forEach { _ in
                let signal = ReactiveKit.Signal<Int, Never> { observer in
                    (0..<100).forEach(observer.receive(_:))
                    observer.receive(completion: .finished)
                    return NonDisposable.instance
                }
                _ = signal.observe { _ in }
            }
        }
    }

    func testProductionAndObservation() {
        let bob = Scheduler()
        bob.runRemaining()

        let operation = Signal<Int, TestError>(sequence: [1, 2, 3]).executeIn(bob.context)

        operation.expectComplete(after: [1, 2, 3])
        operation.expectComplete(after: [1, 2, 3])
        XCTAssertEqual(bob.numberOfRuns, 2)
    }

    func testDisposing() {
        let disposable = SimpleDisposable()

        let operation = Signal<Int, TestError> { _ in
            return disposable
        }

        operation.observe { _ in }.dispose()
        XCTAssertTrue(disposable.isDisposed)
    }

    func testJust() {
        let operation = Signal<Int, TestError>(just: 1)
        operation.expectComplete(after: [1])
    }

    func testSequence() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        operation.expectComplete(after: [1, 2, 3])
    }

    func testCompleted() {
        let operation = Signal<Int, TestError>.completed()
        operation.expectComplete(after: [])
    }

    func testNever() {
        let operation = Signal<Int, TestError>.never()
        operation.expectNoEvent()
    }

    func testFailed() {
        let operation = Signal<Int, TestError>.failed(.Error)
        operation.expect(events: [.failed(.Error)])
    }

    func testObserveFailed() {
        var observedError: TestError? = nil
        let operation = Signal<Int, TestError>.failed(.Error)
        _ = operation.observeFailed {
            observedError = $0
        }
        XCTAssert(observedError != nil && observedError! == .Error)
    }

    func testObserveCompleted() {
        var completed = false
        let operation = Signal<Int, TestError>.completed()
        _ = operation.observeCompleted {
            completed = true
        }
        XCTAssert(completed == true)
    }

    func testBuffer() {
        SafeSignal(sequence: [1, 2, 3]).buffer(ofSize: 1).expectComplete(after: [[1], [2], [3]])
        SafeSignal(sequence: [1, 2, 3, 4]).buffer(ofSize: 2).expectComplete(after: [[1, 2], [3, 4]])
        SafeSignal(sequence: [1, 2, 3, 4, 5]).buffer(ofSize: 2).expectComplete(after: [[1, 2], [3, 4]])
    }

    func testMap() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let mapped = operation.map { $0 * 2 }
        mapped.expectComplete(after: [2, 4, 6])
    }

    func testScan() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let scanned = operation.scan(0, +)
        scanned.expectComplete(after: [0, 1, 3, 6])
    }

    func testToSignal() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let operation2 = operation.toSignal()
        operation2.expectComplete(after: [1, 2, 3])
    }

    func testSuppressError() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let signal = operation.suppressError(logging: false)
        signal.expectComplete(after: [1, 2, 3])
    }

    func testSuppressError2() {
        let operation = Signal<Int, TestError>.failed(.Error)
        let signal = operation.suppressError(logging: false)
        signal.expectComplete(after: [])
    }

    func testRecover() {
        let operation = Signal<Int, TestError>.failed(.Error)
        let signal = operation.recover(with: 1)
        signal.expectComplete(after: [1])
    }

    func testWindow() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let window = operation.window(ofSize: 2)
        window.merge().expectComplete(after: [1, 2])
    }

    //  func testDebounce() {
    //    let operation = Signal<Int, TestError>.interval(0.1, queue: Queue.global).take(first: 3)
    //    let distinct = operation.debounce(interval: 0.3, on: Queue.global)
    //    let exp = expectation(withDescription: "completed")
    //    distinct.expectComplete(after: [2], expectation: exp)
    //    waitForExpectations(withTimeout: 1, handler: nil)
    //  }

    func testDistinct() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 2, 3])
        let distinct = operation.distinctUntilChanged { a, b in a != b }
        distinct.expectComplete(after: [1, 2, 3])
    }

    func testDistinct2() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 2, 3])
        let distinct = operation.distinctUntilChanged()
        distinct.expectComplete(after: [1, 2, 3])
    }

    func testElementAt() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let elementAt1 = operation.element(at: 1)
        elementAt1.expectComplete(after: [2])
    }

    func testFilter() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let filtered = operation.filter { $0 % 2 != 0 }
        filtered.expectComplete(after: [1, 3])
    }

    func testFirst() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let first = operation.first()
        first.expectComplete(after: [1])
    }

    func testIgnoreElement() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let ignoreElements = operation.ignoreElements()
        ignoreElements.expectComplete(after: [])
    }

    func testLast() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let first = operation.last()
        first.expectComplete(after: [3])
    }

    // TODO: sample

    func testSkip() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let skipped1 = operation.skip(first: 1)
        skipped1.expectComplete(after: [2, 3])
    }

    func testSkipLast() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let skippedLast1 = operation.skip(last: 1)
        skippedLast1.expectComplete(after: [1, 2])
    }

    func testTakeFirst() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let taken2 = operation.take(first: 2)
        taken2.expectComplete(after: [1, 2])
    }

    func testTakeLast() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let takenLast2 = operation.take(last: 2)
        takenLast2.expectComplete(after: [2, 3])
    }

    func testTakeUntil() {
        let bob = Scheduler()
        let eve = Scheduler()

        let operation = Signal<Int, TestError>(sequence: [1, 2, 3, 4]).observeIn(bob.context)
        let interrupt = Signal<String, TestError>(sequence: ["A", "B"]).observeIn(eve.context)

        let takeuntil = operation.take(until: interrupt)

        let exp = expectation(description: "completed")
        takeuntil.expectAsyncComplete(after: [1, 2], expectation: exp)

        bob.runOne()                // Sends 1.
        bob.runOne()                // Sends 2.
        eve.runOne()                // Sends A, effectively stopping the receiver.
        bob.runOne()                // Ignored.
        eve.runRemaining()          // Ignored. Sends B, with termination.
        bob.runRemaining()          // Ignored.

        waitForExpectations(timeout: 1, handler: nil)
    }

    //  func testThrottle() {
    //    let operation = Signal<Int, TestError>.interval(0.4, queue: Queue.global).take(5)
    //    let distinct = operation.throttle(1)
    //    let exp = expectation(withDescription: "completed")
    //    distinct.expectComplete(after: [0, 3], expectation: exp)
    //    waitForExpectationsWithTimeout(3, handler: nil)
    //  }

    func testIgnoreNils() {
        let operation = Signal<Int?, TestError>(sequence: Array<Int?>([1, nil, 3]))
        let unwrapped = operation.ignoreNils()
        unwrapped.expectComplete(after: [1, 3])
    }

    func testReplaceNils() {
        let operation = Signal<Int?, TestError>(sequence: Array<Int?>([1, nil, 3, nil]))
        let unwrapped = operation.replaceNils(with: 7)
        unwrapped.expectComplete(after: [1, 7, 3, 7])
    }

    func testCombineLatestWith() {
        let bob = Scheduler()
        let eve = Scheduler()

        let operationA = Signal<Int, TestError>(sequence: [1, 2, 3]).observeIn(bob.context)
        let operationB = Signal<String, TestError>(sequence: ["A", "B", "C"]).observeIn(eve.context)
        let combined = operationA.combineLatest(with: operationB).map { "\($0)\($1)" }

        let exp = expectation(description: "completed")
        combined.expectAsyncComplete(after: ["1A", "1B", "2B", "3B", "3C"], expectation: exp)

        bob.runOne()
        eve.runOne()
        eve.runOne()
        bob.runRemaining()
        eve.runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMergeWith() {
        let bob = Scheduler()
        let eve = Scheduler()
        let operationA = Signal<Int, TestError>(sequence: [1, 2, 3]).observeIn(bob.context)
        let operationB = Signal<Int, TestError>(sequence: [4, 5, 6]).observeIn(eve.context)
        let merged = operationA.merge(with: operationB)

        let exp = expectation(description: "completed")
        merged.expectAsyncComplete(after: [1, 4, 5, 2, 6, 3], expectation: exp)

        bob.runOne()
        eve.runOne()
        eve.runOne()
        bob.runOne()
        eve.runRemaining()
        bob.runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testStartWith() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let startWith4 = operation.start(with: 4)
        startWith4.expectComplete(after: [4, 1, 2, 3])
    }

    func testZipWith() {
        let operationA = Signal<Int, TestError>(sequence: [1, 2, 3])
        let operationB = Signal<String, TestError>(sequence: ["A", "B"])
        let combined = operationA.zip(with: operationB).map { "\($0)\($1)" }
        combined.expectComplete(after: ["1A", "2B"])
    }

    func testZipWithWhenNotComplete() {
        let operationA = Signal<Int, TestError>(sequence: [1, 2, 3]).ignoreTerminal()
        let operationB = Signal<String, TestError>(sequence: ["A", "B"])
        let combined = operationA.zip(with: operationB).map { "\($0)\($1)" }
        combined.expectComplete(after: ["1A", "2B"])
    }

    func testZipWithWhenNotComplete2() {
        let operationA = Signal<Int, TestError>(sequence: [1, 2, 3])
        let operationB = Signal<String, TestError>(sequence: ["A", "B"]).ignoreTerminal()
        let combined = operationA.zip(with: operationB).map { "\($0)\($1)" }
        combined.expect(events: [.next("1A"), .next("2B")])
    }

    func testZipWithAsyncSignal() {
        let operationA = Signal<Int, TestError>(sequence: 0..<4, interval: 0.5)
        let operationB = Signal<Int, TestError>(sequence: 0..<10, interval: 1.0)
        let combined = operationA.zip(with: operationB).map { $0 + $1 } // Completes after 4 nexts due to operationA and takes 4 secs due to operationB
        let exp = expectation(description: "completed")
        combined.expectAsyncComplete(after: [0, 2, 4, 6], expectation: exp)
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testFlatMapError() {
        let operation = Signal<Int, TestError>.failed(.Error)
        let recovered = operation.flatMapError { error in Signal<Int, TestError>(just: 1) }
        recovered.expectComplete(after: [1])
    }

    func testFlatMapError2() {
        let operation = Signal<Int, TestError>.failed(.Error)
        let recovered = operation.flatMapError { error in Signal<Int, Never>(just: 1) }
        recovered.expectComplete(after: [1])
    }

    func testRetry() {
        let bob = Scheduler()
        bob.runRemaining()

        let operation = Signal<Int, TestError>.failed(.Error).executeIn(bob.context)
        let retry = operation.retry(times: 3)
        retry.expect(events: [.failed(.Error)])

        XCTAssertEqual(bob.numberOfRuns, 4)
    }

    func testexecuteIn() {
        let bob = Scheduler()
        bob.runRemaining()

        let operation = Signal<Int, TestError>(sequence: [1, 2, 3]).executeIn(bob.context)
        operation.expectComplete(after: [1, 2, 3])

        XCTAssertEqual(bob.numberOfRuns, 1)
    }

    // TODO: delay

    func testDoOn() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        var start = 0
        var next = 0
        var completed = 0
        var disposed = 0

        let d = operation.doOn(next: { _ in next += 1 }, start: { start += 1}, completed: { completed += 1}, disposed: { disposed += 1}).observe { _ in }

        XCTAssert(start == 1)
        XCTAssert(next == 3)
        XCTAssert(completed == 1)
        XCTAssert(disposed == 1)

        d.dispose()
        XCTAssert(disposed == 1)
    }

    func testobserveIn() {
        let bob = Scheduler()
        bob.runRemaining()

        let operation = Signal<Int, TestError>(sequence: [1, 2, 3]).observeIn(bob.context)
        operation.expectComplete(after: [1, 2, 3])

        XCTAssertEqual(bob.numberOfRuns, 4) // 3 elements + completion
    }

    func testPausable() {
        let operation = PassthroughSubject<Int, TestError>()
        let controller = PassthroughSubject<Bool, TestError>()
        let paused = operation.share().pausable(by: controller)

        let exp = expectation(description: "completed")
        paused.expectAsyncComplete(after: [1, 3], expectation: exp)

        operation.send(1)
        controller.send(false)
        operation.send(2)
        controller.send(true)
        operation.send(3)
        operation.send(completion: .finished)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTimeoutNoFailure() {
        let exp = expectation(description: "completed")
        Signal<Int, TestError>(just: 1).timeout(after: 0.2, with: .Error, on: DispatchQueue.main).expectAsyncComplete(after: [1], expectation: exp)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTimeoutFailure() {
        let exp = expectation(description: "completed")
        Signal<Int, TestError>.never().timeout(after: 0.5, with: .Error, on: DispatchQueue.main).expectAsync(events: [.failed(.Error)], expectation: exp)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAmbWith() {
        let bob = Scheduler()
        let eve = Scheduler()

        let operationA = Signal<Int, TestError>(sequence: [1, 2]).observeIn(bob.context)
        let operationB = Signal<Int, TestError>(sequence: [3, 4]).observeIn(eve.context)
        let ambdWith = operationA.amb(with: operationB)

        let exp = expectation(description: "completed")
        ambdWith.expectAsyncComplete(after: [3, 4], expectation: exp)

        eve.runOne()
        bob.runRemaining()
        eve.runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCollect() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let collected = operation.collect()
        collected.expectComplete(after: [[1, 2, 3]])
    }

    func testConcatWith() {
        let bob = Scheduler()
        let eve = Scheduler()

        let operationA = Signal<Int, TestError>(sequence: [1, 2]).observeIn(bob.context)
        let operationB = Signal<Int, TestError>(sequence: [3, 4]).observeIn(eve.context)
        let merged = operationA.concat(with: operationB)

        let exp = expectation(description: "completed")
        merged.expectAsyncComplete(after: [1, 2, 3, 4], expectation: exp)

        bob.runOne()
        eve.runOne()
        bob.runRemaining()
        eve.runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDefaultIfEmpty() {
        let operation = Signal<Int, TestError>(sequence: [])
        let defaulted = operation.defaultIfEmpty(1)
        defaulted.expectComplete(after: [1])
    }

    func testReduce() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let reduced = operation.reduce(0, +)
        reduced.expectComplete(after: [6])
    }

    func testZipPrevious() {
        let operation = Signal<Int, TestError>(sequence: [1, 2, 3])
        let zipped = operation.zipPrevious()
        zipped.expectComplete(after: [(nil, 1), (1, 2), (2, 3)])
    }

    func testFlatMapMerge() {
        let bob = Scheduler()
        let eves = [Scheduler(), Scheduler()]

        let operation = Signal<Int, TestError>(sequence: [1, 2]).observeIn(bob.context)
        let merged = operation.flatMapMerge { num in
            return Signal<Int, TestError>(sequence: [5, 6].map { $0 * num }).observeIn(eves[num-1].context)
        }

        let exp = expectation(description: "completed")
        merged.expectAsyncComplete(after: [5, 10, 12, 6], expectation: exp)

        bob.runOne()
        eves[0].runOne()
        bob.runRemaining()
        eves[1].runRemaining()
        eves[0].runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFlatMapLatest() {
        let bob = Scheduler()
        let eves = [Scheduler(), Scheduler()]

        let operation = Signal<Int, TestError>(sequence: [1, 2]).observeIn(bob.context)
        let merged = operation.flatMapLatest { num in
            return Signal<Int, TestError>(sequence: [5, 6].map { $0 * num }).observeIn(eves[num-1].context)
        }

        let exp = expectation(description: "completed")
        merged.expectAsyncComplete(after: [5, 10, 12], expectation: exp)

        bob.runOne()
        eves[0].runOne()
        bob.runRemaining()
        eves[1].runRemaining()
        eves[0].runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFlatMapConcat() {
        let bob = Scheduler()
        let eves = [Scheduler(), Scheduler()]

        let operation = Signal<Int, TestError>(sequence: [1, 2]).observeIn(bob.context)
        let merged = operation.flatMapConcat { num in
            return Signal<Int, TestError>(sequence: [5, 6].map { $0 * num }).observeIn(eves[num-1].context)
        }

        let exp = expectation(description: "completed")
        merged.expectAsyncComplete(after: [5, 6, 10, 12], expectation: exp)

        bob.runRemaining()
        eves[1].runOne()
        eves[0].runRemaining()
        eves[1].runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testReplay() {
        let bob = Scheduler()
        bob.runRemaining()

        let operation = Signal<Int, TestError>(sequence: [1, 2, 3]).executeIn(bob.context)
        let replayed = operation.replay(limit: 2)

        operation.expectComplete(after: [1, 2, 3])
        let _ = replayed.connect()
        replayed.expectComplete(after: [2, 3])
        XCTAssertEqual(bob.numberOfRuns, 2)
    }

    func testReplayLatestWith() {
        let bob = Scheduler()
        let eve = Scheduler()

        let a = Signal<Int, TestError>(sequence: [1, 2, 3]).observeIn(bob.context)
        let b = Signal<String, Never>(sequence: ["A", "A", "A", "A", "A"]).observeIn(eve.context)
        let combined = a.replayLatest(when: b)

        let exp = expectation(description: "completed")
        combined.expectAsyncComplete(after: [1, 2, 2, 2, 3, 3], expectation: exp)

        eve.runOne()
        eve.runOne()
        bob.runOne()
        bob.runOne()
        eve.runOne()
        eve.runOne()
        bob.runOne()
        eve.runRemaining()
        bob.runRemaining()

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testPublish() {
        let bob = Scheduler()
        bob.runRemaining()

        let operation = Signal<Int, TestError>(sequence: [1, 2, 3]).executeIn(bob.context)
        let published = operation.publish()

        operation.expectComplete(after: [1, 2, 3])
        let _ = published.connect()
        published.expectNoEvent()

        XCTAssertEqual(bob.numberOfRuns, 2)
    }

    #if  os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    func testBindTo() {

        class User: NSObject, BindingExecutionContextProvider {

            var age: Int = 0

            var bindingExecutionContext: ExecutionContext {
                return .immediate
            }
        }

        let user = User()

        SafeSignal(just: 20).bind(to: user) { (object, value) in object.age = value }
        XCTAssertEqual(user.age, 20)

        SafeSignal(just: 30).bind(to: user, keyPath: \.age)
        XCTAssertEqual(user.age, 30)
    }
    #endif
}

extension SignalTests {

    static var allTests : [(String, (SignalTests) -> () -> Void)] {
        return [
            ("testPerformance", testPerformance),
            ("testProductionAndObservation", testProductionAndObservation),
            ("testDisposing", testDisposing),
            ("testJust", testJust),
            ("testSequence", testSequence),
            ("testCompleted", testCompleted),
            ("testNever", testNever),
            ("testFailed", testFailed),
            ("testObserveFailed", testObserveFailed),
            ("testObserveCompleted", testObserveCompleted),
            ("testBuffer", testBuffer),
            ("testMap", testMap),
            ("testScan", testScan),
            ("testToSignal", testToSignal),
            ("testSuppressError", testSuppressError),
            ("testSuppressError2", testSuppressError2),
            ("testRecover", testRecover),
            ("testWindow", testWindow),
            ("testDistinct", testDistinct),
            ("testDistinct2", testDistinct2),
            ("testElementAt", testElementAt),
            ("testFilter", testFilter),
            ("testFirst", testFirst),
            ("testIgnoreElement", testIgnoreElement),
            ("testLast", testLast),
            ("testSkip", testSkip),
            ("testSkipLast", testSkipLast),
            ("testTakeFirst", testTakeFirst),
            ("testTakeLast", testTakeLast),
            ("testIgnoreNils", testIgnoreNils),
            ("testReplaceNils", testReplaceNils),
            ("testCombineLatestWith", testCombineLatestWith),
            ("testMergeWith", testMergeWith),
            ("testStartWith", testStartWith),
            ("testZipWith", testZipWith),
            ("testZipWithWhenNotComplete", testZipWithWhenNotComplete),
            ("testZipWithWhenNotComplete2", testZipWithWhenNotComplete2),
            ("testZipWithAsyncSignal", testZipWithAsyncSignal),
            ("testFlatMapError", testFlatMapError),
            ("testFlatMapError2", testFlatMapError2),
            ("testRetry", testRetry),
            ("testexecuteIn", testexecuteIn),
            ("testDoOn", testDoOn),
            ("testobserveIn", testobserveIn),
            ("testPausable", testPausable),
            ("testTimeoutNoFailure", testTimeoutNoFailure),
            ("testTimeoutFailure", testTimeoutFailure),
            ("testAmbWith", testAmbWith),
            ("testCollect", testCollect),
            ("testConcatWith", testConcatWith),
            ("testDefaultIfEmpty", testDefaultIfEmpty),
            ("testReduce", testReduce),
            ("testZipPrevious", testZipPrevious),
            ("testFlatMapMerge", testFlatMapMerge),
            ("testFlatMapLatest", testFlatMapLatest),
            ("testFlatMapConcat", testFlatMapConcat),
            ("testReplay", testReplay),
            ("testPublish", testPublish),
            ("testReplayLatestWith", testReplayLatestWith)
        ]
    }
}
