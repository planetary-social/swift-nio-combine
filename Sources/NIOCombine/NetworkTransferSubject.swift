import Foundation
import Combine
import OSLog
import NIO

#if os(iOS) || os(macOS)
import NIOTransportServices
#endif

///

public class NetworkTransferSubject: ChannelInboundHandler {

    ///
    
    public typealias InboundIn = ByteBuffer

    ///
    
    public typealias OutboundOut = ByteBuffer

    ///
    
    internal let reading = PassthroughSubject<Data, Failure>()
    internal let writing = PassthroughSubject<Data, Failure>()
    internal var closing = PassthroughSubject<Void, Never>()

    ///
    
    internal var services: [Cancellable] = []

    ///

    internal var writes = DispatchQueue(label: "\(OSLog.thisSubsystem).writes",
                                        qos: .background) // XXX: Consider concurrent!

    ///

    internal var status = OSLog.networkTransfer

    ///

    internal static var pointsOfInterest = (
        ConnectionActive: StaticString("ConnectionActive"),
        PacketRead: StaticString("PacketRead")
    )

    ///

    public func channelActive(context: ChannelHandlerContext) {
        os_log(.debug, log: status, "establishing connection with %@...",
               String(describing: context.remoteAddress))

        let channel = context.channel

        services.append(
            writing
            .receive(on: writes)
            .assertNoFailure() // XXX: Impossible to fail!
            .handleEvents(receiveCompletion: { _ in self.finish(context: context) })
            .sink { self.writeAndFlush(packet: $0, to: channel) })

        os_signpost(.begin, log: status, name: Self.pointsOfInterest.ConnectionActive,
                    "connected to %@", String(describing: context.remoteAddress))
    }

    ///

    public func channelInactive(context: ChannelHandlerContext) {
        os_log(.debug, log: status, "disconnected from %@", String(describing: context.remoteAddress))
        cancel()
    }

    ///

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        os_signpost(.begin, log: status, name: Self.pointsOfInterest.PacketRead,
                    "incoming data from %@", String(describing: context.remoteAddress))

        var buffer = self.unwrapInboundIn(data)

        guard
            buffer.readableBytes > 0,
            let packet = buffer.readBytes(length: buffer.readableBytes)
        else {
            errorCaught(context: context, error: Malfunction.packetCorrupted)
            return
        }

        reading.send(Data(packet))

        os_signpost(.end, log: status, name: Self.pointsOfInterest.PacketRead, "packet accepted")
        os_log(.debug, log: status, "received a packet of %d bytes", packet.count)
    }

    ///

    internal func writeAndFlush(packet: Data, to channel: Channel) {
        let payload = channel.allocator.buffer(bytes: packet)

        _ = channel
            .writeAndFlush(wrapOutboundOut(payload))
            .map {
                os_log(.debug, log: self.status, "delivered %d bytes", packet.count)
            }
            .recover {
                os_log(.error, log: self.status, "write failed: %@", String(describing: $0))
                self.send(completion: .failure(.connectionProblem(Malfunction.packetDeliveryFailed)))
            }
    }

    ///

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        os_log(.error, log: status, "caught a connection problem: %@", String(describing: error))
        send(completion: .failure(.connectionProblem(error)))
    }


    ///

    private func finish(context: ChannelHandlerContext) {
        writes.async(flags: .barrier) {
            self.send(completion: .finished)
            os_signpost(.end, log: self.status, name: Self.pointsOfInterest.ConnectionActive, "finished")
        }
    }

    ///

    deinit {
        services.forEach { $0.cancel() }
    }

}
