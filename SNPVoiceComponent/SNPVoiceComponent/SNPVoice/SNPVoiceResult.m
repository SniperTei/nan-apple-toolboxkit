//
//  SNPVoiceResult.m
//  SNPVoiceComponent
//

#import "SNPVoiceResult.h"
#import "SNPVoiceConst.h"

NSString * const SNPVoiceResultCodeKey = @"code";
NSString * const SNPVoiceResultMsgKey  = @"msg";
NSString * const SNPVoiceResultDataKey = @"data";

NSString * const SNPVoiceCodeSuccess               = @"000000";
NSString * const SNPVoiceCodeError                 = @"999999";
NSString * const SNPVoiceCodeSpeakTextEmpty        = @"100001";
NSString * const SNPVoiceCodePermissionDenied      = @"200001";
NSString * const SNPVoiceCodeRecognizerUnavailable = @"200002";
NSString * const SNPVoiceCodeRecognitionError      = @"200003";

@implementation SNPVoiceResult

+ (instancetype)successWithMsg:(NSString *)msg data:(nullable NSDictionary<NSString *, id> *)data {
    SNPVoiceResult *result = [[self alloc] init];
    result.code = SNPVoiceCodeSuccess;
    result.msg = msg ?: @"success";
    result.data = data;
    return result;
}

+ (instancetype)failureWithCode:(NSString *)code msg:(NSString *)msg {
    SNPVoiceResult *result = [[self alloc] init];
    result.code = code ?: SNPVoiceCodeError;
    result.msg = msg ?: @"error";
    return result;
}

- (NSDictionary<NSString *, id> *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[SNPVoiceResultCodeKey] = self.code;
    dict[SNPVoiceResultMsgKey] = self.msg;
    dict[SNPVoiceResultDataKey] = self.data ?: @{};
    return dict;
}

- (BOOL)isSuccess {
    return [self.code isEqualToString:SNPVoiceCodeSuccess];
}

@end
