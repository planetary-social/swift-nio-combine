import Foundation
import Combine
import NIO

///

extension NetworkTransferSubject: Cancellable {
    
    ///
    
    public func cancel() {
        writing.send(completion: .finished)
    }
    
}
