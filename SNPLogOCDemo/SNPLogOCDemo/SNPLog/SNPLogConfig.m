//
//  SNPLogConfig.m
//  SNPLogOCDemo
//
//  Created by zhengnan on 2026/9/3.
//

#import "SNPLogConfig.h"

@implementation SNPLogConfig

- (instancetype)initWithLogFilePath:(NSString *)logFilePath
                             deviceId:(NSString *)deviceId
                              logType:(SNPLogType)logType {
    if (self = [super init]) {
        _logFilePath = [logFilePath copy];
        _deviceId = [deviceId copy];
        _logType = logType;
    }
    return self;
}

- (instancetype)initWithLogFilePath:(NSString *)logFilePath
                             deviceId:(NSString *)deviceId {
    return [self initWithLogFilePath:logFilePath deviceId:deviceId logType:SNPLogTypeConsole];
}

@end
