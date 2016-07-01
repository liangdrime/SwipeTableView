//
//  STHeaderView.h
//  SwipeTableView
//
//  Created by Roy lee on 16/6/24.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STHeaderView;
@protocol STHeaderViewDelegate <NSObject>

- (CGPoint)minHeaderViewFrameOrgin;
- (CGPoint)maxHeaderViewFrameOrgin;

@optional
- (void)headerViewDidFrameChanged:(STHeaderView *)headerView;
- (void)headerView:(STHeaderView *)headerView didPan:(UIPanGestureRecognizer *)pan;
- (void)headerView:(STHeaderView *)headerView didPanGestureRecognizerStateChanged:(UIPanGestureRecognizer *)pan;

@end


/**
   采用 UIKitDynamics 实现自定的 swipeHeaderView
 
   只有当`SwipeTableView`的 swipeHeaderView 是`STHeaderView`或其子类的实例,拖拽`SwipeTableView`的 swipeHeaderView才能 同时滚动`SwipeTableView`的 currentItemView.
 */
NS_CLASS_AVAILABLE_IOS(7_0) @interface STHeaderView : UIView

@property (nonatomic, readonly, strong) UIPanGestureRecognizer * panGestureRecognizer;
@property (nonatomic, weak) id<STHeaderViewDelegate> delegate;
@property (nonatomic, readonly, getter=isTracking)     BOOL tracking;
@property (nonatomic, readonly, getter=isDragging)     BOOL dragging;
@property (nonatomic, readonly, getter=isDecelerating) BOOL decelerating;

/**
 *  结束视图的 惯性减速 & 弹性回弹 等效果
 */
- (void)endDecelerating;

@end
