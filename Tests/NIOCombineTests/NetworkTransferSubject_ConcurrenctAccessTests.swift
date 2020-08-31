import Foundation
import Combine
import NIO
import XCTest

@testable import NIOCombine

final class NetworkTransferSubject_ConcurrentAccessTests: XCTestCase {

    ///

    func test_Sending_fromMultipleSimultaneousClients() throws {
        throw XCTSkip("TODO: Make sure multiple clients can send at the same time without races.")
    }

    ///

    func test_Receiving_byMultipleSimultaneousClients() throws {
        throw XCTSkip("TODO: Make sure multiple clients can read witho race conditions.")
    }

}
