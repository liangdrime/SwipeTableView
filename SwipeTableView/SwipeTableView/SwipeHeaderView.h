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

@optional
- (void)swipeHeaderViewDidFrameChanged:(SwipeHeaderView *)headerView;
- (void)swipeHeaderView:(SwipeHeaderView *)headerView didPan:(UIPanGestureRecognizer *)pan;
- (void)swipeHeaderView:(SwipeHeaderView *)headerView didPanGestureRecognizerStateChanged:(UIPanGestureRecognizer *)pan;

@end

NS_CLASS_AVAILABLE_IOS(7_0) @interface SwipeHeaderView : UIView

@property (nonatomic, readonly, strong) UIPanGestureRecognizer * panGestureRecognizer;
@property (nonatomic, weak) id<SwipeHeaderViewDelegate> delegate;
@property (nonatomic, readonly, getter=isTracking)     BOOL tracking;
@property (nonatomic, readonly, getter=isDragging)     BOOL dragging;
@property (nonatomic, readonly, getter=isDecelerating) BOOL decelerating;

/*!
 *  结束视图的 惯性减速 & 弹性回弹 等效果
 */
- (void)endDecelerating;

@end
