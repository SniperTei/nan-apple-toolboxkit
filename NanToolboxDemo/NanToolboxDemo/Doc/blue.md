# 外设读卡读证接口文档

## 1. 基础信息

### 1.1 通用说明
- 所有接口采用异步回调方式
- 错误码统一格式：`E + 5位数字`
- 所有指令执行都有超时机制，默认超时时间为30秒
- 所有接口返回数据统一格式：

```json
{
  "code": "000000",        // 响应代码：成功="000000"，失败=其他
  "msg": "Success",        // 响应消息
  "data": object          // 响应数据，失败时可能为null
}
```

### 1.2 错误码说明
| 错误码 | 说明 |
|--------|------|
| 000000 | 成功 |
| E10001 | 蓝牙未开启 |
| E10002 | 设备未连接 |
| ... | ... |

## 2. 设备连接管理

### 2.1 扫描设备
**方法名**: 
`startScan(DeviceScanCallback callback)`

**参数**:

```json
{
  "timeout": 10000,        // 扫描超时时间，单位毫秒，默认10秒
  "namePrefix": "string",  // 设备名前缀，可选
}
```

**回调方法**: `DeviceScanCallback.onScanResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "devices": [{
      "deviceId": "string",      // 设备ID
      "name": "string",          // 设备名称
      "model": "string",         // 型号
      "manufactor": "string"     // 厂商
    }]
  }
}
```

### 2.2 停止扫描
**方法名**: `stopScan(DeviceStopScanCallback callback)`

**回调方法**: `DeviceStopScanCallback.onStopScanResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "scanStatus": "stopped"  // 扫描状态：stopped
  }
}
```

### 2.3 连接设备
**方法名**: `connect(ConnectConfig config, DeviceConnectCallback callback)`

**参数**:

```json
{
  "deviceId": "string",    // 设备ID
  "timeout": 5000         // 连接超时时间，单位毫秒，默认5秒
}
```

**回调方法**: `DeviceConnectCallback.onConnectResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "deviceId": "string",    // 设备ID
    "status": "connected"    // 连接状态：connected/disconnected
  }
}
```

### 2.4 断开连接
**方法名**: `disconnect(DeviceDisconnectCallback callback)`

**回调方法**: `DeviceDisconnectCallback.onDisconnectResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "deviceId": "string",    // 设备ID
    "status": "disconnected" // 连接状态
  }
}
```


## 3. 银行卡操作

### 3.1 读取银行卡
**方法名**: `readBankCard(ReadBankCardConfig config, BankCardReadCallback callback)`

**参数**:

```json
{
  "timeout": 30000,        // 读卡超时时间，默认30秒
  "readMode": "string"     // 读取模式：NFC(非接)/IC(插入)/MAG(刷卡)
}
```

**回调方法**: `BankCardReadCallback.onBankCardResult`

**回调数据**:

```json
{
  "code": "000000",             // 响应代码
  "msg": "Success",             // 响应消息
  "data": {
    "cardNo": "string",         // 卡号
    "expiryDate": "string",     // 有效期
    	...
  }
}
```

## 4. 证件操作

### 4.1 读取证件
**方法名**: `readCard(ReadCardConfig config, CardReadCallback callback)`

**参数**:

```json
{
  "timeout": 30000,        // 读证超时时间，默认30秒
  "readMode": "string",    // 读取模式：NFC(非接)/INSERTION(吸入式)/AUTO(自动)
}
```

**回调方法**: `CardReadCallback.onCardResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    // 基础信息（所有类型通用）
    "cardType": "string",        // 证件类型
    "readMode": "string",        // 实际读取模式
    
    // 身份证/外国人永久居留证信息
    "cardNumber": "string",      // 证件号码
    "name": "string",            // 姓名（中文）
    "englishName": "string",     // 英文姓名（外国人证件特有）
    "gender": "string",          // 性别
    "birthday": "string",        // 出生日期
    "address": "string",         // 地址/居留地址
    "nation": "string",          // 民族（身份证特有）
    "nationality": "string",     // 国籍（外国人证件特有）
    "issueAuthority": "string",  // 签发机关
    "issueDate": "string",       // 签发日期
    "validFrom": "string",       // 有效期起始日期
    "validTo": "string",         // 有效期截止日期
    "photoBase64": "string",     // 证件照片(Base64)
    ...
    
    // 额外数据
    "extraData": {               // 额外数据
      "key": "value"
    }
  }
}
```

## 5. RFID操作

### 5.1 读取RFID
**方法名**: `readRFID(ReadRFIDConfig config, RFIDCallback callback)`

**参数**:
```json
{
  "block": number,         // 块号
}
```

**回调数据**:
```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "block": number,       // 块号
    "data": "hex",         // 读取的数据
    "length": number       // 数据长度
  }
}
```

### 5.2 写入RFID数据
**方法名**: `writeRFID`

**参数**:

```json
{
  "block": number,       // 块号
  "data": "hex",        // 写入数据
}
```

### 5.3 锁定RFID
**方法名**: `lockRFID`

**参数**:

```json
{
  "block": number,       // 块号
}
```

### 5.4 读取AFI
**方法名**: `readAFI(RFIDCallback callback)`

**回调数据**:
```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "value": "hex"         // AFI值
  }
}
```

### 5.5 写入AFI
**方法名**: `writeAFI`

**参数**:

```json
{
  "value": "hex",        // AFI值
}
```

## 6. 指令操作

### 6.1 执行APDU指令
**方法名**: `executeAPDU`

**参数**:

```json
{
  "command": "hex",      // APDU指令
  "timeout": 5000       // 超时时间，默认5秒
}
```

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "response": "hex",     // 响应数据
    "sw1": "hex",         // 状态字1
    "sw2": "hex"          // 状态字2
  }
}
```

### 6.2 执行脚本
**方法名**: `executeScript`

**参数**:

```json
{
  "script": "string",    // 脚本内容
  "params": {           // 脚本参数
    "key": "value"
  },
  "timeout": 30000      // 超时时间，默认30秒
}
```

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "result": "string",    // 执行结果
    "output": "string",    // 输出信息
    "error": "string"      // 错误信息
  }
}
```

## 7. 设备信息

### 7.1 获取设备信息
**方法名**: `getDeviceInfo`

**参数**: 无

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "manufacturer": "string",   // 制造商
    "model": "string",         // 型号
    "serialNumber": "string",  // 序列号
    "firmwareVersion": "string", // 固件版本
    "hardwareVersion": "string", // 硬件版本
    "batteryLevel": number,    // 电池电量
    "supportedFeatures": ["string"] // 支持的功能列表
  }
}
```

### 7.2 获取设备状态
**方法名**: `getDeviceStatus(DeviceStatusCallback callback)`

**回调方法**: `DeviceStatusCallback.onDeviceStatusResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    // 基础信息
    "deviceId": "string",       // 设备ID
    "manufacturer": "string",   // 制造商
    "model": "string",         // 设备型号
    "serialNumber": "string",  // 序列号
    "firmwareVersion": "string", // 固件版本
    
    // 连接状态
    "connectionStatus": "string", // 连接状态：connected/disconnected
    "rssi": number,              // 信号强度（蓝牙设备）
    "lastConnectTime": "string", // 最近连接时间
    
    // 电源信息
    "batteryLevel": number,      // 电池电量（0-100）
    "charging": boolean,         // 是否正在充电
    "temperature": number,       // 设备温度
    
    // 功能模块状态
    "modules": {
      "bankCard": {              // 银行卡模块
        "status": "string",      // 状态：normal/error/unsupported
        "errorCode": "string",   // 错误代码（如果有）
        "supportedModes": [      // 支持的读卡模式
          "NFC",                 // 非接模式
          "IC",                  // 插卡模式
          "MAG"                  // 刷卡模式
        ]
      },
      "idCard": {                // 证件模块
        "status": "string",      // 状态：normal/error/unsupported
        "errorCode": "string",   // 错误代码（如果有）
        "supportedTypes": [      // 支持的证件类型
          "ID_CARD",             // 身份证
          "FOREIGN_PERMANENT",   // 外国人永久居留证
          "TRAVEL_DOC"          // 出入境证件
        ],
        "supportedModes": [      // 支持的读取模式
          "NFC",                 // 非接模式
          "INSERTION"           // 吸入式
        ]
      },
      "rfid": {                  // RFID模块
        "status": "string",      // 状态：normal/error/unsupported
        "errorCode": "string",   // 错误代码（如果有）
        "supportedFeatures": [   // 支持的功能
          "READ",               // 读取
          "WRITE",             // 写入
          "LOCK"               // 锁定
        ]
      }
    },
    
    // 当前操作状态
    "currentOperation": {
      "type": "string",          // 操作类型
      "startTime": "string",     // 开始时间
      "status": "string"         // 状态：idle/busy/error
    }
  }
}
```

## 8. 指纹操作

### 8.1 读取指纹
**方法名**: `readFingerprint(ReadFingerprintConfig config, FingerprintReadCallback callback)`

**参数**:

```json
{
  "timeout": 30000,           // 读取超时时间，默认30秒
  "readType": "string",       // 读取类型：FEATURE(特征码)/IMAGE(图片)/BOTH(都读取)
}
```

**回调方法**: `FingerprintReadCallback.onFingerprintResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "readType": "string",         // 实际读取类型
    "quality": number,            // 指纹质量分数（0-100）
    "feature": {                  // 特征码数据（readType为FEATURE或BOTH时返回）
      "version": "string",        // 特征码版本
      "data": "string",          // 特征码数据（Base64编码）
      "length": number           // 特征码长度
    },
    "image": {                    // 图片数据（readType为IMAGE或BOTH时返回）
      "format": "string",        // 图片格式
      "width": number,          // 图片宽度
      "height": number,         // 图片高度
      "data": "string",         // 图片数据（Base64编码）
      "size": number            // 图片大小（字节）
    }
  }
}
```

## 9. 取消操作

### 9.1 取消当前操作
**方法名**: `cancelOperation(CancelCallback callback)`

**回调方法**: `CancelCallback.onCancelResult`

**回调数据**:

```json
{
  "code": "000000",        // 响应代码
  "msg": "Success",        // 响应消息
  "data": {
    "cancelTime": "string",      // 取消时间
    "canceledOperations": [{     // 被取消的操作列表
      "type": "string",         // 操作类型
      "status": "string"        // 操作状态：canceled/canceling
    }]
  }
}
```

## 日志？
## 音量？


## 11. 注意事项

1. 设备连接
   - 设备连接具有独占性，同一时间只能被一个应用程序连接
   - 如果其他应用程序已连接设备，连接将返回错误码：（设备已被占用）
   - 读卡读证操作会自动尝试重连最后一次成功连接的设备（如果该设备未被占用）
   - 自动重连超时时间为n秒，超时后将返回错误码 （连接超时）

2. 操作超时
   - 所有操作都有默认的超时时间（通常为30秒）
   - 超时后操作会自动取消并返回错误码 （操作超时）
   - 可以通过参数自定义超时时间

3. 错误处理
   - 实现完整的错误处理机制
   - 记录详细的错误日志
   - 提供友好的错误提示
   - 在遇到设备占用错误时，建议提示用户检查其他应用是否正在使用设备

4. 性能优化
   - 及时释放不需要的资源

