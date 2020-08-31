extension NetworkTransferSubject {

    ///

    public enum Malfunction: Error, Equatable {
        case packetCorrupted
        case packetDeliveryFailed
    }

}
