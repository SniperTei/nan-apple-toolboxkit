// The Swift Programming Language
// https://docs.swift.org/swift-book

// 导入C语言函数
import Foundation
import CalculatorCore // 导入C语言核心模块

/// 提供打印功能的工具类
public class Printer {
    /// 打印指定的消息
    /// - Parameter message: 要打印的消息内容
    public class func printMessage(_ message: String) {
        print("[SPMDemo] " + message)
    }
}

/// 便捷的全局打印函数
/// - Parameter message: 要打印的消息内容
public func demoPrint(_ message: String) {
    Printer.printMessage(message)
}

/// 计算器工具类，封装C语言的加减乘除功能
public class Calculator {
    /// 加法计算
    /// - Parameters:
    ///   - a: 第一个操作数
    ///   - b: 第二个操作数
    /// - Returns: 计算结果
    public class func add(_ a: Double, _ b: Double) -> Double {
        return addC(a, b) // 直接调用C函数
    }
    
    /// 减法计算
    /// - Parameters:
    ///   - a: 被减数
    ///   - b: 减数
    /// - Returns: 计算结果
    public class func subtract(_ a: Double, _ b: Double) -> Double {
        return subtractC(a, b) // 直接调用C函数
    }
    
    /// 乘法计算
    /// - Parameters:
    ///   - a: 第一个因数
    ///   - b: 第二个因数
    /// - Returns: 计算结果
    public class func multiply(_ a: Double, _ b: Double) -> Double {
        return multiplyC(a, b) // 直接调用C函数
    }
    
    /// 除法计算
    /// - Parameters:
    ///   - a: 被除数
    ///   - b: 除数
    /// - Returns: 计算结果，如果除数为0则返回0
    public class func divide(_ a: Double, _ b: Double) -> Double {
        return divideC(a, b) // 直接调用C函数
    }
}

