//
//  SwipeTableView.h
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN const CGFloat SwipeTableViewScrollViewTag;

@protocol SwipeTableViewDataSource;
@protocol SwipeTableViewDelegate;
@interface SwipeTableView : UIView

@property (nonatomic, weak) id<SwipeTableViewDelegate>delegate;
@property (nonatomic, weak) id<SwipeTableViewDataSource>dataSource;
@property (nonatomic, readonly, strong) UICollectionView * contentView;


/**
 * 自定义显示在swipeView顶端的headerView，可以通过setter方法动态设置
 *
 * 如果想要支持拖动swipeHeaderView，滚动当前页面的currentItemView，需要自定义的header继承自'STHeaderView'，
 * 或者以'STHeaderView'的实例作为父视图
 */
@property (nonatomic, strong) UIView * swipeHeaderView;

/**
 * 自定义显示在swipeView顶端的headerBar，可以通过setter方法动态设置
 */
@property (nonatomic, strong) UIView * swipeHeaderBar;

/**
 * header & bar 悬停时距离顶部的距离。默认是 0
 */
@property (nonatomic, assign) CGFloat stickyHeaderTopInset;

/**
 * 当前itemView的index，在滑动swipeView过程中，index的变化以显示窗口的1/2宽为界限
 */
@property (nonatomic, readonly) NSInteger currentItemIndex;

/**
 * 当前itemView，在滑动swipeView过程中，currentItemView的变化以显示窗口的1/2宽为界限
 */
@property (nonatomic, readonly, strong) UIView * currentItemView;

/**
 * 当前itemView的 scrollview
 */
@property (nonatomic, readonly, strong) UIScrollView * currentScrollView;

/**
 * 每个 itemview 的内容是否从公共 headerview 的底部开始，默认是 NO。
 * 此时，每个 itemview 的顶部留白将采用 itemview 的 headerview（tableHeaderView & collectionHeaderView）
 *
 * 如果是 YES 的话，顶部公共 header 的留白将采用的是调整每个 itemview 的 contentInsets 的方式
 */
@property (nonatomic, getter=isItemContentTopFromHeaderViewBottom) BOOL itemContentTopFromHeaderViewBottom;

/**
 * swipeView是否开启水平bounce效果，默认为 YES
 */
@property (nonatomic, assign) BOOL alwaysBounceHorizontal;

/**
 * 在实际中，不同item的listView显示的数据多少不同。当数据多的item垂直滚动后，水平切换到数据少的item时，
 * 后一个item垂直滚动的范围便小于前一个item的垂直滚动范围。此时操作当前的item会产生一个回弹的动作。
 *
 * 设置这个属性，可以调整前后两个item的滚动范围一致。默认为 NO
 */
@property (nonatomic, assign) BOOL shouldAdjustContentSize;

/**
 *  向下拖动的时候 headerView 是否一直悬停在顶部，默认 NO
 */
@property (nonatomic, assign) BOOL swipeHeaderAlwaysOnTop;

/**
 * 是否禁止顶部悬停，默认是 NO
 */
@property (nonatomic, assign) BOOL stickyHeaderDiabled;

@property (nonatomic, assign) BOOL scrollEnabled;


- (void)reloadData;
- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated;

@end



@protocol SwipeTableViewDataSource <NSObject>

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView;
- (UIView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view;

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


/** Weak refrence of SwipeTableView for UIScrollView */
@interface UIScrollView (SwipeTableView)
@property (nonatomic, readonly, weak) SwipeTableView * swipeTableView;
@end

