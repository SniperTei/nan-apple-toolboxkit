# API 文档

## 通用说明

### 基础URL
```
http://localhost:3000/api
```

### 通用响应格式

所有API响应都遵循以下格式：

```json
{
  "code": "000000",        // 响应代码：成功="000000"，错误="A00xxx"
  "statusCode": 200,       // HTTP状态码
  "msg": "Success",        // 响应消息
  "data": null,           // 响应数据，错误时为null
  "timestamp": "2025-01-02 14:11:30.123" // 服务器时间戳
}
```

### 错误码说明
| 错误码 | 说明 |
|--------|------|
| 000000 | 成功 |
| E00001 | 参数错误 |
| E00002 | 用户已存在 |
| E00003 | 用户不存在 |
| E00004 | 密码错误 |
| E00005 | 未授权访问 |
| E00401 | 认证失败 |
| E00403 | 权限不足 |
| E00404 | 资源不存在 |
| E00500 | 服务器内部错误 |

### 认证方式
除了注册和登录接口，其他所有接口都需要在请求头中携带 token：
```
Authorization: Bearer <token>
```

## 用户相关接口

### 1. 用户注册

**请求方式**
- POST `v1/user/register`

**请求参数**
```json
{
  "username": "string",     // 必需，3-20个字符
  "password": "string",     // 必需，最少6个字符
  "email": "string",       // 可选，需要符合邮箱格式
  "nickname": "string",    // 可选，最多30个字符
  "avatarUrl": "string"    // 可选，头像URL
}
```

**成功响应**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "注册成功",
  "data": {
    "userId": "60d5ecb8b5c9c62b3c3c1234"
  },
  "timestamp": "2023-12-20 14:11:30.123"
}
```

### 2. 用户登录

**请求方式**
- POST `v1/user/login`

**请求参数**
```json
{
  "username": "string",    // 必需
  "password": "string"     // 必需
}
```

**成功响应**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1...",
    "user": {
      "id": "60d5ecb8b5c9c62b3c3c1234",
      "username": "admin",
      "email": "admin@test.com",
      "nickname": "管理员",
      "avatarUrl": "http://example.com/avatar.jpg",
      "isAdmin": true,
      "createdAt": "2023-12-20T06:11:30.123Z"
    }
  },
  "timestamp": "2023-12-20 14:11:30.123"
}
```

### 3. 获取用户信息

**请求方式**
- GET `v1/user/profile`

**请求头**
```
Authorization: Bearer <token>
```

**成功响应**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "Success",
  "data": {
    "id": "60d5ecb8b5c9c62b3c3c1234",
    "username": "admin",
    "email": "admin@test.com",
    "nickname": "管理员",
    "avatarUrl": "http://example.com/avatar.jpg",
    "isAdmin": true,
    "createdAt": "2023-12-20T06:11:30.123Z",
    "createdBy": {
      "username": "admin",
      "nickname": "管理员"
    },
    "updatedAt": "2023-12-20T06:11:30.123Z",
    "updatedBy": {
      "username": "admin",
      "nickname": "管理员"
    }
  },
  "timestamp": "2023-12-20 14:11:30.123"
}
```

### 4. 更新用户信息

**请求方式**
- PUT `v1/user/profile`

**请求头**
```
Authorization: Bearer <token>
```

**请求参数**
```json
{
  "email": "string",      // 可选，需要符合邮箱格式
  "nickname": "string",   // 可选，最多30个字符
  "avatarUrl": "string",  // 可选，头像URL
  "isAdmin": boolean      // 可选，仅管理员可设置
}
```

**成功响应**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "更新成功",
  "data": {
    "id": "60d5ecb8b5c9c62b3c3c1234",
    "username": "admin",
    "email": "new@test.com",
    "nickname": "新昵称",
    "avatarUrl": "http://example.com/new-avatar.jpg",
    "isAdmin": true,
    "createdAt": "2023-12-20T06:11:30.123Z",
    "updatedAt": "2023-12-20T07:11:30.123Z"
  },
  "timestamp": "2023-12-20 14:11:30.123"
}
```

### 5. 文件上传

**请求方式**
- POST `/v1/upload/files`

**请求头**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**请求参数**
- fileList: 文件数组（1-9个文件）
- fileType: 文件类型（可选，当上传日志文件时设置为 'log'）
- deviceId: 设备ID（当 fileType='log' 时必需）
- logType: 日志类型（可选，当 fileType='log' 时有效，可选值：error/info/warning/debug）
- content: 日志内容（当 fileType='log' 时必需）
- metadata: 额外信息（可选，JSON 字符串）

**成功响应示例（普通文件）**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "文件上传成功",
  "data": [
    {
      "url": "http://localhost:3000/uploads/image/uuid.jpg",
      "fileName": "uuid.jpg",
      "originalName": "photo.jpg",
      "size": 1024,
      "mimeType": "image/jpeg",
      "type": "image"
    }
  ],
  "timestamp": "2023-12-20 14:11:30.123"
}
```

**成功响应示例（日志文件）**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "文件上传成功",
  "data": [
    {
      "url": "http://localhost:3000/uploads/document/uuid.log",
      "fileName": "uuid.log",
      "originalName": "error.log",
      "size": 1024,
      "mimeType": "text/plain",
      "type": "document"
    }
  ],
  "timestamp": "2023-12-20 14:11:30.123"
}
```

**错误响应示例**
```json
{
  "code": "A00001",
  "statusCode": 400,
  "msg": "最多只能上传9个文件",
  "data": null,
  "timestamp": "2023-12-20 14:11:30.123"
}
```

**使用说明**
1. 支持的文件类型：
   - 图片：.png, .jpg, .jpeg, .gif, .webp
   - 音频：.mp3, .wav, .ogg
   - 视频：.mp4, .webm, .avi
   - 文档：.pdf, .doc, .docx
2. 单个文件大小限制：
   - 开发环境：5MB
   - 生产环境：10MB
3. 文件数量限制：1-9个
4. 返回的文件URL会根据环境自动适配：
   - 开发环境：http://localhost:3000/uploads/...
   - 生产环境：https://api.yourdomain.com/uploads/...

## 错误响应示例

### 1. 参数错误
```json
{
  "code": "A00001",
  "statusCode": 400,
  "msg": "用户名至少需要3个字符",
  "data": null,
  "timestamp": "2023-12-20 14:11:30.123"
}
```

### 2. 认证失败
```json
{
  "code": "A00005",
  "statusCode": 401,
  "msg": "无效的认证令牌",
  "data": null,
  "timestamp": "2023-12-20 14:11:30.123"
}
```

### 3. 用户已存在
```json
{
  "code": "A00002",
  "statusCode": 400,
  "msg": "用户名或邮箱已存在",
  "data": null,
  "timestamp": "2023-12-20 14:11:30.123"
}
```

## 注意事项

1. 所有时间戳都使用 ISO 8601 格式
2. 密码在传输和存储时都会进行加密处理
3. token 有效期为 24 小时
4. 第一个注册的用户自动成为管理员
5. 只有管理员可以修改其他用户的管理员权限

### 7. 日志管理

#### 7.1 上传日志

**请求方式**
- POST `/v1/logs`

**请求头**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**请求参数**
```json
{
  "deviceId": "string",    // 必需，设备ID
  "type": "string",       // 可选，日志类型：error/info/warning/debug
  "content": "string",    // 必需，日志内容
  "metadata": {           // 可选，额外信息
    "osVersion": "string",     // 操作系统版本
    "deviceModel": "string",   // 设备型号
    "appVersion": "string",    // APP版本
    "deviceUUID": "string",    // 设备唯一标识符
    "errorType": "string",     // 错误类型
    "errorStack": "string",    // 错误堆栈
    "errorScene": "string",    // 错误场景
    "cpuUsage": "string",      // CPU使用率
    "memoryUsage": "string",   // 内存使用情况
    "networkType": "string",   // 网络类型
    "userAction": "string",    // 用户操作
    "timestamp": "string"      // 错误发生时间
  }
}
```
- file: 文件对象（可选）

#### 7.2 获取日志列表

**请求方式**
- GET `/v1/logs`

**请求参数**
```
deviceId: string          // 可选，设备ID
type: string             // 可选，日志类型
startTime: string        // 可选，开始时间，ISO格式
endTime: string          // 可选，结束时间，ISO格式
page: number             // 可选，页码，默认1
limit: number           // 可选，每页数量，默认10
sort: string            // 可选，排序方式，默认-timestamp
```

**成功响应**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "Success",
  "data": {
    "logs": [{
      "id": "60d5ecb8b5c9c62b3c3c1234",
      "deviceId": "device_001",
      "fileUrl": "http://localhost:3000/uploads/logs/crash.log",
      "fileName": "crash.log",
      "fileSize": 1024,
      "metadata": {
        "version": "1.0.0",
        "platform": "android"
      },
      "timestamp": "2023-12-20T06:11:30.123Z",
      "createdBy": {
        "username": "admin",
        "nickname": "管理员"
      }
    }],
    "pagination": {
      "total": 100,
      "page": 1,
      "limit": 10,
      "pages": 10
    }
  },
  "timestamp": "2023-12-20 14:11:30.123"
}
```

#### 7.3 获取设备列表

**请求方式**
- GET `/v1/logs/devices`

**成功响应**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "Success",
  "data": ["device_001", "device_002", "device_003"],
  "timestamp": "2023-12-20 14:11:30.123"
}
```

#### 7.4 下载日志文件

**请求方式**
- GET `/v1/logs/:logId/download`

**成功响应**
```json
{
  "code": "000000",
  "statusCode": 200,
  "msg": "Success",
  "data": {
    "url": "http://localhost:3000/uploads/logs/crash.log",
    "fileName": "crash.log"
  },
  "timestamp": "2023-12-20 14:11:30.123"
}
```