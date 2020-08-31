import Foundation
import Combine
import NIO
import XCTest

@testable import NIOCombine

final class NetworkTransferSubjectPerformanceTests: XCTestCase {

    ///

    func test_Latency_ofWriting() throws {
        throw XCTSkip("TODO: Reading speed should be predictable.")
    }

    ///

    func test_Latency_ofReading() throws {
        throw XCTSkip("TODO: Writing speed should be predictable as well.")
    }

    ///

    func test_OverallThroughput_usingConstantPredictablePackets() throws {
        throw XCTSkip("TODO: Overall transfer speed should be predictable in an organised environment.")
    }

    ///

    func test_OverallThroughput_usingChaoticallySizedPackets() throws {
        throw XCTSkip("TODO: Overall transfer speed should be predictable even among chaos.")
    }

}
