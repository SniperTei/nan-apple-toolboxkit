import MNLoggerModule

class MNAppCore: @unchecked Sendable {
    static let shared = MNAppCore()
    private init() {
        MNDebug("MNAppCore", "初始化")
    }
    func test() {
        MNDebug("MNAppCore", "测试")
    }
}