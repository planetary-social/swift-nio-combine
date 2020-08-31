import Foundation
import Combine
import OSLog

///

extension NetworkTransferSubject: Subject {
    
    ///
    
    public typealias Output = Data
    
    ///
    
    public func send(_ value: Data) {
        guard !value.isEmpty else {
            os_log(.debug, log: status, "dropping an empty packet!")
            return
        }

        os_log(.debug, log: status, "sending a packet of %d bytes...", value.count)
        writing.send(value)
    }
    
    ///
    
    public func send(completion: Subscribers.Completion<Failure>) {
        reading.send(completion: completion)
    }
    
    ///
    
    public func send(subscription: Subscription) { // XXX: What does this do?
        reading.send(subscription: subscription)
    }

}
