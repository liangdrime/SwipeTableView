//
//  STPrivateAssistant.m
//  SwipeTableView
//
//  Created by Roylee on 2016/12/11.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "STPrivateAssistant.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface STInvocationAgency : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, copy) InjectActionBlock block;

@end

@implementation STInvocationAgency

- (instancetype)initWithTarget:(id)target action:(SEL)selector {
    self = [super init];
    if (self) {
        self.target = target;
        self.selector = selector;
    }
    return self;
}

- (instancetype)initWithTarget:(id)target block:(InjectActionBlock)block {
    self = [super init];
    if (self) {
        self.target = target;
        self.block = block;
    }
    return self;
}

- (void)invoke:(void(^)(id _target, SEL _selector))invocation {
    if (_block) {
        _block();
    }
    else if (invocation) {
        invocation(_target,_selector);
    }
}

@end





static NSString * const STSelectorAliasPrefix = @"st_alias_";

static SEL STAliasForSelector(SEL originalSelector) {
    NSString *selectorName = NSStringFromSelector(originalSelector);
    return NSSelectorFromString([STSelectorAliasPrefix stringByAppendingString:selectorName]);
}

static BOOL STForwardInvocation(id self, NSInvocation *invocation) {
    id target = invocation.target;
    SEL aliasSelector = STAliasForSelector(invocation.selector);
    STInvocationAgency *agency = objc_getAssociatedObject(self, aliasSelector);
    
    // Invoke the new method before the origin method.
    //
    // Replace the target & selector of the invocation, and
    // invoke the replaced method of the replaced target.
    [agency invoke:^(id _target, SEL _selector) {
        invocation.target = _target;
        invocation.selector = _selector;
        [invocation invoke];
    }];
    
    // Reset origin target & method to invoke the origin selector.
    Class class = object_getClass(target);
    BOOL respondsToAlias = [class instancesRespondToSelector:aliasSelector];
    if (respondsToAlias) {
        invocation.target = target;
        invocation.selector = aliasSelector;
        [invocation invoke];
    }
    
    if (agency == nil) return respondsToAlias;
    
    return YES;
}

static void STSwizzleForwardInvocation(Class class) {
    SEL forwardInvocationSEL = @selector(forwardInvocation:);
    Method forwardInvocationMethod = class_getInstanceMethod(class, forwardInvocationSEL);
    
    // Preserve any existing implementation of -forwardInvocation:.
    void (*originalForwardInvocation)(id, SEL, NSInvocation *) = NULL;
    if (forwardInvocationMethod != NULL) {
        originalForwardInvocation = (__typeof__(originalForwardInvocation))method_getImplementation(forwardInvocationMethod);
    }
    
    // Set up a new version of -forwardInvocation:.
    //
    // If the selector has been passed to -injectAction:, invoke
    // the aliased method.
    //
    // If the selector has not been passed to -injectAction:,
    // invoke any existing implementation of -forwardInvocation:. If there
    // was no existing implementation, throw an unrecognized selector
    // exception.
    id newForwardInvocation = ^(id self, NSInvocation *invocation) {
        BOOL matched = STForwardInvocation(self, invocation);
        if (matched) return;
        
        if (originalForwardInvocation == NULL) {
            [self doesNotRecognizeSelector:invocation.selector];
        } else {
            originalForwardInvocation(self, forwardInvocationSEL, invocation);
        }
    };
    
    class_replaceMethod(class, forwardInvocationSEL, imp_implementationWithBlock(newForwardInvocation), "v@:@");
}

static void STNSObjectInjectAction(NSObject *self, SEL selector, NSObject *target, SEL targetSelector) {
    SEL aliasSelector = STAliasForSelector(selector);
    
    @synchronized (self) {
        STInvocationAgency *agency = objc_getAssociatedObject(self, aliasSelector);
        if (agency != nil) return;
        
        agency = [[STInvocationAgency alloc] initWithTarget:target action:targetSelector];
        objc_setAssociatedObject(self, aliasSelector, agency, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        Class class = self.class;
        STSwizzleForwardInvocation(class);
        NSCAssert(class != nil, @"Could not swizzle class of %@", self);
        
        Method targetMethod = class_getInstanceMethod(class, selector);
        if (targetMethod == NULL) {
            // Define the selector to call -forwardInvocation:.
            class_addMethod(class, selector, _objc_msgForward, method_getTypeEncoding(targetMethod));
        } else if (method_getImplementation(targetMethod) != _objc_msgForward) {
            // Make a method alias for the existing method implementation.
            // The alias method will be invoke instead of the existing origin method.
            const char *typeEncoding = method_getTypeEncoding(targetMethod);
            
            BOOL addedAlias __attribute__((unused)) = class_addMethod(class, aliasSelector, method_getImplementation(targetMethod), typeEncoding);
            NSCAssert(addedAlias, @"Original implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), class);
            
            // Redefine the selector to call -forwardInvocation:.
            class_replaceMethod(class, selector, _objc_msgForward, method_getTypeEncoding(targetMethod));
        }
    }
}

static void STNSObjectInjectBlockAction(NSObject *self, SEL selector, NSObject *target,InjectActionBlock block) {
    SEL aliasSelector = STAliasForSelector(selector);
    
    @synchronized (self) {
        STInvocationAgency *agency = objc_getAssociatedObject(self, aliasSelector);
        if (agency != nil) return;
        
        agency = [[STInvocationAgency alloc] initWithTarget:target block:block];
        objc_setAssociatedObject(self, aliasSelector, agency, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        Class class = self.class;
        STSwizzleForwardInvocation(class);
        NSCAssert(class != nil, @"Could not swizzle class of %@", self);
        
        Method targetMethod = class_getInstanceMethod(class, selector);
        if (targetMethod == NULL) {
            // Define the selector to call -forwardInvocation:.
            class_addMethod(class, selector, _objc_msgForward, method_getTypeEncoding(targetMethod));
        } else if (method_getImplementation(targetMethod) != _objc_msgForward) {
            // Make a method alias for the existing method implementation.
            // The alias method will be invoke instead of the existing origin method.
            const char *typeEncoding = method_getTypeEncoding(targetMethod);
            
            BOOL addedAlias __attribute__((unused)) = class_addMethod(class, aliasSelector, method_getImplementation(targetMethod), typeEncoding);
            NSCAssert(addedAlias, @"Original implementation for %@ is already copied to %@ on %@", NSStringFromSelector(selector), NSStringFromSelector(aliasSelector), class);
            
            // Redefine the selector to call -forwardInvocation:.
            class_replaceMethod(class, selector, _objc_msgForward, method_getTypeEncoding(targetMethod));
        }
    }
}




@interface STBlockExecutor : NSObject

@property (nonatomic, copy) void(^block)();
- (id)initWithBlock:(void(^)())aBlock;

@end


@implementation STBlockExecutor

- (id)initWithBlock:(void(^)())aBlock {
    self = [super init];
    if (self) {
        self.block = aBlock;
    }
    return self;
}

- (void)dealloc {
    _block ? _block() : nil;
}

@end




@implementation SwipeTableView (Private)

- (void)injectScrollAction:(SEL)selector toView:(UIScrollView *)scrollView fromSelector:(SEL)fromSelector {
    id delegate = scrollView.delegate;
    STNSObjectInjectAction(delegate, fromSelector, self, selector);
    // Must clear the delegate and reset it after inject the new selector to the
    // delegate of scrollview.
    //
    // If not, the new selector will not be invoked when the delegate not implementation
    // the `fromSelector`.
    //
    // Because apple frameworks will check to see if your class responds to a certain delegate
    // method selector when you set the delegate object, and cache that information.
    // See http://stackoverflow.com/questions/22000433/rac-signalforselector-needs-empty-implementation
    scrollView.delegate = nil;
    scrollView.delegate = delegate;
}

- (void)injectReloadAction:(InjectActionBlock)reloadActionBlock toView:(UIScrollView *)scrollView {
    if (![scrollView respondsToSelector:@selector(reloadData)]) {
        return;
    }
    STNSObjectInjectBlockAction(scrollView, @selector(reloadData), self, reloadActionBlock);
}

void RunOnNextEventLoop(void(^block)()) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (block) {
            block();
        }
    });
}

@end



@implementation NSObject (STDealloc)

- (void)st_runAtDealloc:(void(^)())deallocBlock {
    if (deallocBlock) {
        STBlockExecutor * executor = [[STBlockExecutor alloc]initWithBlock:deallocBlock];
        const void * key = &executor;
        objc_setAssociatedObject(self,
                                 key,
                                 executor,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end




static void *STScrollViewAssociatedKey = &STScrollViewAssociatedKey;

@implementation UIScrollView (STExtension)

- (SwipeTableView *)st_swipeTableView {
    SwipeTableView * swipeTableView = objc_getAssociatedObject(self, STScrollViewAssociatedKey);
    if (swipeTableView) {
        return swipeTableView;
    }
    for (UIView * nextRes = self; nextRes; nextRes = nextRes.superview) {
        if ([nextRes isKindOfClass:SwipeTableView.class]) {
            SwipeTableView * swipeTableView = (SwipeTableView *)nextRes;
            // Weak refrence by runtime.
            objc_setAssociatedObject(self, STScrollViewAssociatedKey, swipeTableView, OBJC_ASSOCIATION_ASSIGN);
            [swipeTableView st_runAtDealloc:^{
                objc_setAssociatedObject(self, STScrollViewAssociatedKey, nil, OBJC_ASSOCIATION_ASSIGN);
            }];
            return (SwipeTableView *)nextRes;
        }
    }
    return nil;
}

- (void)setSt_headerView:(UIView *)headerView {
    if ([self isKindOfClass:UITableView.class]) {
        [self setValue:headerView forKey:@"tableHeaderView"];
    }else if ([self isKindOfClass:UICollectionView.class]) {
        [self setValue:headerView forKey:@"collectionHeadView"];
    }
    [self bringSubviewToFront:headerView];
}

- (UIView *)st_headerView {
    if ([self isKindOfClass:UITableView.class]) {
        return [self valueForKey:@"tableHeaderView"];
    }else if ([self isKindOfClass:UICollectionView.class]) {
        return [self valueForKey:@"collectionHeadView"];
    }
    return nil;
}

- (void)setSt_index:(NSInteger)st_index {
    objc_setAssociatedObject(self, @selector(st_index), @(st_index), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)st_index {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setIsReloadingData:(BOOL)isReloadingData {
    objc_setAssociatedObject(self, @selector(isReloadingData), @(isReloadingData), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isReloadingData {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setSt_originalInsets:(UIEdgeInsets)st_originalInsets {
    objc_setAssociatedObject(self, @selector(st_originalInsets), [NSValue valueWithUIEdgeInsets:st_originalInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)st_originalInsets {
    return [objc_getAssociatedObject(self, _cmd) UIEdgeInsetsValue];
}

@end




@implementation UIView (ScrollView)

- (UIScrollView *)st_scrollView {
    // Find the scroll view of a itemview, it may be the view itself if the view
    // is sub class of UIScrollView.
    // If not, will find the view with tag `SwipeTableViewScrollViewTag`, if the view is nill,
    // will return the first scrollview of subviews in the view, and set its tag `SwipeTableViewScrollViewTag`.
    if ([self isKindOfClass:[UIScrollView class]]) {
        return (UIScrollView *)self;
    }
    __block UIScrollView * scrollView = [self viewWithTag:SwipeTableViewScrollViewTag];
    if (!scrollView) {
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIScrollView class]]) {
                obj.tag    = SwipeTableViewScrollViewTag;
                scrollView = obj;
                *stop = YES;
            }
        }];
    }
    return scrollView;
}

@end




@interface STObserver ()

@property (nonatomic, weak) id weakTarget;
@property (nonatomic, unsafe_unretained) id unsafeTarget;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) STObserverCallBackBlock block;

@end

@implementation STObserver

static BOOL IsAddedObserverToObjectForKeyPath(id object, NSString *keyPath) {
    STObserver *observer = objc_getAssociatedObject(object, (__bridge void *)(keyPath));
    return observer != nil;
}

static void AddObserverToObjectForKeyPath(id object, STObserver *observer, NSString *keyPath) {
    void *key = (__bridge void *)(keyPath);
    objc_setAssociatedObject(object, key, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc {
    NSObject *target;
    
    @synchronized (self) {
        _block = nil;
        
        // The target should still exist at this point, because we still need to
        // tear down its KVO observation. Therefore, we can use the unsafe
        // reference (and need to, because the weak one will have been zeroed by
        // now).
        target = self.unsafeTarget;
        
        _unsafeTarget = nil;
    }
    
    [target removeObserver:self forKeyPath:_keyPath];
}

- (instancetype)initWithObject:(id)object keyPath:(NSString *)keyPath block:(STObserverCallBackBlock)block {
    self = [super init];
    if (self) {
        NSObject *strongTarget = object;
        self.weakTarget = object;
        self.unsafeTarget = strongTarget;
        self.keyPath = keyPath;
        self.block = block;
        [_unsafeTarget addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}

+ (void)observerForObject:(id)object keyPath:(NSString *)keyPath callBackBlock:(STObserverCallBackBlock)callBackBlock {
    if (IsAddedObserverToObjectForKeyPath(object,keyPath)) {
        return;
    }
    STObserver *observer = [[STObserver alloc] initWithObject:object keyPath:keyPath block:callBackBlock];
    AddObserverToObjectForKeyPath(object, observer, keyPath);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (_block) {
        _block(object, change[NSKeyValueChangeNewKey], change[NSKeyValueChangeOldKey]);
    }
}

@end



