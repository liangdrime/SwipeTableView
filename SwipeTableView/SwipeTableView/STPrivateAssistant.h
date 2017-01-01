//
//  STPrivateAssistant.h
//  SwipeTableView
//
//  Created by Roylee on 2016/12/11.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SwipeTableView.h"

typedef void(^InjectActionBlock)();

@interface  SwipeTableView (Private)

- (void)injectScrollAction:(SEL)selector toView:(UIScrollView *)scrollView fromSelector:(SEL)fromSelector;
- (void)injectReloadAction:(InjectActionBlock)reloadActionBlock toView:(UIScrollView *)scrollView;
void RunOnNextEventLoop(void(^block)());

@end



@interface UIScrollView (STExtension)

@property (nonatomic, strong) UIView *st_headerView;
@property (nonatomic, assign) NSInteger st_index;
@property (nonatomic, assign) BOOL isReloadingData;
@property (nonatomic, assign) UIEdgeInsets st_originalInsets;
- (SwipeTableView *)st_swipeTableView;

@end



@interface UIView (ScrollView)

- (UIScrollView *)st_scrollView;

@end



typedef void(^STObserverCallBackBlock)(id object, id newValue, id oldValue);

@interface STObserver : NSObject

+ (void)observerForObject:(id)object keyPath:(NSString *)keyPath callBackBlock:(STObserverCallBackBlock)callBackBlock;

@end


