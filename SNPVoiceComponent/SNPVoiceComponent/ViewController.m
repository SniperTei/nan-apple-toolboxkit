//
//  ViewController.m
//  SNPVoiceComponent
//
//  Created by zhengnan on 2026/9/4.
//

#import "ViewController.h"
#import "SNPVoiceManager.h"

@interface ViewController ()
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UISlider *rateSlider;
@property (nonatomic, strong) UILabel *rateLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    CGFloat top = 80;
    self.rateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, top, self.view.bounds.size.width - 40, 20)];
    self.rateLabel.font = [UIFont systemFontOfSize:13];
    self.rateLabel.text = @"语速：0.50";
    [self.view addSubview:self.rateLabel];
    top += 24;

    self.rateSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, top, self.view.bounds.size.width - 40, 30)];
    self.rateSlider.minimumValue = 0.0;
    self.rateSlider.maximumValue = 1.0;
    self.rateSlider.value = SNPVoiceDefaultRate;
    [self.rateSlider addTarget:self action:@selector(onRateChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.rateSlider];
    top += 40;

    NSArray *titles = @[@"开始播报", @"取消播报", @"同时播报3句", @"开始识别", @"停止识别", @"打断组合测试", @"清空控制台"];
    for (NSUInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = 100 + (int)i;
        button.frame = CGRectMake(20, top + i * 60, self.view.bounds.size.width - 40, 44);
        [button setTitle:titles[i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(onButton:) forControlEvents:UIControlEventTouchUpInside];
        button.layer.cornerRadius = 8;
        button.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [self.view addSubview:button];
    }
    top += titles.count * 60 + 20;

    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(20, top, self.view.bounds.size.width - 40, self.view.bounds.size.height - top - 40)];
    self.logView.editable = NO;
    self.logView.font = [UIFont fontWithName:@"Menlo" size:12];
    self.logView.layer.cornerRadius = 8;
    self.logView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [self.view addSubview:self.logView];
}

- (void)onRateChanged:(UISlider *)slider {
    self.rateLabel.text = [NSString stringWithFormat:@"语速：%.2f", slider.value];
}

- (void)onButton:(UIButton *)sender {
    switch (sender.tag) {
        case 100: { // 开始播报
            SNPVoiceManager *voice = [SNPVoiceManager sharedManager];
            [voice speak:@"你好，这是系统语音播报测试" rate:self.rateSlider.value completion:^(NSDictionary<NSString *, id> *result) {
                [self log:@"speak" result:result];
            }];
            break;
        }
        case 101: { // 取消播报
            SNPVoiceManager *voice = [SNPVoiceManager sharedManager];
            [voice cancelSpeak:^(NSDictionary<NSString *, id> *result) {
                [self log:@"cancelSpeak" result:result];
            }];
            break;
        }
        case 102: { // 同时播报3句：验证打断，只会播报最后一句
            SNPVoiceManager *voice = [SNPVoiceManager sharedManager];
            [voice speak:@"第一句话，这句会被打断" rate:0.5 completion:^(NSDictionary<NSString *, id> *result) {
                [self log:@"speak-1" result:result];
            }];
            [voice speak:@"第二句话，这句也会被打断" rate:0.5 completion:^(NSDictionary<NSString *, id> *result) {
                [self log:@"speak-2" result:result];
            }];
            [voice speak:@"第三句话，只有这句能播完" rate:0.8 completion:^(NSDictionary<NSString *, id> *result) {
                [self log:@"speak-3" result:result];
            }];
            break;
        }
        case 103: { // 开始识别
            SNPVoiceManager *voice = [SNPVoiceManager sharedManager];
            [voice startRecognize:^(NSDictionary<NSString *, id> *result) {
                [self log:@"recognize" result:result];
            }];
            break;
        }
        case 104: { // 停止识别
            [[SNPVoiceManager sharedManager] stopRecognize];
            break;
        }
        case 105: { // 打断组合测试：speak1、speak2、cancelSpeak，然后 speak3
            SNPVoiceManager *voice = [SNPVoiceManager sharedManager];
            [voice speak:@"话术一，马上会被取消" completion:^(NSDictionary<NSString *, id> *result) {
                [self log:@"combo-speak-1" result:result];
            }];
            [voice speak:@"话术二，马上会被取消" completion:^(NSDictionary<NSString *, id> *result) {
                [self log:@"combo-speak-2" result:result];
            }];
            [voice cancelSpeak:^(NSDictionary<NSString *, id> *result) {
                [self log:@"combo-cancel" result:result];
            }];
            [voice speak:@"话术三，最终只有这句能播完" completion:^(NSDictionary<NSString *, id> *result) {
                [self log:@"combo-speak-3" result:result];
            }];
            break;
        }
        case 106: { // 清空控制台
            self.logView.text = @"";
            break;
        }
    }
}

- (void)log:(NSString *)action result:(NSDictionary *)result {
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *line = [NSString stringWithFormat:@"[%@][%@] %@\n\n", action, [NSDate now], text];
    self.logView.text = [self.logView.text stringByAppendingString:line];
    [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length, 0)];
    NSLog(@"[SNPVoiceDemo] %@", line);
}

@end
