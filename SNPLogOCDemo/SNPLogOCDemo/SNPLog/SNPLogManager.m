//
//  SNPLogManager.m
//  SNPLogOCDemo
//
//  Created by zhengnan on 2026/9/3.
//

#import "SNPLogManager.h"
#import "snp_log_writer.h"

@interface SNPLogManager ()

@property (nonatomic, strong) SNPLogConfig *config;
@property (nonatomic, copy) NSString *logFilePath;
@property (nonatomic, assign) SNPLogType logType;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *currentLogDate;

@property (nonatomic) void *writer;
@property (nonatomic, strong) dispatch_queue_t logQueue;
@property (nonatomic, strong) dispatch_source_t flushTimer;

@property (nonatomic, strong) NSDateFormatter *fileNameDateFormatter;
@property (nonatomic, strong) NSDateFormatter *logTimeDateFormatter;

@end

static SNPLogManager *_sharedManager = nil;

@implementation SNPLogManager

#pragma mark - 单例

+ (void)setupWithConfig:(SNPLogConfig *)config {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[SNPLogManager alloc] initWithConfig:config];
    });
}

+ (instancetype)sharedManager {
    if (!_sharedManager) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"请先调用 +[SNPLogManager setupWithConfig:] 进行初始化"];
    }
    return _sharedManager;
}

- (instancetype)initWithConfig:(SNPLogConfig *)config {
    if (self = [super init]) {
        _config = config;
        _logFilePath = config.logFilePath;
        _logType = config.logType;
        _deviceId = config.deviceId;
        _logQueue = dispatch_queue_create("com.nan.logQueue.oc", DISPATCH_QUEUE_SERIAL);

        _fileNameDateFormatter = [[NSDateFormatter alloc] init];
        [_fileNameDateFormatter setDateFormat:@"yyyy-MM-dd"];
        _logTimeDateFormatter = [[NSDateFormatter alloc] init];
        [_logTimeDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];

        _currentLogDate = [self.fileNameDateFormatter stringFromDate:[NSDate date]];

        // 完成所有属性初始化后，再进行文件操作
        [self setupLogFile];
        [self startFlushTimer];
    }
    return self;
}

#pragma mark - 文件管理

- (void)setupLogFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // 确保日志目录存在
    if (![fileManager fileExistsAtPath:self.logFilePath]) {
        [fileManager createDirectoryAtPath:self.logFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    // 获取完整的日志文件路径
    NSString *currentFileName = [self currentLogFileName];
    NSString *fullPath = [self.logFilePath stringByAppendingPathComponent:currentFileName];
    NSLog(@"日志文件路径: %@", fullPath);

    BOOL fileExisted = [fileManager fileExistsAtPath:fullPath];
    if (!fileExisted) {
        [fileManager createFileAtPath:fullPath contents:nil attributes:nil];
    }

    // 关闭旧的 writer（跨天切换时）
    if (self.writer) {
        snp_log_destroy(self.writer);
        self.writer = NULL;
    }

    self.writer = snp_log_create(fullPath.fileSystemRepresentation);
    if (!self.writer) {
        NSLog(@"错误：无法打开日志文件进行写入，路径：%@", fullPath);
        return;
    }

    // 新建的文件写入一条启动日志
    if (!fileExisted) {
        NSString *startupLog = [NSString stringWithFormat:@"=== 日志系统启动 [%@] ===\n",
                                [self.logTimeDateFormatter stringFromDate:[NSDate date]]];
        [self writeToWriter:startupLog];
    }
}

- (void)startFlushTimer {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.logQueue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                              1 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        [weakSelf synchronizeFile];
    });
    dispatch_resume(timer);
    self.flushTimer = timer;
}

- (void)synchronizeFile {
    if (self.writer) {
        snp_log_flush(self.writer);
    }
}

#pragma mark - 写日志

- (void)writeLog:(NSString *)log
            type:(SNPLogInfoType)type
            file:(const char *)file
        function:(const char *)function
            line:(NSInteger)line {
    // 获取时间戳
    NSString *timestamp = [self.logTimeDateFormatter stringFromDate:[NSDate date]];
    NSString *typeString = SNPLogInfoTypeIndicator(type);

    // 构建完整日志
    NSString *fileName = file ? [[NSString stringWithUTF8String:file] lastPathComponent] : @"";
    NSString *functionName = function ? [NSString stringWithUTF8String:function] : @"";
    NSString *fullLog = [NSString stringWithFormat:@"[%@] [%@] [%@:%ld] %@ - %@",
                         timestamp, typeString, fileName, (long)line, functionName, log];

    if (self.logType == SNPLogTypeConsole) {
        NSLog(@"%@", fullLog);
        return;
    }
    [self writeToFile:fullLog];
}

// 获取当前日志文件名
- (NSString *)currentLogFileName {
    NSString *today = [self.fileNameDateFormatter stringFromDate:[NSDate date]];
    if (![today isEqualToString:self.currentLogDate]) {
        self.currentLogDate = today;
    }
    return [NSString stringWithFormat:@"SNPLog-%@-%@.log", self.deviceId, self.currentLogDate];
}

// 写入日志
- (void)writeToFile:(NSString *)log {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.logQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        // 写入前检查日期，跨天时销毁旧 writer、切换新文件
        NSString *today = [strongSelf.fileNameDateFormatter stringFromDate:[NSDate date]];
        if (![today isEqualToString:strongSelf.currentLogDate]) {
            strongSelf.currentLogDate = today;
            [strongSelf setupLogFile];
        }

        // 确保日志以换行结束
        NSString *logWithNewline = [log hasSuffix:@"\n"] ? log : [log stringByAppendingString:@"\n"];
        [strongSelf writeToWriter:logWithNewline];
    });
}

- (void)writeToWriter:(NSString *)log {
    if (!self.writer) {
        NSLog(@"错误：文件句柄为空，尝试重新打开文件");
        [self setupLogFile];
        if (!self.writer) return;
    }
    NSData *data = [log dataUsingEncoding:NSUTF8StringEncoding];
    snp_log_write(self.writer, data.bytes, data.length);
    snp_log_flush(self.writer);
}

- (void)dealloc {
    if (_writer) {
        snp_log_flush(_writer);
        snp_log_destroy(_writer);
        _writer = NULL;
    }
}

#pragma mark - 便捷日志方法

+ (void)info:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line {
    [[self sharedManager] writeLog:message type:SNPLogInfoTypeInfo file:file function:function line:line];
}

+ (void)warning:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line {
    [[self sharedManager] writeLog:message type:SNPLogInfoTypeWarning file:file function:function line:line];
}

+ (void)error:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line {
    [[self sharedManager] writeLog:message type:SNPLogInfoTypeError file:file function:function line:line];
}

+ (void)network:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line {
    [[self sharedManager] writeLog:message type:SNPLogInfoTypeNetwork file:file function:function line:line];
}

@end
