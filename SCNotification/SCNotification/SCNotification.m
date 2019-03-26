//
//  SCNotification.m
//  自定义消息中心
//
//  Created by SeacenLiu on 2019/3/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import "SCNotification.h"
#import <objc/runtime.h>

/** 监听响应者释放类
 * 关联到监听者上
 * 随监听者的释放而释放
 * 再调用 dealloc 进行通知中心的移除
 */
@interface SCObserverMonitor : NSObject
@property (nonatomic, strong) NSString *observerId;
@end

@implementation SCObserverMonitor
/**
 变量的释放顺序各种不确定，可能走 SCObserverMonitor 的 dealloc 时，
 observer 响应者对象已经释放了，所以不直接使用observer响应者对象对比做释放操作。
 */
- (void)dealloc {
    NSLog(@"%@ dealloc", self);
    [SCNotificationCenter.defaultCenter removeObserverId:self.observerId];
}
@end

@implementation SCNotification

- (instancetype)initWithName:(NSString*)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo {
    if (self = [super init]) {
        _name = name;
        _object = object;
        _userInfo = userInfo;
    }
    return self;
}

+ (instancetype)notificationWithName:(NSString*)aName object:(nullable id)anObject {
    return [[self alloc] initWithName:aName object:anObject userInfo:nil];
}

+ (instancetype)notificationWithName:(NSString*)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo {
    return [[self alloc] initWithName:aName object:anObject userInfo:aUserInfo];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithName:_name object:_object userInfo:_userInfo];
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.object forKey:@"object"];
    [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [super init]) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _object = [aDecoder decodeObjectForKey:@"object"];
        _userInfo = [aDecoder decodeObjectForKey:@"userInfo"];
    }
    return self;
}

@end

// 监听者信息存储模型类
@interface SCObserverInfoModel : NSObject
@property (nonatomic, weak) id observer; // 弱引用
/** 不需要...有autorelease */
//@property (nonatomic, strong) id observer_strong; // 强引用 用于 Block 处理
@property (nonatomic, strong) NSString *observerId; // 用于比较删除
@property (nonatomic, assign) SEL selector; // 方法选择器
@property (nonatomic, weak) id object; // 弱引用
@property (nonatomic, copy) NSString *name; // SCNotification.name
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, copy) void(^block)(SCNotification *note);
@end
@implementation SCObserverInfoModel
- (void)dealloc {
    NSLog(@"%@ dealloc", self);
}
@end

static NSString *key_observersDic_noContent = @"key_observersDic_noContent";
@interface SCNotificationCenter ()
@property (nonatomic, class, strong) SCNotificationCenter *defaultCenter;
/**
 * 树形结构
 * 便于发送通知的时候，直接就能通过key直接找到对应的通知信息了
 * 有效降低了时间复杂度
 * 一对多（一个通知对多个监听者）
 */
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableArray<SCObserverInfoModel*>*> *observersDict;
@end

@implementation SCNotificationCenter

#pragma mark - 添加
/** 添加观察者通过 SEL - addTarget */
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString*)aName object:(nullable id)anObject {
    if (!observer || !aSelector) {
        return;
    }
    SCObserverInfoModel *observerInfo = [SCObserverInfoModel new];
    observerInfo.observer = observer;
    observerInfo.observerId = [NSString stringWithFormat:@"%@", observer];
    observerInfo.selector = aSelector;
    observerInfo.object = anObject;
    observerInfo.name = aName;
    
    [self addObserverInfo:observerInfo];
 }

/** 添加观察者通过 Block */
- (id <NSObject>)addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(SCNotification *note))block {
    if (!block) return nil;
    SCObserverInfoModel *observerInfo = [SCObserverInfoModel new];
    observerInfo.object = obj;
    observerInfo.name = name;
    observerInfo.queue = queue;
    observerInfo.block = block;
    NSObject *observer = [NSObject new];
    observerInfo.observer = observer; // observer_strong 强引用 observer 避免 observer 提前释放
    observerInfo.observerId = [NSString stringWithFormat:@"%@", observer];
    
    [self addObserverInfo:observerInfo];
    return observer;
}

/** 添加订阅者信息 */
- (void)addObserverInfo:(SCObserverInfoModel *)observerInfo {
    // 为 observer 关联一个释放监听器
//    id resultObserver = observerInfo.observer ? observerInfo.observer : observerInfo.observer_strong;
    id resultObserver = observerInfo.observer;
    if (!resultObserver) {
        return;
    }
    SCObserverMonitor *monitor = [SCObserverMonitor new];
    monitor.observerId = observerInfo.observerId;
    const char *keyOfmonitor = [[NSString stringWithFormat:@"%@", monitor] UTF8String];
    objc_setAssociatedObject(resultObserver, keyOfmonitor, monitor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 添加监听者字典
    NSMutableDictionary *observersDict = SCNotificationCenter.defaultCenter.observersDict;
    @synchronized (observersDict) {
        NSString *key = (observerInfo.name && [observerInfo.name isKindOfClass:NSString.class]) ? observerInfo.name : key_observersDic_noContent;
        if (observersDict[key]) {
            [observersDict[key] addObject:observerInfo];
        } else {
            observersDict[key] = [NSMutableArray arrayWithObject:observerInfo];
        }
    }
}

#pragma mark - 发送通知
/** 发送通知 */
- (void)postNotification:(SCNotification *)notification {
    if (!notification) return;
    NSMutableDictionary *observersDict = SCNotificationCenter.defaultCenter.observersDict;
    NSMutableArray *observerArr = observersDict[notification.name];
    if (observerArr) {
        [observerArr enumerateObjectsUsingBlock:^(SCObserverInfoModel*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.block) { // 通过 Block 回调
                if (obj.queue) { // 根据操作队列分配
                    NSBlockOperation *opreation = [NSBlockOperation blockOperationWithBlock:^{
                        obj.block(notification);
                    }];
                    NSOperationQueue *queue = obj.queue;
                    [queue addOperation:opreation];
                } else { // 默认在哪个线程发送就在哪个线程响应
                    obj.block(notification);
                }
            } else { // 执行 SEL 回调
                if (!obj.object || obj.object == notification.object) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    obj.observer ? [obj.observer performSelector:obj.selector withObject:notification] : nil;
#pragma clang diagnostic pop
                }
            }
        }];
    }
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject {
    [self postNotification:[SCNotification notificationWithName:aName object:anObject]];
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    [self postNotification:[SCNotification notificationWithName:aName object:anObject userInfo:aUserInfo]];
}

#pragma mark - 移除
/** 自动移除通知 */
- (void)removeObserverId:(NSString *)observerId name:(NSString *)aName object:(id)anObject {
    if (!observerId) return;
    NSMutableDictionary *observersDict = SCNotificationCenter.defaultCenter.observersDict;
    @synchronized (observersDict) {
        if (aName && [aName isKindOfClass:[NSString class]]) {
            [self array_removeObserverId:observerId object:anObject array:observersDict[aName]];
        } else {
            [observersDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray *obj, BOOL * _Nonnull stop) {
                [self array_removeObserverId:observerId object:anObject array:obj];
            }];
        }
    }
}

- (void)array_removeObserverId:(NSString *)observerId object:(id)anObject array:(NSMutableArray *)array {
    @autoreleasepool {
        [array.copy enumerateObjectsUsingBlock:^(SCObserverInfoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.observerId isEqualToString:observerId] && (!anObject || anObject == obj.object)) { // 对 anObject 的处理
                [array removeObject:obj];
                return;
            }
        }];
    }
}

/** 移除通知 */
- (void)removeObserver:(id)observer name:(NSString *)aName object:(id)anObject {
    if (!observer) return;
    [self removeObserverId:[NSString stringWithFormat:@"%@", observer] name:aName object:anObject];
}

- (void)removeObserver:(id)observer {
    [self removeObserver:observer name:nil object:nil];
}

/** 通过observerId移除 */
- (void)removeObserverId:(NSString *)observerId {
    [self removeObserverId:observerId name:nil object:nil];
}

#pragma mark - 单例相关方法
static SCNotificationCenter *_defaultCenter = nil;
+ (void)setDefaultCenter:(SCNotificationCenter *)x {
    if (!self.defaultCenter) {
        _defaultCenter = x;
    }
}
+ (SCNotificationCenter *)defaultCenter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultCenter = [SCNotificationCenter new];
        _defaultCenter.observersDict = [NSMutableDictionary dictionary];
    });
    return _defaultCenter;
}

@end
