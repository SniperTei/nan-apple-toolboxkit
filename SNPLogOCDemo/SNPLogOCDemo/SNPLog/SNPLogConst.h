//
//  SNPLogConst.h
//  SNPLogOCDemo
//
//  Created by zhengnan on 2026/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 日志输出类型
typedef NS_ENUM(NSInteger, SNPLogType) {
    SNPLogTypeConsole,
    SNPLogTypeFile
};

// 日志记录类型
typedef NS_ENUM(NSInteger, SNPLogInfoType) {
    SNPLogInfoTypeInfo,
    SNPLogInfoTypeNetwork,
    SNPLogInfoTypeError,
    SNPLogInfoTypeWarning
};

// 日志类型指示器（对齐 Swift 扩展的 indicator）
NS_INLINE NSString *SNPLogInfoTypeIndicator(SNPLogInfoType type) {
    switch (type) {
        case SNPLogInfoTypeInfo:    return @"INFO";
        case SNPLogInfoTypeNetwork: return @"NETWORK";
        case SNPLogInfoTypeError:   return @"ERROR";
        case SNPLogInfoTypeWarning: return @"WARN";
    }
}

NS_ASSUME_NONNULL_END
