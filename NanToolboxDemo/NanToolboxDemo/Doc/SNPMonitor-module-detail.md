# SNPMonitor 模块详细说明

## 📁 模块结构

```
SNPMonitor/
├── SNPCrashMonitor.swift          # 核心崩溃监控器
├── Models/
│   ├── SNPCrashModel.swift        # 崩溃信息模型
│   └── DeviceInfo.swift           # 设备信息模型
├── Protocols/
│   └── SNPCrashMonitorDelegate.swift  # 崩溃监控代理协议
└── Utils/
    └── SNPSignalHandler.swift     # 信号处理器
```

## 🏗️ 架构设计

### 1. 核心组件

#### SNPCrashMonitor (崩溃监控器)
- **职责**：统一管理崩溃监控功能
- **设计模式**：单例模式 + 代理模式
- **功能**：
  - 启动/停止崩溃监控
  - 处理异常崩溃
  - 处理信号崩溃
  - 集成日志记录
  - 通知代理对象

#### SNPSignalHandler (信号处理器)
- **职责**：处理系统信号崩溃
- **设计模式**：单例模式
- **功能**：
  - 设置信号处理器
  - 移除信号处理器
  - 支持多种信号类型

### 2. 数据模型

#### SNPCrashModel (崩溃信息模型)
```swift
public struct SNPCrashModel {
    public let type: CrashType           // 崩溃类型
    public let name: String              // 崩溃名称
    public let reason: String            // 崩溃原因
    public let callStackSymbols: [String] // 调用栈
    public let timestamp: TimeInterval   // 时间戳
    public let deviceInfo: DeviceInfo    // 设备信息
}
```

#### CrashType (崩溃类型枚举)
```swift
public enum CrashType {
    case exception(NSException)  // 异常崩溃
    case signal(Int32)           // 信号崩溃
}
```

#### DeviceInfo (设备信息模型)
```swift
public struct DeviceInfo {
    public let deviceId: String      // 设备ID
    public let appVersion: String    // 应用版本
    public let deviceModel: String   // 设备型号
    public let osVersion: String     // 系统版本
    
    public static var current: DeviceInfo  // 当前设备信息
}
```

### 3. 协议定义

#### SNPUncaughtExceptionHandlerDelegate
```swift
public protocol SNPUncaughtExceptionHandlerDelegate: AnyObject {
    func crashMonitor(_ monitor: SNPCrashMonitor, didCatchCrash crash: SNPCrashModel)
}
```

## 🔧 核心功能

### 1. 异常崩溃监控

**监控原理**：
- 使用 `NSSetUncaughtExceptionHandler` 设置全局异常处理器
- 捕获 `NSException` 类型的崩溃

**处理流程**：
1. 设置全局异常处理函数
2. 捕获异常时记录详细日志
3. 创建崩溃模型对象
4. 通知代理对象
5. 写入日志文件

**支持的异常类型**：
- 数组越界
- 空指针解包
- 类型转换错误
- 其他 Objective-C 异常

### 2. 信号崩溃监控

**监控原理**：
- 使用 `sigaction` 系统调用设置信号处理器
- 捕获系统信号导致的崩溃

**支持的信号类型**：
- `SIGABRT` - 程序异常终止
- `SIGILL` - 非法指令
- `SIGSEGV` - 段错误（内存访问错误）
- `SIGFPE` - 浮点异常
- `SIGBUS` - 总线错误
- `SIGPIPE` - 管道破裂
- `SIGTRAP` - 跟踪陷阱

**处理流程**：
1. 设置信号处理器
2. 捕获信号时记录详细日志
3. 创建崩溃模型对象
4. 通知代理对象
5. 恢复默认信号处理
6. 写入日志文件

### 3. 日志集成

**日志类型**：
- 使用专门的 `.crash` 日志类型
- 记录崩溃的详细信息

**日志内容**：
- 崩溃类型和描述
- 异常名称和原因
- 完整调用栈
- 设备信息
- 时间戳

## 🚀 使用方法

### 1. 基本使用

```swift
// 设置代理
SNPCrashMonitor.shared.delegate = self

// 启动监控
SNPCrashMonitor.shared.startMonitoring()

// 停止监控
SNPCrashMonitor.shared.stopMonitoring()
```

### 2. 实现代理方法

```swift
extension YourViewController: SNPUncaughtExceptionHandlerDelegate {
    func crashMonitor(_ monitor: SNPCrashMonitor, didCatchCrash crash: SNPCrashModel) {
        // 处理崩溃信息
        print("捕获到崩溃：\(crash.reason)")
        
        // 记录到日志
        SNPLogManager.shared.writeLog(
            log: crash.description,
            type: .crash
        )
    }
}
```

### 3. 手动记录崩溃信息

```swift
// 记录自定义崩溃信息
SNPCrashMonitor.shared.logCrashInfo([
    "error": "自定义错误",
    "context": "错误上下文"
])
```

## 🔍 技术细节

### 1. 全局函数设计

**问题**：C函数指针不能捕获上下文
**解决方案**：
- 使用全局变量存储监控器实例
- 使用全局函数处理异常和信号
- 避免闭包捕获上下文

```swift
// 全局变量
private var globalCrashMonitor: SNPCrashMonitor?

// 全局异常处理函数
private func globalExceptionHandler(exception: NSException) {
    globalCrashMonitor?.handleException(exception)
}
```

### 2. 内存管理

**弱引用**：
- 代理使用 `weak` 引用避免循环引用
- 信号处理器使用 `[weak self]` 避免内存泄漏

**资源清理**：
- 停止监控时清除全局引用
- 移除信号处理器
- 关闭文件句柄

### 3. 线程安全

**异步处理**：
- 日志写入使用专用队列
- UI更新在主线程执行
- 信号处理在系统线程执行

## 📊 监控能力

### 1. 崩溃类型覆盖

- ✅ **异常崩溃**：NSException 类型
- ✅ **信号崩溃**：系统信号类型
- ✅ **内存错误**：SIGSEGV, SIGBUS
- ✅ **程序错误**：SIGABRT, SIGILL
- ✅ **计算错误**：SIGFPE
- ✅ **其他错误**：SIGPIPE, SIGTRAP

### 2. 信息收集

- ✅ **崩溃类型**：异常或信号
- ✅ **崩溃原因**：详细错误信息
- ✅ **调用栈**：完整的堆栈跟踪
- ✅ **设备信息**：设备型号、系统版本
- ✅ **应用信息**：应用版本、设备ID
- ✅ **时间信息**：精确的时间戳

### 3. 日志记录

- ✅ **统一日志**：集成到现有日志系统
- ✅ **分类记录**：使用专门的崩溃日志类型
- ✅ **详细信息**：包含完整的崩溃上下文
- ✅ **文件存储**：持久化到日志文件

## 🛡️ 安全考虑

### 1. 数据安全

- 崩溃信息包含敏感数据（调用栈）
- 建议加密存储或限制访问权限
- 生产环境中注意日志文件的安全

### 2. 性能影响

- 监控器对性能影响极小
- 只在崩溃时执行处理逻辑
- 日志写入使用异步队列

### 3. 稳定性

- 使用全局函数避免崩溃
- 异常处理确保监控器稳定运行
- 资源清理防止内存泄漏

## 🔮 扩展性

### 1. 可扩展的架构

- 模块化设计便于扩展
- 代理模式支持多种处理方式
- 可以轻松添加新的崩溃类型

### 2. 未来功能

- 崩溃报告上传
- 崩溃统计分析
- 自动修复建议
- 性能监控集成

## 📝 最佳实践

### 1. 使用建议

- 在应用启动时初始化监控器
- 实现代理方法处理崩溃信息
- 定期检查和分析崩溃日志
- 根据崩溃信息优化应用

### 2. 注意事项

- 不要在崩溃处理中执行复杂操作
- 避免在崩溃回调中访问UI
- 及时清理旧的崩溃日志
- 测试各种崩溃场景

这个SNPMonitor模块提供了一个完整、稳定、可扩展的崩溃监控解决方案，能够有效捕获和分析应用崩溃，帮助开发者快速定位和解决问题。 