//
//  SNPVoiceManager.m
//  SNPVoiceComponent
//

#import "SNPVoiceManager.h"
#import "SNPVoiceConst.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

float const SNPVoiceDefaultRate = 0.5f; // AVSpeechUtteranceDefaultSpeechRate

/// 静音检测的音量阈值（RMS），低于该值视为没在说话，可按机型实际采集到的音量微调
static float const SNPVoiceSilenceRMSThreshold = 0.02f;

/// 计算音频缓冲区的均方根（RMS），用于粗略判断有没有人在说话
static float SNPVoiceBufferRMS(AVAudioPCMBuffer *buffer) {
    float *samples = buffer.floatChannelData[0];
    UInt32 frameLength = buffer.frameLength;
    if (frameLength == 0 || samples == NULL) { return 0.0f; }
    double sum = 0.0;
    for (UInt32 i = 0; i < frameLength; i++) {
        sum += (double)samples[i] * samples[i];
    }
    return (float)sqrt(sum / frameLength);
}

@interface SNPVoiceManager () <AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, strong, nullable) AVSpeechUtterance *currentUtterance;
@property (nonatomic, copy, nullable) SNPVoiceCallback speakCompletion;
@property (nonatomic, copy, nullable) SNPVoiceCallback cancelCompletion;

@property (nonatomic, strong, nullable) SFSpeechRecognizer *recognizer;
@property (nonatomic, strong, nullable) AVAudioEngine *audioEngine;
@property (nonatomic, strong, nullable) SFSpeechRecognitionTask *recognizeTask;
@property (nonatomic, strong, nullable) SFSpeechAudioBufferRecognitionRequest *recognizeRequest;
@property (nonatomic, copy, nullable) SNPVoiceCallback recognizeCompletion;
/// 上一次中间结果的文本，用于去重（同样文本不重复回调）
@property (nonatomic, copy, nullable) NSString *lastInterimText;
/// 最近一次检测到说话的时间（tap 线程与识别回调线程都会读写，属性默认 atomic 足够）
@property (nonatomic, strong, nullable) NSDate *lastSpeechDate;
/// 权限申请等待期标记，防止弹窗期间重复 startRecognize 覆盖任务导致 engine 泄漏
@property (nonatomic, assign) BOOL recognizeStarting;
@end

@implementation SNPVoiceManager

+ (instancetype)sharedManager {
    static SNPVoiceManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
        _recognizePartialResults = YES;
        _recognizeAutoStopEnabled = NO;
        _recognizeAutoStopSilenceSeconds = 2.0;
    }
    return self;
}

#pragma mark - 语音播报

- (BOOL)isSpeaking {
    return self.synthesizer.isSpeaking;
}

- (void)speak:(NSString *)text completion:(nullable SNPVoiceCallback)completion {
    [self speak:text rate:SNPVoiceDefaultRate completion:completion];
}

- (void)speak:(NSString *)text rate:(float)rate completion:(nullable SNPVoiceCallback)completion {
    if (text.length == 0) {
        [self callback:completion result:[SNPVoiceResult failureWithCode:SNPVoiceCodeSpeakTextEmpty msg:@"text is empty"]];
        return;
    }
    rate = MIN(MAX(rate, 0.0), 1.0);
    // 有未结束的旧任务（正在播或刚入队还没出声）时停掉它：
    // 旧回调立即以 cancelled 结束，并把 currentUtterance 置空，
    // 让稍后到达的 didCancel 代理被忽略，不会误伤新回调。
    // 注意不能用 synthesizer.isSpeaking 判断——utterance 刚入队还没出声时它是 NO
    if (self.currentUtterance != nil) {
        SNPVoiceCallback oldCompletion = self.speakCompletion;
        SNPVoiceCallback oldCancel = self.cancelCompletion;
        self.speakCompletion = nil;
        self.cancelCompletion = nil;
        self.currentUtterance = nil;
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        [self callback:oldCompletion result:[SNPVoiceResult successWithMsg:@"cancelled" data:@{@"cancelled": @YES}]];
        [self callback:oldCancel result:[SNPVoiceResult successWithMsg:@"cancelled" data:@{@"cancelled": @YES}]];
    }

    self.speakCompletion = completion;
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    utterance.rate = rate;
    self.currentUtterance = utterance;
    [self.synthesizer speakUtterance:utterance];
}

- (void)cancelSpeak:(nullable SNPVoiceCallback)completion {
    if (self.currentUtterance == nil) {
        [self callback:completion result:[SNPVoiceResult successWithMsg:@"success" data:@{@"cancelled": @NO}]];
        return;
    }
    self.cancelCompletion = completion;
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (utterance != self.currentUtterance) { return; } // 已被新播报替换的旧任务
    self.currentUtterance = nil;
    SNPVoiceCallback completion = self.cancelCompletion ?: self.speakCompletion;
    self.cancelCompletion = nil;
    self.speakCompletion = nil;
    [self callback:completion result:[SNPVoiceResult successWithMsg:@"success" data:@{@"text": utterance.speechString}]];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (utterance != self.currentUtterance) { return; } // 已被新播报替换的旧任务
    self.currentUtterance = nil;
    SNPVoiceResult *result = [SNPVoiceResult successWithMsg:@"success" data:@{@"cancelled": @YES}];
    SNPVoiceCallback speakCompletion = self.speakCompletion;
    SNPVoiceCallback cancelCompletion = self.cancelCompletion;
    self.speakCompletion = nil;
    self.cancelCompletion = nil;
    [self callback:speakCompletion result:result];
    [self callback:cancelCompletion result:result];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didEncounterError:(AVSpeechUtterance *)utterance error:(NSError *)error API_AVAILABLE(ios(26.0)) {
    if (utterance != self.currentUtterance) { return; }
    self.currentUtterance = nil;
    SNPVoiceCallback completion = self.speakCompletion;
    self.speakCompletion = nil;
    [self callback:completion result:[SNPVoiceResult failureWithCode:SNPVoiceCodeError msg:error.localizedDescription ?: @"speak error"]];
}

#pragma mark - 语音识别

- (BOOL)isRecognizing {
    return self.audioEngine.isRunning;
}

- (void)startRecognize:(nullable SNPVoiceCallback)completion {
    // recognizeStarting 覆盖权限弹窗等待期：此期间 engine 尚未创建（isRunning = NO），
    // 若放行会导致第二路 beginRecognition 覆盖第一路，旧的 engine/tap 再也无法停止（泄漏）
    if (self.recognizeStarting || self.audioEngine.isRunning) {
        [self callback:completion result:[SNPVoiceResult failureWithCode:SNPVoiceCodeRecognitionError msg:@"already recognizing"]];
        return;
    }
    self.recognizeStarting = YES;
    self.recognizeCompletion = completion;

    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        BOOL speechAllowed = (status == SFSpeechRecognizerAuthorizationStatusAuthorized);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!speechAllowed) {
                [self finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodePermissionDenied msg:@"speech recognition permission denied"]];
                return;
            }
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!granted) {
                        [self finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodePermissionDenied msg:@"microphone permission denied"]];
                        return;
                    }
                    [self beginRecognition];
                });
            }];
        });
    }];
}

- (void)beginRecognition {
    self.recognizeStarting = NO; // 进入实际识别阶段，后续防重入交给 isRunning
    NSLocale *locale = [[NSLocale preferredLanguages].firstObject length] > 0
        ? [NSLocale localeWithLocaleIdentifier:NSLocale.preferredLanguages.firstObject]
        : [NSLocale localeWithLocaleIdentifier:@"zh-CN"];
    SFSpeechRecognizer *recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    if (recognizer == nil || !recognizer.isAvailable) {
        [self finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodeRecognizerUnavailable msg:@"speech recognizer unavailable"]];
        return;
    }
    self.recognizer = recognizer;

    AVAudioEngine *engine = [[AVAudioEngine alloc] init];
    self.audioEngine = engine;

    SFSpeechAudioBufferRecognitionRequest *request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    request.shouldReportPartialResults = self.recognizePartialResults;
    self.recognizeRequest = request;
    self.lastInterimText = nil;
    self.lastSpeechDate = [NSDate date];

    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDuckOthers error:&error];
    if (error) {
        [self finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodeError msg:error.localizedDescription]];
        return;
    }
    [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error) {
        [self finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodeError msg:error.localizedDescription]];
        return;
    }

    AVAudioInputNode *inputNode = engine.inputNode;
    // 装 tap 前防御：瞬态路由切换（蓝牙连接中、通话/FaceTime 占用、配件拔插）时
    // 取到的格式可能为 0Hz/0声道，直接传给 installTap 会触发 AVFAudio 断言闪退
    //（required condition is false: IsFormatSampleRateAndChannelCountValid），这里降级为失败回调
    AVAudioFormat *inputFormat = [inputNode outputFormatForBus:0];
    if (inputFormat == nil || inputFormat.sampleRate == 0 || inputFormat.channelCount == 0) {
        [self finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodeNoInputRoute msg:@"no valid input audio route"]];
        return;
    }
    BOOL autoStopEnabled = self.recognizeAutoStopEnabled;
    NSTimeInterval silenceLimit = MAX(self.recognizeAutoStopSilenceSeconds, 0.1);
    __weak typeof(self) weakSelf = self;
    [inputNode installTapOnBus:0 bufferSize:4096 format:inputFormat block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        [request appendAudioPCMBuffer:buffer];
        if (!autoStopEnabled) { return; }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (SNPVoiceBufferRMS(buffer) > SNPVoiceSilenceRMSThreshold) {
            strongSelf.lastSpeechDate = [NSDate date];
        }
        if (-[strongSelf.lastSpeechDate timeIntervalSinceNow] >= silenceLimit) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf stopRecognize];
            });
        }
    }];

    self.recognizeTask = [self.recognizer recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable taskError) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (result != nil) {
            NSString *text = result.bestTranscription.formattedString ?: @"";
            if (result.isFinal) {
                [strongSelf finishRecognize:[SNPVoiceResult successWithMsg:@"success" data:@{@"text": text, @"final": @YES}]];
            } else if (![text isEqualToString:strongSelf.lastInterimText]) {
                // 中间结果：同样文本不重复回调
                strongSelf.lastInterimText = text;
                // 有新的识别文本 = 一定有人在说话，重置静音计时（与 RMS 检测互补：
                // RMS 盖住识别延迟/失败的盲区，识别回调盖住环境噪音撑高 RMS 的盲区）
                strongSelf.lastSpeechDate = [NSDate date];
                [strongSelf callback:strongSelf.recognizeCompletion
                               result:[SNPVoiceResult successWithMsg:@"interim" data:@{@"text": text, @"final": @NO}]];
            }
        } else if (taskError != nil) {
            [strongSelf finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodeRecognitionError msg:taskError.localizedDescription ?: @"recognition error"]];
        }
    }];

    error = nil;
    [engine prepare];
    [engine startAndReturnError:&error];
    if (error) {
        [self finishRecognize:[SNPVoiceResult failureWithCode:SNPVoiceCodeError msg:error.localizedDescription]];
    }
}

- (void)stopRecognize {
    if (!self.audioEngine.isRunning) { return; }
    // endAudio 让识别任务产出 final 结果，随后在 resultHandler 中回调
    [self.recognizeRequest endAudio];
    [self.audioEngine stop];
    [self.audioEngine.inputNode removeTapOnBus:0];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)finishRecognize:(SNPVoiceResult *)result {
    self.recognizeStarting = NO; // 权限被拒等场景：清掉等待期标记，允许再次 start
    [self.recognizeTask cancel];
    self.recognizeTask = nil;
    self.recognizeRequest = nil;
    self.recognizer = nil;
    self.lastInterimText = nil;
    self.lastSpeechDate = nil;
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        [self.audioEngine.inputNode removeTapOnBus:0];
    }
    self.audioEngine = nil;
    // 去活不依赖 engine 状态：未启动成功就失败的路径（如无有效输入路由）也要还回音频会话
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

    SNPVoiceCallback completion = self.recognizeCompletion;
    self.recognizeCompletion = nil;
    [self callback:completion result:result];
}

#pragma mark - Private

- (void)callback:(nullable SNPVoiceCallback)completion result:(SNPVoiceResult *)result {
    if (completion == nil) { return; }
    if ([NSThread isMainThread]) {
        completion(result.toDictionary);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result.toDictionary);
        });
    }
}

@end
