//
//  ViewController.m
//  SNPLogOCDemo
//
//  Created by zhengnan on 2026/9/3.
//

#import "ViewController.h"
#import "TestLogController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"开始日志测试" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.layer.cornerRadius = 8;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:@selector(startLogTest) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    [NSLayoutConstraint activateConstraints:@[
        [button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [button.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [button.widthAnchor constraintEqualToConstant:200],
        [button.heightAnchor constraintEqualToConstant:50]
    ]];
}

- (void)startLogTest {
    TestLogController *controller = [[TestLogController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
}


@end
