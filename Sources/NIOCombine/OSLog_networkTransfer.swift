import OSLog

///

extension OSLog {

    ///

    internal static var thisSubsystem = "social.planetary.NIOCombine"

    ///

    static let networkTransfer = OSLog(subsystem: thisSubsystem, category: "NetworkTransferSubject")

}
