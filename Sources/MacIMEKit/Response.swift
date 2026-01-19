public enum ResponseStatus {
   case ok, err
}
public struct Response {
   public var status: ResponseStatus
   public var content: String
}
