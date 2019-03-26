//
//  SCNotification.h
//  自定义消息中心
//
//  Created by SeacenLiu on 2019/3/9.
//  Copyright © 2019 SeacenLiu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 通知的外部封装 */
@interface SCNotification : NSObject <NSCopying, NSCoding>
/** 通知的名称 */
@property (readonly, copy) NSString* name;
/** 通知的来源对象 */
@property (nullable, readonly, retain) id object;
/** 通知内容 */
@property (nullable, readonly, copy) NSDictionary *userInfo;

- (instancetype)initWithName:(NSString*)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder;

@end

@interface SCNotification (SCNotificationCreation)

+ (instancetype)notificationWithName:(NSString*)aName object:(nullable id)anObject;
+ (instancetype)notificationWithName:(NSString*)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

@end

/****************    Notification Center    ****************/

@interface SCNotificationCenter: NSObject
+ (instancetype)defaultCenter;

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString*)aName object:(nullable id)anObject;

- (void)postNotification:(SCNotification *)notification;
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(nullable NSString*)aName object:(nullable id)anObject;

// 该方法实现有个缺陷：外部对返回值必须强引用，否则返回值会释放，也就无法释放掉这个通知。
- (id <NSObject>)addObserverForName:(nullable NSString*)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(SCNotification *note))block;

- (void)removeObserverId:(NSString *)observerId;
@end

NS_ASSUME_NONNULL_END
