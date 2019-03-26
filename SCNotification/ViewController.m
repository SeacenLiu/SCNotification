//
//  ViewController.m
//  SCNotification
//
//  Created by SeacenLiu on 2019/3/26.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "ViewController.h"
#import "SCNotification/SCNotification.h"

#define kNotificationKey1 @"kNotificationKey1"

@interface ViewController ()

@end

@implementation ViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"发通知");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationKey1 object:self userInfo:@{@"key": @"value"}];
    [[SCNotificationCenter defaultCenter] postNotificationName:kNotificationKey1 object:self userInfo:@{@"key": @"sc_value"}];
    
    [[SCNotificationCenter defaultCenter] postNotificationName:@"kNotificationKey2" object:self userInfo:@{@"key": @"sc_value2"}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationTest:) name:kNotificationKey1 object:nil];
    [[SCNotificationCenter defaultCenter] addObserver:self selector:@selector(sc_notificationTest:) name:kNotificationKey1 object:nil];
}

- (void)notificationTest:(NSNotification*)note {
    NSLog(@"NSNotificationCenter: %@",note.userInfo[@"key"]);
}

- (void)sc_notificationTest:(SCNotification*)note {
    NSLog(@"SCNotificationCenter: %@",note.userInfo[@"key"]);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
