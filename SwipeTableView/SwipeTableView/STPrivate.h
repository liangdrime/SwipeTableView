//
//  STPrivate.h
//  SwipeTableView
//
//  Created by Roylee on 2016/12/11.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SwipeTableView.h"

@interface  SwipeTableView (Private)

- (void)injectScrollAction:(SEL)selector toView:(UIScrollView *)scrollView fromSelector:(SEL)fromSelector;
- (void)injectReloadAction:(SEL)selector toView:(UIScrollView *)scrollView;

@end



@interface UIScrollView (STExtension)

@property (nonatomic, strong) UIView *st_headerView;
- (SwipeTableView *)st_swipeTableView;

@end



@interface UIView (ScrollView)

- (UIScrollView *)st_scrollView;

CGFloat CGFloatPixelFloor(CGFloat value);
CGFloat CGFloatPixelRound(CGFloat value);

@end

