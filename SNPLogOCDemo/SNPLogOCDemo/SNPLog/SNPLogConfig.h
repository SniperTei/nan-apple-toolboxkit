//
//  SNPLogConfig.h
//  SNPLogOCDemo
//
//  Created by zhengnan on 2026/9/3.
//

#import <Foundation/Foundation.h>
#import "SNPLogConst.h"

NS_ASSUME_NONNULL_BEGIN

@interface SNPLogConfig : NSObject

@property (nonatomic, copy, readonly) NSString *logFilePath;
@property (nonatomic, assign, readonly) SNPLogType logType;
@property (nonatomic, copy, readonly) NSString *deviceId;

- (instancetype)initWithLogFilePath:(NSString *)logFilePath
                             deviceId:(NSString *)deviceId
                              logType:(SNPLogType)logType;

- (instancetype)initWithLogFilePath:(NSString *)logFilePath
                             deviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
