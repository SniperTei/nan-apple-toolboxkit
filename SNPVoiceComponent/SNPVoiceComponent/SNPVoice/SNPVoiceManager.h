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

/// 是否回调中间识别结果（默认 YES）。
/// YES 时识别过程中会多次回调：data: {"text": 中间文本, "final": NO}，结束时回调最终结果 final = YES；
/// NO 时仅在结束时回调一次最终结果。
@property (nonatomic, assign) BOOL recognizePartialResults;

/// 是否静音自动停止（默认 NO，即手动调用 stopRecognize 停止）。
/// YES 时，连续 recognizeAutoStopSilenceSeconds 秒没有检测到说话（含从头到尾没说话的情况），
/// 会自动停止识别并回调最终结果。说话的判定综合两个信号：输入音频能量、识别中间结果有新文本。
@property (nonatomic, assign) BOOL recognizeAutoStopEnabled;

/// 静音自动停止的静音时长（秒，默认 2.0，仅 recognizeAutoStopEnabled 为 YES 时生效）
@property (nonatomic, assign) NSTimeInterval recognizeAutoStopSilenceSeconds;

/// 开始识别，回调 data: {"text": 识别文本, "final": 是否最终结果}。
/// recognizePartialResults 为 YES 时会多次回调中间结果（final = NO），最终结果 final = YES；
/// 为 NO 时仅在识别结束（停止/出错/超时）时回调一次。
- (void)startRecognize:(nullable SNPVoiceCallback)completion;

/// 停止识别（手动停止 / 静音自动停止均会触发 startRecognize 的回调并携带最终结果）
- (void)stopRecognize;

/// 当前是否正在识别
- (BOOL)isRecognizing;

@end

NS_ASSUME_NONNULL_END
