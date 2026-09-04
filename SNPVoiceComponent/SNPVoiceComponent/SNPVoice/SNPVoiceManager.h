//
//  SNPVoiceManager.h
//  SNPVoiceComponent
//
//  基于系统 API 的语音播报(AVSpeechSynthesizer) + 语音识别(Speech)组件。
//  仅依赖系统框架，直接拖入 SNPVoice 目录即可移植到其他工程。
//
//  使用前需在宿主工程 Info.plist 添加：
//    NSMicrophoneUsageDescription
//    NSSpeechRecognitionUsageDescription
//

#import <Foundation/Foundation.h>
#import "SNPVoiceResult.h"

NS_ASSUME_NONNULL_BEGIN

/// 统一回调，result 结构：{"code": "000000", "msg": "success", "data": {...}}
typedef void(^SNPVoiceCallback)(NSDictionary<NSString *, id> *result);

@interface SNPVoiceManager : NSObject

/// 默认语速（AVSpeechUtteranceDefaultSpeechRate = 0.5），rate 取值范围 0.0 ~ 1.0，越大越快
FOUNDATION_EXPORT float const SNPVoiceDefaultRate;

+ (instancetype)sharedManager;

#pragma mark - 语音播报

/// 播报文本（默认语速），播报完成后回调
- (void)speak:(NSString *)text completion:(nullable SNPVoiceCallback)completion;

/// 播报文本，rate 取值 0.0 ~ 1.0（越界会自动截断到边界值），播报完成后回调
- (void)speak:(NSString *)text rate:(float)rate completion:(nullable SNPVoiceCallback)completion;

/// 取消播报，取消完成后回调
- (void)cancelSpeak:(nullable SNPVoiceCallback)completion;

/// 当前是否正在播报
- (BOOL)isSpeaking;

#pragma mark - 语音识别

/// 开始识别，识别结束后（停止/出错/超时）回调，data: {"text": 识别文本}
- (void)startRecognize:(nullable SNPVoiceCallback)completion;

/// 停止识别，停止后会触发 startRecognize 的回调并携带最终结果
- (void)stopRecognize;

/// 当前是否正在识别
- (BOOL)isRecognizing;

@end

NS_ASSUME_NONNULL_END
