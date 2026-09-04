//
//  SNPVoiceConst.h
//  SNPVoiceComponent
//
//  语音组件错误码 & 回调字段常量
//

#ifndef SNPVoiceConst_h
#define SNPVoiceConst_h

/// 回调字段
FOUNDATION_EXPORT NSString * const SNPVoiceResultCodeKey;
FOUNDATION_EXPORT NSString * const SNPVoiceResultMsgKey;
FOUNDATION_EXPORT NSString * const SNPVoiceResultDataKey;

/// 成功
FOUNDATION_EXPORT NSString * const SNPVoiceCodeSuccess;

/// 通用失败
FOUNDATION_EXPORT NSString * const SNPVoiceCodeError;

/// 播报：文本为空
FOUNDATION_EXPORT NSString * const SNPVoiceCodeSpeakTextEmpty;

/// 识别：权限被拒绝（麦克风 / 语音识别）
FOUNDATION_EXPORT NSString * const SNPVoiceCodePermissionDenied;

/// 识别：识别器不可用（无网络、不支持当前语言等）
FOUNDATION_EXPORT NSString * const SNPVoiceCodeRecognizerUnavailable;

/// 识别：识别过程出错
FOUNDATION_EXPORT NSString * const SNPVoiceCodeRecognitionError;

#endif /* SNPVoiceConst_h */
