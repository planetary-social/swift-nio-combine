import Foundation
import Combine
import os

///

extension NetworkTransferSubject: Publisher {
    
    ///
    
    public func receive<S>(subscriber: S)
    where S: Subscriber, Failure == S.Failure, Output == S.Input {
        reading.receive(subscriber: subscriber)
    }
    
}
