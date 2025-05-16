
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
