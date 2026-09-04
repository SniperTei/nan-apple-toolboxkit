//
//  SNPVoiceResult.h
//  SNPVoiceComponent
//
//  统一回调结果模型：{"code": "000000", "msg": "success", "data": {...}}
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNPVoiceResult : NSObject

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *msg;
/// JSON 的 Dictionary，可为空
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *data;

+ (instancetype)successWithMsg:(NSString *)msg data:(nullable NSDictionary<NSString *, id> *)data;
+ (instancetype)failureWithCode:(NSString *)code msg:(NSString *)msg;

/// 转为 {"code": "000000", "msg": "success", "data": {...}} 结构的字典
- (NSDictionary<NSString *, id> *)toDictionary;

- (BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
