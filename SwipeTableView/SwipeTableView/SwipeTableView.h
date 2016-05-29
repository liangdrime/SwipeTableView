//
//  SwipeTableView.h
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SwipeTableViewDataSource;
@protocol SwipeTableViewDelegate;
@interface SwipeTableView : UIView

@property (nonatomic, assign) id<SwipeTableViewDelegate>delegate;
@property (nonatomic, assign) id<SwipeTableViewDataSource>dataSource;
@property (nonatomic, strong, readonly) UICollectionView * contentView;

/*!
 *  自定义显示在swipeView顶端的headerView，可以通过setter方法动态设置
 */
@property (nonatomic, strong) UIView * swipeHeaderView;

/*!
 *  自定义显示在swipeView顶端的headerBar，可以通过setter方法动态设置
 */
@property (nonatomic, strong) UIView * swipeHeaderBar;

/*!
 *  swipeView顶端headerView顶部的留白inset，这个属性可以设置顶部导航栏的inset，默认是 64
 */
@property (nonatomic, assign) CGFloat swipeHeaderTopInset;

/*!
 *  当前itemView的index，在滑动swipeView过程中，index的变化以显示窗口的1/2宽为界限
 */
@property (nonatomic, readonly) NSInteger currentItemIndex;

/*!
 *  当前itemView，在滑动swipeView过程中，currentItemView的变化以显示窗口的1/2宽为界限
 */
@property (nonatomic, strong, readonly) UIScrollView * currentItemView;

/*!
 *  swipeView是否开启水平bounce效果，默认为 YES
 */
@property (nonatomic, assign) BOOL alwaysBounceHorizontal;

/*!
 *  在实际中，不同item的listView显示的数据多少不同。当数据多的item垂直滚动后，水平切换到数据少的item时，后一个item垂直滚动的范围便小于前一个item的垂直滚动范围。此时操作当前的item会产生一个回弹的动作。
 *  设置这个属性，可以调整前后两个item的滚动范围一致。默认 shouldAdjustContentSize 是 NO
 */
@property (nonatomic, assign) BOOL shouldAdjustContentSize;

@property (nonatomic, assign) BOOL scrollEnabled;


- (void)reloadData;
- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;

@end



@protocol SwipeTableViewDataSource <NSObject>

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView;
- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view;

@end

@protocol SwipeTableViewDelegate <NSObject>

@optional
- (void)swipeTableViewDidScroll:(SwipeTableView *)swipeView;
- (void)swipeTableViewCurrentItemIndexDidChange:(SwipeTableView *)swipeView;
- (void)swipeTableViewWillBeginDragging:(SwipeTableView *)swipeView;
- (void)swipeTableViewDidEndDragging:(SwipeTableView *)swipeView willDecelerate:(BOOL)decelerate;
- (void)swipeTableViewWillBeginDecelerating:(SwipeTableView *)swipeView;
- (void)swipeTableViewDidEndDecelerating:(SwipeTableView *)swipeView;
- (void)swipeTableViewDidEndScrollingAnimation:(SwipeTableView *)swipeView;
- (BOOL)swipeTableView:(SwipeTableView *)swipeView shouldSelectItemAtIndex:(NSInteger)index;
- (void)swipeTableView:(SwipeTableView *)swipeView didSelectItemAtIndex:(NSInteger)index;

@end

