//
//  TestLogController.m
//  SNPLogOCDemo
//
//  Created by zhengnan on 2026/9/3.
//

#import "TestLogController.h"
#import "SNPLogManager.h"
#import <mach/mach.h>

@interface TestLogController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *sections;

@property (nonatomic, assign) NSInteger autoLogCount;
@property (nonatomic, strong) NSTimer *logTimer;
@property (nonatomic, assign) CFAbsoluteTime startTime;

// 生产者消费者测试
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSLock *bufferLock;
@property (nonatomic, assign) NSInteger maxBufferSize;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *buffer;
@property (nonatomic, assign) BOOL isProducing;
@property (nonatomic, assign) NSInteger totalItemsToProducePerProducer;
@property (nonatomic, assign) NSInteger totalProduced;

@end

@implementation TestLogController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    [self setupLogger];
}

#pragma mark - UI

- (void)setupUI {
    self.title = @"日志测试";
    self.view.backgroundColor = UIColor.whiteColor;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:UITableViewCell.self forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.sections = @[
        @{@"title": @"性能测试", @"items": @[
            @{@"title": @"性能测试(1万条)", @"action": ^{ [self performanceTest]; }},
            @{@"title": @"开始连续写入", @"action": ^{ [self startLoggingTest]; }},
            @{@"title": @"停止写入", @"action": ^{ [self stopLoggingTest]; }},
            @{@"title": @"并发写入测试", @"action": ^{ [self concurrentTest]; }},
            @{@"title": @"生产者消费者测试", @"action": ^{ [self producerConsumerTest]; }}
        ]},
        @{@"title": @"日志管理", @"items": @[
            @{@"title": @"查看日志文件", @"action": ^{ [self showLogFile]; }},
            @{@"title": @"清理日志文件", @"action": ^{ [self clearLogFiles]; }},
            @{@"title": @"网络请求日志测试", @"action": ^{ [self networkLogTest]; }}
        ]}
    ];
}

- (void)setupLogger {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *logPath = [documentsPath stringByAppendingPathComponent:@"Logs"];

    NSLog(@"设置日志路径: %@", logPath);

    SNPLogConfig *config = [[SNPLogConfig alloc] initWithLogFilePath:logPath
                                                             deviceId:@"simulatorOC"
                                                              logType:SNPLogTypeFile];
    [SNPLogManager setupWithConfig:config];

    // 写入一条测试日志
    SNPLogInfo(@"日志系统初始化完成");
}

#pragma mark - 性能测试

- (void)performanceTest {
    self.startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime start = self.startTime;

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        for (NSInteger i = 1; i <= 10000; i++) {
            NSString *memory = [self memoryUsageString];
            [[SNPLogManager sharedManager] writeLog:[NSString stringWithFormat:@"性能测试 #%ld - 内存: %@MB", (long)i, memory]
                                                type:SNPLogInfoTypeInfo
                                                file:__FILE__
                                            function:__PRETTY_FUNCTION__
                                                line:__LINE__];
        }

        CFAbsoluteTime timeElapsed = CFAbsoluteTimeGetCurrent() - start;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:@"性能测试完成"
                             message:[NSString stringWithFormat:@"总耗时: %.3f秒\n平均每条日志耗时: %.3f毫秒",
                                      timeElapsed, timeElapsed / 10000 * 1000]];
        });
    });
}

- (void)startLoggingTest {
    [self stopLoggingTestSilently];
    self.startTime = CFAbsoluteTimeGetCurrent();

    __weak typeof(self) weakSelf = self;
    self.logTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 repeats:YES block:^(NSTimer *timer) {
        [weakSelf writeAutoLog];
    }];
    [self showToastWithMessage:@"开始连续写入测试"];
}

- (void)stopLoggingTest {
    [self.logTimer invalidate];
    self.logTimer = nil;

    CFAbsoluteTime timeElapsed = CFAbsoluteTimeGetCurrent() - self.startTime;
    NSInteger count = self.autoLogCount;
    NSString *message = [NSString stringWithFormat:@"写入数量: %ld条\n总耗时: %.3f秒\n平均每条日志耗时: %.3f毫秒",
                         (long)count, timeElapsed, count > 0 ? timeElapsed / (double)count * 1000 : 0];
    [self showAlertWithTitle:@"停止写入测试" message:message];
    self.autoLogCount = 0;
}

- (void)stopLoggingTestSilently {
    [self.logTimer invalidate];
    self.logTimer = nil;
    self.autoLogCount = 0;
}

- (void)concurrentTest {
    self.startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime start = self.startTime;

    dispatch_group_t group = dispatch_group_create();

    for (NSInteger index = 0; index < 5; index++) {
        dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"com.nan.logQueue.%ld", (long)index] UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_group_enter(group);
        dispatch_async(queue, ^{
            for (NSInteger i = 1; i <= 2000; i++) {
                NSString *memory = [self memoryUsageString];
                [[SNPLogManager sharedManager] writeLog:[NSString stringWithFormat:@"并发测试 - 线程%ld - #%ld - 内存: %@MB", (long)index, (long)i, memory]
                                                    type:SNPLogInfoTypeInfo
                                                    file:__FILE__
                                                function:__PRETTY_FUNCTION__
                                                    line:__LINE__];
            }
            dispatch_group_leave(group);
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        CFAbsoluteTime timeElapsed = CFAbsoluteTimeGetCurrent() - start;
        [self verifyLogFile:^(NSString *result) {
            NSString *message = [NSString stringWithFormat:@"总日志数: 10000条\n总耗时: %.3f秒\n平均每条日志耗时: %.3f毫秒\n\n验证结果：\n%@",
                                 timeElapsed, timeElapsed / 10000 * 1000, result];
            [self showAlertWithTitle:@"并发测试完成" message:message];
        }];
    });
}

#pragma mark - 日志管理

- (void)showLogFile {
    [self verifyLogFile:^(NSString *result) {
        [self showAlertWithTitle:@"日志文件内容" message:result];
    }];
}

- (void)clearLogFiles {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *logPath = [documentsPath stringByAppendingPathComponent:@"Logs"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:logPath error:&error];
    if (error) {
        [self showAlertWithTitle:@"清理失败" message:error.localizedDescription];
        return;
    }
    for (NSString *file in files) {
        NSString *filePath = [logPath stringByAppendingPathComponent:file];
        [fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            [self showAlertWithTitle:@"清理失败" message:error.localizedDescription];
            return;
        }
    }
    [self showToastWithMessage:@"日志文件已清理"];
}

- (void)networkLogTest {
    // 记录请求参数
    NSDictionary *requestParams = @{
        @"username": @"admin",
        @"password": @"123456",
        @"deviceId": @"iPhone14Pro"
    };

    [SNPLogManager network:[NSString stringWithFormat:
        @"=== 网络请求开始 ===\nURL: http://api.example.com/login\nMethod: POST\nHeaders: {\n    \"Content-Type\": \"application/json\",\n    \"User-Agent\": \"MyApp/1.0\"\n}\nParameters: %@",
        requestParams]
        file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];

    // 模拟网络请求延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *responseData = @{
            @"code": @"200",
            @"msg": @"登录成功",
            @"data": @{
                @"token": @"eyJhbGciOiJIUzI1NiIs...",
                @"userId": @"12345",
                @"username": @"admin"
            }
        };

        [SNPLogManager network:[NSString stringWithFormat:
            @"=== 网络请求完成 ===\nStatus: 200 OK\nResponse Time: 1.023s\nResponse Data: %@",
            responseData]
            file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];

        [self showToastWithMessage:@"网络请求日志已记录"];
    });
}

#pragma mark - 生产者消费者测试

- (void)producerConsumerTest {
    // 重置状态
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.concurrentQueue = dispatch_queue_create("com.nan.queue.oc", DISPATCH_QUEUE_CONCURRENT);
    self.semaphore = dispatch_semaphore_create(0);
    self.bufferLock = [[NSLock alloc] init];
    self.maxBufferSize = 100;
    self.buffer = [NSMutableArray array];
    self.isProducing = YES;
    self.totalItemsToProducePerProducer = 17;  // 每个生产者生产17个，3个生产者共51个
    self.totalProduced = 0;

    // 启动3个生产者
    for (NSInteger producerId = 0; producerId < 3; producerId++) {
        dispatch_async(self.concurrentQueue, ^{
            [self producerWithId:producerId];
        });
    }

    // 启动2个消费者
    for (NSInteger consumerId = 0; consumerId < 2; consumerId++) {
        dispatch_async(self.concurrentQueue, ^{
            [self consumerWithId:consumerId];
        });
    }

    // 等待生产完成
    dispatch_async(self.concurrentQueue, ^{
        // 等待所有生产者生产完成
        [NSThread sleepForTimeInterval:2];
        self.isProducing = NO;

        // 再等待一会儿让消费者消费完
        [NSThread sleepForTimeInterval:2];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopProducerConsumerTest];
        });
    });

    [self showToastWithMessage:@"生产者消费者测试开始"];
}

- (void)producerWithId:(NSInteger)id {
    NSInteger count = 0;
    while (self.isProducing && count < self.totalItemsToProducePerProducer) {
        [self.bufferLock lock];
        if (self.buffer.count < self.maxBufferSize) {
            count++;
            self.totalProduced++;
            [self.buffer addObject:@(self.totalProduced)];

            // 根据不同情况使用不同的日志级别和类型
            if (count == 1) {
                [SNPLogManager info:[NSString stringWithFormat:@"生产者%ld 开始生产", (long)id]
                                 file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
            } else if (self.buffer.count >= self.maxBufferSize) {
                [SNPLogManager error:[NSString stringWithFormat:@"生产者%ld 缓冲区已满", (long)id]
                                  file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
            }

            [SNPLogManager info:[NSString stringWithFormat:@"生产者%ld 生产第%ld个(总第%ld个), 当前缓冲区: %ld个",
                                        (long)id, (long)count, (long)self.totalProduced, (long)self.buffer.count]
                             file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
            dispatch_semaphore_signal(self.semaphore);
        }
        [self.bufferLock unlock];
        [NSThread sleepForTimeInterval:0.1];
    }
    [SNPLogManager info:[NSString stringWithFormat:@"生产者%ld 完成生产, 共生产: %ld个", (long)id, (long)count]
                     file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
}

- (void)consumerWithId:(NSInteger)id {
    NSInteger count = 0;
    while (self.isProducing || self.buffer.count > 0) {
        if (dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC))) != 0) {
            if (!self.isProducing && self.buffer.count == 0) {
                break;
            }
            [SNPLogManager warning:[NSString stringWithFormat:@"消费者%ld 等待超时", (long)id]
                               file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
            continue;
        }

        [self.bufferLock lock];
        if (self.buffer.count > 0) {
            NSInteger item = self.buffer.firstObject.integerValue;
            [self.buffer removeObjectAtIndex:0];
            count++;

            if (count == 1) {
                [SNPLogManager info:[NSString stringWithFormat:@"消费者%ld 开始消费", (long)id]
                                 file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
            }

            [SNPLogManager info:[NSString stringWithFormat:@"消费者%ld 消费第%ld个(序号%ld), 剩余缓冲区: %ld个",
                                        (long)id, (long)count, (long)item, (long)self.buffer.count]
                             file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
        } else {
            [SNPLogManager warning:[NSString stringWithFormat:@"消费者%ld 发现空缓冲区", (long)id]
                               file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
        }
        [self.bufferLock unlock];
        [NSThread sleepForTimeInterval:0.15];
    }
    [SNPLogManager info:[NSString stringWithFormat:@"消费者%ld 结束消费, 共消费: %ld个", (long)id, (long)count]
                     file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__];
}

- (void)stopProducerConsumerTest {
    CFAbsoluteTime timeElapsed = CFAbsoluteTimeGetCurrent() - self.startTime;

    // 清理资源
    [self.bufferLock lock];
    NSInteger remainingItems = self.buffer.count;
    [self.buffer removeAllObjects];
    [self.bufferLock unlock];

    NSInteger produced = self.totalProduced;
    NSInteger target = 3 * self.totalItemsToProducePerProducer;
    [self verifyLogFile:^(NSString *result) {
        NSString *message = [NSString stringWithFormat:
            @"测试时长: %.3f秒\n目标生产数量: %ld个\n实际生产数量: %ld个\n剩余未消费: %ld个\n\n日志分析：\n%@",
            timeElapsed, (long)target, (long)produced, (long)remainingItems, result];
        [self showAlertWithTitle:@"生产者消费者测试完成" message:message];
    }];
}

#pragma mark - 辅助方法

- (void)writeAutoLog {
    self.autoLogCount++;
    NSString *memory = [self memoryUsageString];
    [[SNPLogManager sharedManager] writeLog:[NSString stringWithFormat:@"连续测试 #%ld - 内存: %@MB", (long)self.autoLogCount, memory]
                                        type:SNPLogInfoTypeInfo
                                        file:__FILE__
                                    function:__PRETTY_FUNCTION__
                                        line:__LINE__];
}

- (NSString *)memoryUsageString {
    struct mach_task_basic_info info;
    mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;

    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &count);
    if (kerr == KERN_SUCCESS) {
        float physical = (float)info.resident_size / 1024.0f / 1024.0f;
        float virtual = (float)info.virtual_size / 1024.0f / 1024.0f;
        return [NSString stringWithFormat:@"(物理: %.1f, 虚拟: %.1f)", physical, virtual];
    }
    return @"(0.0, 0.0)";
}

- (void)verifyLogFile:(void (^)(NSString *))completion {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *logPath = [documentsPath stringByAppendingPathComponent:@"Logs"];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *currentFileName = [NSString stringWithFormat:@"SNPLog-simulatorOC-%@.log",
                                 [dateFormatter stringFromDate:[NSDate date]]];
    NSString *logFilePath = [logPath stringByAppendingPathComponent:currentFileName];

    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&error];
    if (!content) {
        NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logPath error:nil];
        completion([NSString stringWithFormat:
            @"日志文件验证失败：%@\n文件路径：%@\n\n日志目录文件列表：\n%@",
            error, logFilePath, files ? [files componentsJoinedByString:@"\n"] : @"无法读取目录"]);
        return;
    }

    NSArray<NSString *> *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSPredicate *nonEmpty = [NSPredicate predicateWithFormat:@"length > 0"];
    NSArray<NSString *> *validLines = [lines filteredArrayUsingPredicate:nonEmpty];

    NSMutableString *result = [NSMutableString stringWithFormat:@"实际写入行数: %ld\n\n", (long)validLines.count];

    // 分析生产者消费者日志
    NSMutableDictionary<NSNumber *, NSNumber *> *producerCounts = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, NSNumber *> *consumerCounts = [NSMutableDictionary dictionary];

    NSRegularExpression *producerRegex = [NSRegularExpression regularExpressionWithPattern:@"生产者(\\d+)" options:0 error:nil];
    NSRegularExpression *consumerRegex = [NSRegularExpression regularExpressionWithPattern:@"消费者(\\d+)" options:0 error:nil];

    for (NSString *line in validLines) {
        if ([line containsString:@"生产者"] && [line containsString:@"生产:"]) {
            NSTextCheckingResult *match = [producerRegex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match) {
                NSInteger id = [[line substringWithRange:[match rangeAtIndex:1]] integerValue];
                producerCounts[@(id)] = @(producerCounts[@(id)].integerValue + 1);
            }
        } else if ([line containsString:@"消费者"] && [line containsString:@"消费:"]) {
            NSTextCheckingResult *match = [consumerRegex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match) {
                NSInteger id = [[line substringWithRange:[match rangeAtIndex:1]] integerValue];
                consumerCounts[@(id)] = @(consumerCounts[@(id)].integerValue + 1);
            }
        }
    }

    // 添加生产者消费者统计
    [result appendString:@"\n生产者统计：\n"];
    for (NSNumber *id in [producerCounts.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        [result appendFormat:@"生产者%ld: %ld条\n", (long)id.integerValue, (long)producerCounts[id].integerValue];
    }

    [result appendString:@"\n消费者统计：\n"];
    for (NSNumber *id in [consumerCounts.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        [result appendFormat:@"消费者%ld: %ld条\n", (long)id.integerValue, (long)consumerCounts[id].integerValue];
    }

    completion(result);
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToastWithMessage:(NSString *)message {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.7];
    toast.textColor = UIColor.whiteColor;
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:14];
    toast.layer.cornerRadius = 20;
    toast.clipsToBounds = YES;
    toast.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:toast];
    [NSLayoutConstraint activateConstraints:@[
        [toast.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [toast.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-50],
        [toast.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor constant:-40],
        [toast.heightAnchor constraintEqualToConstant:40]
    ]];

    [UIView animateWithDuration:0.3 delay:2 options:0 animations:^{
        toast.alpha = 0;
    } completion:^(BOOL finished) {
        [toast removeFromSuperview];
    }];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"items"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *item = self.sections[indexPath.section][@"items"][indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = self.sections[indexPath.section][@"items"][indexPath.row];
    void (^action)(void) = item[@"action"];
    if (action) action();
}

@end
