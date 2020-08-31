import Foundation
import Combine
import NIO
import XCTest

//

@testable import NIOCombine

///

final class NetworkTransferSubject_TransportTests: XCTestCase {

    ///

    var events: EventLoopGroup?

    ///

    var lock = DispatchSemaphore(value: 1)

    ///

    var serverSubject, clientSubject: NetworkTransferSubject?

    ///

    var server, client: Channel?

    ///

    var endpoint = try! SocketAddress(ipAddress: "0.0.0.0", port: arbitraryPort)

    ///

    static var arbitraryPort: Int { .random(in: 50000...51000) }

    ///

    var arbitraryPacketSizeBounds: ClosedRange<Int> = 2...1024

    ///

    var arbitraryPacket: Data {
        Data((1...Int.random(in: arbitraryPacketSizeBounds)).map { _ in
            return UInt8.random(in: UInt8.min...UInt8.max)
        })
    }

    ///

    var waitTime: TimeInterval = 5

    ///

    var failingChannelHandler: FailingChannelHandler?

    ///

    static func arbitrarySubject(for label: String) ->  NetworkTransferSubject { // FIXME: label, remove probably
        return NetworkTransferSubject()
    }

    ///

    override func setUpWithError() throws {
        lock.wait()

        events = MultiThreadedEventLoopGroup(numberOfThreads: 2)

        failingChannelHandler = FailingChannelHandler()

        serverSubject = Self.arbitrarySubject(for: "server")
        clientSubject = Self.arbitrarySubject(for: "client")

        server = try setUp_NIOServer()
        client = try setUp_NIOClient()
    }

    ///

    func setUp_NIOServer() throws -> Channel {
        try ServerBootstrap(group: events!)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                return channel.pipeline.addHandler(self.serverSubject!)
            }
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .bind(to: endpoint)
            .wait()
    }

    ///

    func setUp_NIOClient() throws -> Channel {
        try ClientBootstrap(group: events!)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(self.failingChannelHandler!).flatMap { _ in
                    channel.pipeline.addHandler(self.clientSubject!)
                }
            }
            .connect(to: endpoint)
            .wait()
    }
    
    ///
    
    override func tearDownWithError() throws {
        defer { lock.signal() }

        for channel in [client, server] { try channel?.close().wait() }
        for subject in [clientSubject, serverSubject] { subject?.cancel() }

        try events?.syncShutdownGracefully()
        events = nil

        serverSubject = nil
        clientSubject = nil

        failingChannelHandler = nil
    }
    
    ///
    
    func test_Sending_networkPackets() {
        let expectReceive = expectation(description: "expected to receive packet on the server side")
        let packet = arbitraryPacket
        let wait = serverSubject?.assertNoFailure().sink { receivedPacket in
            XCTAssertEqual(receivedPacket, packet)
            expectReceive.fulfill()
        }

        clientSubject?.send(packet)
        clientSubject?.send(Data()) // NOTE: Empty packets should be dropped.

        waitForExpectations(timeout: waitTime) { _ in
            wait?.cancel()
        }
    }
    
    ///
    
    func test_Reading_networkPackets() {
        let expectReceive = expectation(description: "expected to receive packet on the client side")
        let packet = arbitraryPacket
        let wait = clientSubject?.assertNoFailure().sink { receivedPacket in
            XCTAssertEqual(receivedPacket, packet)
            expectReceive.fulfill()
        }

        serverSubject?.send(packet)

        waitForExpectations(timeout: waitTime) { _ in
            wait?.cancel()
        }
    }
    
    ///
    
    func test_Cancellation_causedByLocalRequest() {
        let expectedCompletion = expectation(description: "client must receive completion")

        let wait =
            clientSubject?
            .handleEvents(receiveCompletion: { _ in expectedCompletion.fulfill() })
            .assertNoFailure()
            .sink { _ in }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.clientSubject?.cancel()
        }

        waitForExpectations(timeout: waitTime) { _ in
            wait?.cancel()
        }
    }

    ///

    func test_Cancellation_causedByRemoteConnectionReset() {
        let expectedCompletion = expectation(description: "server must receive completion")

        let wait =
            clientSubject?
            .handleEvents(receiveCompletion: { _ in expectedCompletion.fulfill() })
            .assertNoFailure()
            .sink { _ in }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.client?.close().whenComplete { _ in
                self.client = nil
            }
        }

        waitForExpectations(timeout: waitTime) { _ in
            wait?.cancel()
        }
    }

    ///

    func test_Failure_simulatingCaughtError() {
        let expectedError = expectation(description: "client must fail")
        failingChannelHandler!.caughtFailure = NSError(domain: "example.error", code: 191)

        let wait =
            clientSubject?
            .catch { error -> Empty<Data, Never> in
                if case .connectionProblem(let failure) = error {
                    XCTAssertEqual(failure as NSError, self.failingChannelHandler!.caughtFailure)
                    expectedError.fulfill()
                }

                return .init()
            }
            .sink { _ in }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.serverSubject?.send(self.arbitraryPacket)
        }

        waitForExpectations(timeout: waitTime) { _ in
            wait?.cancel()
        }
    }

    ///

    func test_Failure_simulatingReceiveProblem() {
        let expectedError = expectation(description: "client must fail")
        failingChannelHandler!.failOnRead = true

        let wait =
            clientSubject?
            .catch { error -> Empty<Data, Never> in
                print(error)
                if case .connectionProblem(NetworkTransferSubject.Malfunction.packetCorrupted) = error {
                    expectedError.fulfill()
                }

                return .init()
            }
            .sink { _ in }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.serverSubject?.send(self.arbitraryPacket)
        }

        waitForExpectations(timeout: waitTime) { _ in
            wait?.cancel()
        }
    }

    ///

    func test_Failure_simulatingWriteAndFlushProblem() throws {
        throw XCTSkip("It is not trivial to simulate broken writes...")
    }

}
