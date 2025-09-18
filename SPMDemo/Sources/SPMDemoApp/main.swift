import SPMDemo

// 使用C语言实现的计算器功能
let a = 10.0
let b = 5.0

print("\n=== 测试C语言计算器功能 ===")
print("\(a) + \(b) = \(Calculator.add(a, b))")
print("\(a) - \(b) = \(Calculator.subtract(a, b))")
print("\(a) * \(b) = \(Calculator.multiply(a, b))")
print("\(a) / \(b) = \(Calculator.divide(a, b))")
print("\(a) / 0 = \(Calculator.divide(a, 0))") // 测试除零情况

print("\n=== 测试打印功能 ===")
// 使用类方法
Printer.printMessage("Hello from Printer class!")

// 使用便捷函数
demoPrint("Hello from demoPrint function!")

// 也可以保留原始的print语句作为比较
print("Hello, world!")