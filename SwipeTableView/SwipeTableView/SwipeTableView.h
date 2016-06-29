//
//  SwipeTableView.h
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeHeaderView.h"

@protocol SwipeTableViewDataSource;
@protocol SwipeTableViewDelegate;
@interface SwipeTableView : UIView

@property (nonatomic, assign) id<SwipeTableViewDelegate>delegate;
@property (nonatomic, assign) id<SwipeTableViewDataSource>dataSource;
@property (nonatomic, strong, readonly) UICollectionView * contentView;

/*****************************************************************************************************/
/**
 如果项目想要支持常用的下拉刷新控件，如MJRefresh等。需要满足以下条件：
 
 ①.需要在项目PCH文件或者当前.h文件中设置如下的宏：#define ST_PULLTOREFRESH_HEADER_HEIGHT  xx
 ②.定义的宏中`xx`要与您使用的第三方下拉刷新控件的refreshHeader高度相同：
   `MJRefresh` 为 `MJRefreshHeaderHeight`，`SVPullToRefresh` 为 `SVPullToRefreshViewHeight`
 */
/*****************************************************************************************************/
//#define ST_PULLTOREFRESH_HEADER_HEIGHT  54.0

/*!
 *  自定义显示在swipeView顶端的headerView，可以通过setter方法动态设置
 *  如果想要支持拖动swipeHeaderView，滚动当前页面的currentItemView，需要自定义的header继承自'SwipeHeaderView'，或者以'SwipeHeaderView'的实例作为父视图
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
 *  设置这个属性，可以调整前后两个item的滚动范围一致。默认为 NO
 */
@property (nonatomic, assign) BOOL shouldAdjustContentSize;

/*!
 *  调整当前item的contentSize的最小值是自身frame的高度，还是跟随前一个页面切换时的最大滚动位置
 *  如果设置为NO，当从页面1切换到页面2的时候，页面2的向上的滚动范围最大不会超过切换页面时的对齐范围。 默认值是YES
 */
@property (nonatomic, assign) BOOL adaptMinContentSizeForBounds;

/*!
 *  swipeHeaderBar是否跟随滚动，默认为 NO。如果设置为YES，在没有swipeHeaderView的条件下，可以实现类似网易新闻首页效果
 */
@property (nonatomic, assign) BOOL swipeHeaderBarScrollDisabled;

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

