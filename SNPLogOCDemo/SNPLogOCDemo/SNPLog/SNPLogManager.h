//
//  SNPLogManager.h
//  SNPLogOCDemo
//
//  Created by zhengnan on 2026/9/3.
//

#import <Foundation/Foundation.h>
#import "SNPLogConst.h"
#import "SNPLogConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface SNPLogManager : NSObject

// 初始化
+ (void)setupWithConfig:(SNPLogConfig *)config;

// 单例（未调用 setupWithConfig: 会抛异常）
+ (instancetype)sharedManager;

// 写日志
- (void)writeLog:(NSString *)log
            type:(SNPLogInfoType)type
            file:(const char *)file
        function:(const char *)function
            line:(NSInteger)line;

// 便捷日志方法
+ (void)info:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line;
+ (void)warning:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line;
+ (void)error:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line;
+ (void)network:(NSString *)message file:(const char *)file function:(const char *)function line:(NSInteger)line;

@end

// 捕获调用位置的宏（对齐 Swift 的 #file/#function/#line 默认参数）
#define SNPLogInfo(fmt, ...)        [SNPLogManager info:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define SNPLogWarning(fmt, ...)     [SNPLogManager warning:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define SNPLogError(fmt, ...)       [SNPLogManager error:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]
#define SNPLogNetwork(fmt, ...)     [SNPLogManager network:[NSString stringWithFormat:(fmt), ##__VA_ARGS__] file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]

NS_ASSUME_NONNULL_END
