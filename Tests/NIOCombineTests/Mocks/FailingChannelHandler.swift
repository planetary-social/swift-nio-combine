import Foundation
import NIO

///

final class FailingChannelHandler: ChannelDuplexHandler {

    ///

    typealias InboundIn   = ByteBuffer
    typealias InboundOut  = ByteBuffer
    typealias OutboundIn  = ByteBuffer
    typealias OutboundOut = ByteBuffer

    ///

    var caughtFailure: NSError?

    ///

    var failOnRead = false
    var failOnSend = false // FIXME: Unused

    ///

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if let failure = caughtFailure {
            return context.fireErrorCaught(failure)
        }

        if failOnRead {
            return context.fireChannelRead(wrapOutboundOut(ByteBuffer()))
        }

        context.fireChannelRead(data)
    }

}
