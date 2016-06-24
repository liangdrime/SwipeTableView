//
//  SwipeHeaderView.h
//  SwipeTableView
//
//  Created by Roy lee on 16/6/24.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SwipeHeaderView;
@protocol SwipeHeaderViewDelegate <NSObject>

- (CGPoint)minSwipeHeaderViewFrameOrgin;
- (CGPoint)maxSwipeHeaderViewFrameOrgin;

- (void)swipeHeaderViewDidFrameChanged:(SwipeHeaderView *)headerView;

@end

NS_CLASS_AVAILABLE_IOS(7_0) @interface SwipeHeaderView : UIView

@property (nonatomic, weak) id<SwipeHeaderViewDelegate> delegate;

/*!
 *  结束视图的 惯性减速 & 弹性回弹 等效果
 */
- (void)endDecelerating;

@end
