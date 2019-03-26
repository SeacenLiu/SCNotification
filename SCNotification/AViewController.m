//
//  AViewController.m
//  自定义消息中心
//
//  Created by SeacenLiu on 2019/3/10.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "AViewController.h"
#import "SCNotification/SCNotification.h"

#define kNotificationKey2 @"kNotificationKey2"
#define kNotificationKey3 @"kNotificationKey3"

@interface AViewController ()
@property (nonatomic, weak) id observer;
@end

@implementation AViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[SCNotificationCenter defaultCenter] postNotificationName:kNotificationKey2 object:self userInfo:@{@"key": @"sc_value2"}];
    [[SCNotificationCenter defaultCenter] postNotificationName:kNotificationKey3 object:self userInfo:@{@"key": @"sc_value3"}];
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKey3 object:self userInfo:@{@"key": @"sc_value3"}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[SCNotificationCenter defaultCenter] addObserver:self selector:@selector(sc_notificationTest:) name:kNotificationKey2 object:nil];
    self.observer = [[SCNotificationCenter defaultCenter] addObserverForName:kNotificationKey3 object:nil queue:nil usingBlock:^(SCNotification * _Nonnull note) {
        NSLog(@"SC Block! %@", note.userInfo[@"key"]);
    }];
//    [[NSNotificationCenter defaultCenter] addObserverForName:kNotificationKey3 object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        NSLog(@"NS Block! %@", note.userInfo[@"key"]);
//    }];
}

- (void)sc_notificationTest:(SCNotification*)note {
    NSLog(@"AViewController SCNotificationCenter: %@",note.userInfo[@"key"]);
}

- (void)dealloc {
    NSLog(@"AViewController dealloc");
//    [[SCNotificationCenter defaultCenter] removeObserver:self];
//    [[SCNotificationCenter defaultCenter] removeObserver:self.observer];
}

@end
