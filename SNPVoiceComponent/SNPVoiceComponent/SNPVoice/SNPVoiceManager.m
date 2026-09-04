//
//  SNPVoiceManager.m
//  SNPVoiceComponent
//

#import "SNPVoiceManager.h"
#import "SNPVoiceConst.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

float const SNPVoiceDefaultRate = 0.5f; // AVSpeechUtteranceDefaultSpeechRate

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
    if (self.audioEngine.isRunning) {
        [self callback:completion result:[SNPVoiceResult failureWithCode:SNPVoiceCodeRecognitionError msg:@"already recognizing"]];
        return;
    }
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
    request.shouldReportPartialResults = NO;
    self.recognizeRequest = request;

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
    [inputNode installTapOnBus:0 bufferSize:4096 format:[inputNode outputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        [request appendAudioPCMBuffer:buffer];
    }];

    __weak typeof(self) weakSelf = self;
    self.recognizeTask = [self.recognizer recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable taskError) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (result != nil && result.isFinal) {
            [strongSelf finishRecognize:[SNPVoiceResult successWithMsg:@"success" data:@{@"text": result.bestTranscription.formattedString ?: @""}]];
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
    [self.recognizeTask cancel];
    self.recognizeTask = nil;
    self.recognizeRequest = nil;
    self.recognizer = nil;
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        [self.audioEngine.inputNode removeTapOnBus:0];
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }
    self.audioEngine = nil;

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
