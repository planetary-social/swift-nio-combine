extension NetworkTransferSubject {

    ///

    public enum Failure: Error {
        case connectionProblem(Error)
    }

}
