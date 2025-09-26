import Foundation

public protocol MNResponseProtocol: Decodable {
    associatedtype Data: Decodable
    var code: String { get }
    var status: Int { get }
    var msg: String { get }
    var data: Data? { get }
    var timestamp: String { get }
}

public extension MNResponseProtocol {
    var isSuccess: Bool  {
        // code == "000000"
        return code == "000000"
    }
        
    var errorDescription: String? {
        return msg
    }
}