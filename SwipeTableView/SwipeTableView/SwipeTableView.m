//
//  SwipeTableView.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "SwipeTableView.h"
#import <objc/runtime.h>
#import "STPrivateAssistant.h"
#import "UIView+STFrame.h"
#import "STCollectionView.h"

#if !__has_feature(objc_arc)
#error SwipeTableView is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#ifndef ST_CLAMP // return the clamped value
#define ST_CLAMP(_x_, _low_, _high_)  (((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_)))
#endif

const CGFloat SwipeTableViewScrollViewTag = 997998;

@interface SwipeTableView ()<UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>

@property (nonatomic, readwrite) UICollectionView * contentView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIView * headerView;
@property (nonatomic, assign) CGFloat headerInset;
@property (nonatomic, assign) CGFloat barInset;
@property (nonatomic, assign) NSIndexPath * cunrrentItemIndexpath;
@property (nonatomic, readwrite) NSInteger currentItemIndex;
@property (nonatomic, readwrite) UIView * currentItemView;
/// 将要显示的item的index
@property (nonatomic, assign) NSInteger shouldVisibleItemIndex;

/// 记录重用中各个item的contentOffset，最后还原用
@property (nonatomic, strong) NSMutableDictionary * contentOffsetQuene;

/// 记录item的contentSize
@property (nonatomic, strong) NSMutableDictionary * contentSizeQuene;

/// 记录item所要求的最小contentSize
@property (nonatomic, strong) NSMutableDictionary * contentMinSizeQuene;

/// 调用 scrollToItemAtIndex:animated: animated为NO的状态
@property (nonatomic, assign) BOOL switchPageWithoutAnimation;

/// 标记itemView自适应contentSize的状态，用于在observe中修改当前itemView的contentOffset（重设contentSize影响contentOffset）
@property (nonatomic, assign) BOOL isAdjustingcontentSize;

/// 顶部功能 bar 是否一致悬停在顶部，当没有 headerview 只有 headerbar 的情况下
@property (nonatomic, assign) BOOL swipeHeaderBarAlwaysStickyOnTop;

@property (nonatomic, assign) BOOL contentOffsetKVODisabled;

@end

static NSString * const SwipeContentViewCellIdfy       = @"SwipeContentViewCellIdfy";
static const void *SwipeTableViewItemTopInsetKey       = &SwipeTableViewItemTopInsetKey;
static void * SwipeTableViewItemContentInsetContext    = &SwipeTableViewItemContentInsetContext;
static void * SwipeTableViewItemPanGestureContext      = &SwipeTableViewItemPanGestureContext;

@implementation SwipeTableView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

#pragma mark - init

- (void)commonInit {
    // collection view
    self.contentView = [[UICollectionView alloc]initWithFrame:self.bounds collectionViewLayout:self.layout];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.showsHorizontalScrollIndicator = NO;
    _contentView.pagingEnabled = YES;
    _contentView.scrollsToTop = NO;
    _contentView.delegate = self;
    _contentView.dataSource = self;
    [_contentView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:SwipeContentViewCellIdfy];
    
    // disable cell prefetching after iOS10.
    if ([_contentView respondsToSelector:@selector(setPrefetchingEnabled:)]) {
        _contentView.prefetchingEnabled = NO;
    }
    
    // 添加一个空白视图，抵消iOS7后导航栏对scrollview的insets影响 - (void)automaticallyAdjustsScrollViewInsets:
    UIScrollView * autoAdjustInsetsView  = [UIScrollView new];
    autoAdjustInsetsView.scrollsToTop    = NO;
    
    // header 与 bar 的 contentView
    self.headerView = [UIView new];
    
    [self addSubview:autoAdjustInsetsView];
    [self addSubview:_contentView];
    [self addSubview:_headerView];
    
    self.contentOffsetQuene  = [NSMutableDictionary dictionaryWithCapacity:0];
    self.contentSizeQuene    = [NSMutableDictionary dictionaryWithCapacity:0];
    self.contentMinSizeQuene = [NSMutableDictionary dictionaryWithCapacity:0];
    _stickyHeaderTopInset = 0;
    _headerInset = 0;
    _barInset = 0;
    _currentItemIndex = 0;
    _switchPageWithoutAnimation = NO;
    _itemContentTopFromHeaderViewBottom = NO;
    _cunrrentItemIndexpath  = [NSIndexPath indexPathForItem:0 inSection:0];
}

- (UICollectionViewFlowLayout *)layout {
    if (!_layout) {
        self.layout = [[UICollectionViewFlowLayout alloc]init];
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _layout.minimumLineSpacing = 0;
        _layout.minimumInteritemSpacing = 0;
        _layout.sectionInset = UIEdgeInsetsZero;
        _layout.itemSize = self.bounds.size;
    }
    return _layout;
}

#pragma mark - layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    self.layout.itemSize = self.bounds.size;
    self.headerView.st_width = self.st_width;
}

- (void)setSwipeHeaderView:(UIView *)swipeHeaderView {
    if (_swipeHeaderView != swipeHeaderView) {
        [_swipeHeaderView removeFromSuperview];
        [_headerView addSubview:swipeHeaderView];
        
        _swipeHeaderView        = swipeHeaderView;
        _swipeHeaderView.st_top = 0;
        _swipeHeaderBar.st_top  = _swipeHeaderView.st_height;
        _headerView.st_height   = _swipeHeaderBar.st_height + _swipeHeaderView.st_height;
        _headerInset            = _swipeHeaderView.st_height;
        
        [self reloadData];
    }
}

- (void)setSwipeHeaderBar:(UIView *)swipeHeaderBar {
    if (_swipeHeaderBar != swipeHeaderBar) {
        [_swipeHeaderBar removeFromSuperview];
        [_headerView addSubview:swipeHeaderBar];
        
        _swipeHeaderBar           = swipeHeaderBar;
        _headerView.st_height     = _swipeHeaderBar.st_height + _swipeHeaderView.st_height;
        _swipeHeaderBar.st_bottom = _headerView.st_height;
        _barInset                 = _swipeHeaderBar.st_height;
        
        [self reloadData];
    }
}

- (void)setStickyHeaderTopInset:(CGFloat)stickyHeaderTopInset {
    _stickyHeaderTopInset = stickyHeaderTopInset;
    [self reloadData];
}

- (void)setAlwaysBounceHorizontal:(BOOL)alwaysBounceHorizontal {
    _alwaysBounceHorizontal = alwaysBounceHorizontal;
    self.contentView.alwaysBounceHorizontal = alwaysBounceHorizontal;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    self.contentView.scrollEnabled = scrollEnabled;
}

- (void)setCurrentItemView:(UIView *)currentItemView {
    // Set property `scrollsToTop` YES of current scrollView only,
    // it will scoll to top when tap status bar.
    _currentItemView.st_scrollView.scrollsToTop = NO;
    _currentItemView = currentItemView;
    _currentItemView.st_scrollView.scrollsToTop = YES;
}

- (UIView *)currentScrollView {
    return _currentItemView.st_scrollView;
}

- (BOOL)swipeHeaderBarAlwaysStickyOnTop {
    // When only have swipeHeaderBar in the header view, this will return YES.
    // That means the bar will always sticky on the top where the `stickyHeaderTopInset` defined.
    return _swipeHeaderBarAlwaysStickyOnTop =  _swipeHeaderBar && !_swipeHeaderView;
}

- (NSInteger)currentItemIndex {
    if (_switchPageWithoutAnimation) {
        return ST_CLAMP(_shouldVisibleItemIndex, 0, [_dataSource numberOfItemsInSwipeTableView:self] - 1);
    }
    return ST_CLAMP(_currentItemIndex, 0, [_dataSource numberOfItemsInSwipeTableView:self] - 1);
}

#pragma mark -

- (void)reloadData {
    CGFloat headerOffsetY = _itemContentTopFromHeaderViewBottom ? -(_headerInset + _barInset) : 0;
    headerOffsetY        -= self.currentScrollView.contentInset.top;
    
    [self swipeHeaderBarAlwaysStickyOnTop];
    [self.contentOffsetQuene removeAllObjects];
    [self.contentSizeQuene removeAllObjects];
    [self.contentMinSizeQuene removeAllObjects];
    [self.contentView reloadData];
    [self.currentItemView.st_scrollView setContentOffset:CGPointMake(0, headerOffsetY)];
}

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    if (index == _currentItemIndex) {
        return;
    }
    _shouldVisibleItemIndex = index;
    // Record content offset of last item.
    CGPoint contentOffset = self.currentItemView.st_scrollView.contentOffset;
    CGSize contentSize    = self.currentItemView.st_scrollView.contentSize;
    self.contentOffsetQuene[@(_currentItemIndex)] = [NSValue valueWithCGPoint:contentOffset];
    self.contentSizeQuene[@(_currentItemIndex)]   = [NSValue valueWithCGSize:contentSize];
    
    // Move the header view to self, and move it to the current itemview until scroll the
    // item to next, it happens on the next event loop when change value of the property
    // `switchPageWithoutAnimation` if the animated is NO.
    //
    // If not, it may make the subviews of heder view disorder when change the superview
    // of the header view frequently.
    [self moveHeaderViewToContentView:self];
    
    // Scroll to the target item index.
    //
    // Note that, the perproty `switchPageWithoutAnimation` should set before, because the
    // method -scrollToItemAtIndexPath will call -scrollViewDidScroll firstly, and call
    // -cellForItemAtIndexPath late.
    self.switchPageWithoutAnimation = !animated;
    NSIndexPath * indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.contentView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
}

#pragma mark - UICollectionView M

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(numberOfItemsInSwipeTableView:)]) {
        return [_dataSource numberOfItemsInSwipeTableView:self];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:SwipeContentViewCellIdfy forIndexPath:indexPath];
    
    UIView * subView = cell.contentView.subviews.firstObject;
    UIScrollView * scrollView = subView.st_scrollView;
    
    if ([_dataSource respondsToSelector:@selector(swipeTableView:viewForItemAtIndex:reusingView:)]) {
        UIView *newSubView = [_dataSource swipeTableView:self viewForItemAtIndex:indexPath.row reusingView:subView];
        scrollView = newSubView.st_scrollView;
        scrollView.scrollsToTop = NO;
        
        // Use contentInsets for the space of common headerview.
        if (_itemContentTopFromHeaderViewBottom) {
            // Set the top inset for common headerview.
            CGFloat topInset = _headerInset + _barInset;
            UIEdgeInsets contentInset = scrollView.contentInset;
            BOOL setTopInset = [objc_getAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey) boolValue];
            if (!setTopInset) {
                // Save the original insets when init the view first.
                scrollView.st_originalInsets = contentInset;
                contentInset.top += topInset;
                scrollView.contentInset = contentInset;
                scrollView.contentOffset = CGPointMake(0, - topInset);  // set default contentOffset after init
                objc_setAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }else {
                // Update
                CGFloat deltaTopInset = topInset - contentInset.top;
                contentInset.top += deltaTopInset;
                scrollView.contentInset = contentInset;
            }
        }
        // Use tableHeaderView or collectionHeaderView for common headerview, if the itemview
        // from datasource is subclass of UITableView or UICollectionView.
        else {
            NSAssert([scrollView isKindOfClass:UITableView.class] || [scrollView isKindOfClass:STCollectionView.class], @"The item view from dataSouce must be kind of UITalbeView class or STCollectionView class!");
            
            // Create the header view used for content view of the common header view `swipeHeaderView`.
            UIView * headerView = [scrollView viewWithTag:911918];
            if (nil == headerView) {
                headerView = [[UIView alloc]init];
                headerView.st_width = newSubView.st_width;
                headerView.tag = 911918;
            }
            CGFloat headerHeight = _headerInset + _barInset;
            BOOL setHeaderHeight = [objc_getAssociatedObject(scrollView, SwipeTableViewItemTopInsetKey) boolValue];
            if (!setHeaderHeight) {
                headerView.st_height += headerHeight;
                scrollView.st_headerView = headerView;
                objc_setAssociatedObject(scrollView, SwipeTableViewItemTopInsetKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                // Save the original insets when init the view first.
                scrollView.st_originalInsets = scrollView.contentInset;
            }else {
                // Update the height of header view, only when the delta height is not 0,
                //
                // If just call `st_headerView` to set header view, it may make the position wrong
                // when change the current item view frequently.
                CGFloat deltHeaderHeight = headerHeight - headerView.st_height;
                headerView.st_height += deltHeaderHeight;
                if (deltHeaderHeight != 0) {
                    scrollView.st_headerView = headerView;
                }
            }
        }
        
        // Add new subview
        if (newSubView != subView) {
            [subView removeFromSuperview];
            [cell.contentView addSubview:newSubView];
            subView = newSubView;
        }
    }
    
    // Adapt for iOS 11.
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
#endif
    
    // Set tag index to the item view.
    scrollView.st_index = indexPath.item;
    _shouldVisibleItemIndex = indexPath.item;
    
    // Add observer to the itemView.
    [self addObserverToItemView:scrollView];
    
    // Init currentItemView
    if (_currentItemIndex == indexPath.item) {
        self.currentItemView = subView;
        // Move headerView to currentItemView first
        [self moveHeaderViewToItemView:scrollView];
    }
    
    UIView * lastItemView = _currentItemView;
    NSInteger lastIndex   = _currentItemIndex;
    
    if (_switchPageWithoutAnimation) {
        // Reset the current itemview and current index.
        self.currentItemView = subView;
        self.currentItemIndex = indexPath.item;
        RunOnNextEventLoop(^{
            // Change the property on the next event loop, to enable the effect on the call back of KVO.
            _switchPageWithoutAnimation = NO;
            
            // Move headerView to currentItemView after scrolling the view. And before this action
            // the header view may be subview of self, if method -scrollToItemAtIndex:animated: was called
            // and the animated is NO.
            [self moveHeaderViewToItemView:scrollView];
            
            // Call end decelerating delegate
            [self scrollViewDidEndDecelerating:collectionView];
        });
    }
    
    // Inject actions to the scrollview
    [self injectActionsToItemView:scrollView];
    
    // Make the itemview's contentoffset same
    [self adjustItemViewContentOffset:scrollView atIndex:indexPath.item fromLastItemView:lastItemView.st_scrollView lastIndex:lastIndex];
    
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableView:shouldSelectItemAtIndex:)]) {
        return [_delegate swipeTableView:self shouldSelectItemAtIndex:indexPath.row];
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableView:didSelectItemAtIndex:)]) {
        [_delegate swipeTableView:self didSelectItemAtIndex:indexPath.row];
    }
}

#pragma mark - Private

- (void)adjustItemViewContentOffset:(UIScrollView *)itemView atIndex:(NSInteger)index fromLastItemView:(UIScrollView *)lastItemView lastIndex:(NSInteger)lastIndex {
    // First init or reloaddata,this condition will be executed when the item init
    // or call the method `reloadData`.
    if (lastIndex == index) {
        CGPoint initContentOffset = CGPointMake(0, -itemView.contentInset.top);
        
        // save current contentOffset before reset contentSize,to reset contentOffset when KVO contentSize.
        _contentOffsetQuene[@(index)] = [NSValue valueWithCGPoint:initContentOffset];
        
        // adjust contentSize
        [self adjustItemViewContentSize:itemView atIndex:index];
        
        return;
    }
    
    // Adjust contentOffset below.
    // Save current item contentoffset
    CGPoint contentOffset  = lastItemView.contentOffset;
    
    if (lastItemView != itemView) {
        self.contentOffsetQuene[@(lastIndex)] = [NSValue valueWithCGPoint:contentOffset];
    }else {
        // 非滚动切换item，由于重用关系前后itemView是同一个
        contentOffset = [self.contentOffsetQuene[@(lastIndex)] CGPointValue];
    }
    // Set the min offset to ignore the changed top insets, such as the item is in pulling to refresh.
    contentOffset.y   = fmax(contentOffset.y, -lastItemView.st_originalInsets.top);
    
    // 取出记录的offset
    CGFloat topMarginOffsetY  = _itemContentTopFromHeaderViewBottom ? -_barInset : _headerInset;
    topMarginOffsetY         -= _stickyHeaderTopInset;
    
    NSValue *offsetObj = [self.contentOffsetQuene objectForKey:@(index)];
    CGPoint itemContentOffset = [offsetObj CGPointValue];
    if (nil == offsetObj) {  // init
        itemContentOffset.y = topMarginOffsetY;
    }
    
    // 顶部悬停
    // floor 处理，避免不同屏幕尺寸像素影响，导致旧的item无法设置之前记录的offset
    topMarginOffsetY = STFloatPixelFloor(topMarginOffsetY);
    if (contentOffset.y >= topMarginOffsetY) {
        // 比较过去记录的offset与当前应该设的offset，决定是否对齐相邻item的顶部
        if (itemContentOffset.y < topMarginOffsetY) {
            itemContentOffset.y = topMarginOffsetY;
        }
    }else {
        itemContentOffset.y = contentOffset.y;
    }
    
    // Save current contentOffset before reset contentSize,to reset contentOffset when KVO contentSize.
    _contentOffsetQuene[@(index)] = [NSValue valueWithCGPoint:itemContentOffset];
    
    // Adjust contentsize
    [self adjustItemViewContentSize:itemView atIndex:index];
    
    // Reset contentOffset after reset contentSize
    itemView.contentOffset = itemContentOffset;
    
}

- (void)adjustItemViewContentSize:(UIScrollView *)itemView atIndex:(NSInteger)index {
    // get the min required height of contentSize
    CGFloat minRequireHeight = itemView.st_height + _headerInset - _stickyHeaderTopInset;
    if (_itemContentTopFromHeaderViewBottom) {
        minRequireHeight = itemView.st_height - _barInset - _stickyHeaderTopInset;
    }
    
    // 修正contentInset的bottom的影响
    minRequireHeight  -= itemView.contentInset.bottom;
    // 重设contentsize的高度
    CGSize contentSize = itemView.contentSize;
    contentSize.height = MAX(minRequireHeight, contentSize.height);
    
    // set shoudVisible item contentOffset and contentSzie
    if (_shouldAdjustContentSize) {
        CGSize minRequireContentSize   = CGSizeMake(contentSize.width, minRequireHeight);
        _contentSizeQuene[@(index)]    = [NSValue valueWithCGSize:contentSize];
        _contentMinSizeQuene[@(index)] = [NSValue valueWithCGSize:minRequireContentSize];
        if (itemView.contentSize.height > minRequireHeight) return;
        itemView.contentSize           = contentSize;
        _isAdjustingcontentSize        = YES;
        // 自适应contentSize的状态在当前事件循环之后解除
        RunOnNextEventLoop(^{
            _isAdjustingcontentSize = NO;
        });
    }
}

- (void)pureMoveHeaderViewToItemView:(UIScrollView *)scrollView {
    UIView * superView = _itemContentTopFromHeaderViewBottom ? scrollView : scrollView.st_headerView;
    if (_headerView.superview == superView || self.swipeHeaderBarAlwaysStickyOnTop) {
        return;
    }
    
    // Add the header view to current item view,
    // Note that, can not call -removeFromSuperView here, it will hold the main quene some times.
    [superView addSubview:_headerView];
}

- (void)moveHeaderViewToItemView:(UIScrollView *)scrollView {
    if (_contentView.isTracking) {
        return;
    }
    UIView * superView = _itemContentTopFromHeaderViewBottom ? scrollView : scrollView.st_headerView;
    if (_headerView.superview == superView || self.swipeHeaderBarAlwaysStickyOnTop) {
        return;
    }else if ([self isTopBarSticky]) {
        return;
    }
    
    CGFloat top = _itemContentTopFromHeaderViewBottom? -_headerView.st_height : 0;
    if ([self isHeaderSticky]) {
        // Change the position of header view in its superview of a scrollview.
        CGFloat moveOffsetY = scrollView.contentOffset.y + scrollView.st_originalInsets.top;
        top += moveOffsetY;
    }
    _headerView.st_top = top;
    
    // Add the header view to current item view,
    // Note that, can not call -removeFromSuperView here, it will hold the main quene some times.
    [superView addSubview:_headerView];
}

- (void)moveHeaderViewToContentView:(UIView *)contentView {
    if (_headerView.superview == contentView) {
        return;
    }
    CGPoint origin = [_headerView.superview convertPoint:_headerView.frame.origin toView:contentView];
    _headerView.st_top = origin.y;
    
    // Add the header view to current item view,
    // Note that, can not call -removeFromSuperView here, it will hold the main quene some times.
    [contentView addSubview:_headerView];
}

- (BOOL)isHeaderSticky {
    CGFloat offsetY       = self.currentScrollView.contentOffset.y;
    CGFloat minTopOffset  = _itemContentTopFromHeaderViewBottom ? -_headerView.st_height : 0;
    minTopOffset         -= self.currentScrollView.st_originalInsets.top;
    
    BOOL alwaysSticky = _swipeHeaderAlwaysOnTop || _swipeHeaderBarAlwaysStickyOnTop;
    BOOL headerSticky = offsetY < minTopOffset && alwaysSticky;
    
    return headerSticky;
}

- (BOOL)isTopBarSticky {
    CGFloat offsetY       = self.currentScrollView.contentOffset.y;
    CGFloat stickyOffsetY = _itemContentTopFromHeaderViewBottom ? -_barInset : _headerInset;
    stickyOffsetY        -= _stickyHeaderTopInset;
    
    BOOL barSticky = offsetY > stickyOffsetY;
    return barSticky;
}

#pragma mark - Observe & Inject Action

- (void)injectActionsToItemView:(UIScrollView *)scrollView {
    // Inject scroll view did scroll action from the scrollview delegate.
    // In the mew method, update the position of common header view.
    [self injectScrollAction:@selector(st_scrollViewDidScroll:) toView:scrollView fromSelector:@selector(scrollViewDidScroll:)];
    // Inject reloadData action to monitor if should adjust contentsize.
    //
    // If the table or collection shriks when call -realodData, the offset will be adjusted.
    // So must record the offset before reloaddata, it will be used to reset offset when
    // reloaddata completed.
    if (_shouldAdjustContentSize) {
        __weak typeof(self) weakSelf = self;
        __weak typeof(scrollView) weakScrollView = scrollView;
        [self injectReloadAction:^{
            [weakSelf st_reloadData:weakScrollView];
        } toView:scrollView];
    }
}

- (void)addObserverToItemView:(UIScrollView *)view {
    __weak typeof(self) weakSelf = self;
    [STObserver observerForObject:view keyPath:@"contentOffset" callBackBlock:^(UIScrollView *object, id newValue, id oldValue) {
        [weakSelf scrollViewContentOffsetDidChanged:object newValue:newValue oldValue:oldValue];
    }];
    [STObserver observerForObject:view keyPath:@"contentSize" callBackBlock:^(UIScrollView *object, id newValue, id oldValue) {
        [weakSelf scrollViewContentSizeDidChanged:object newValue:newValue oldValue:oldValue];
    }];
}

- (void)st_scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL isContentViewScrolling   = _contentView.isDragging || _contentView.isDecelerating;
    BOOL currentItemViewNotScroll = isContentViewScrolling || scrollView != _currentItemView.st_scrollView;
    if (currentItemViewNotScroll || _stickyHeaderDiabled) {
        return;
    }
    
    CGFloat offsetY         = scrollView.contentOffset.y;
    CGFloat topStickyOffset = _headerInset;
    CGFloat minTopOffset    = 0;
    if (_itemContentTopFromHeaderViewBottom) {
        topStickyOffset     = -_barInset;
        minTopOffset        = -_headerView.st_height;
    }
    topStickyOffset        -= _stickyHeaderTopInset;
    minTopOffset           -= scrollView.st_originalInsets.top;
    
    // Sticky the header view
    if (offsetY > topStickyOffset) {
        [self moveHeaderViewToContentView:self];
        _headerView.st_bottom = _barInset + _stickyHeaderTopInset;
    }
    else {
        [self pureMoveHeaderViewToItemView:scrollView];
        
        BOOL alwaysSticky = _swipeHeaderAlwaysOnTop || _swipeHeaderBarAlwaysStickyOnTop;
        if (offsetY < minTopOffset && alwaysSticky) {
            CGPoint topPoint = [scrollView convertPoint:CGPointMake(0, scrollView.st_originalInsets.top) fromView:self];
            _headerView.st_top = topPoint.y;
        }else {
            _headerView.st_top = 0;
        }
    }
    
    // If enable adjust contentsize of itemview, should store the offset when the scrollview
    // is scrolling, it will be used to reset the original offset when the contentsize changed.
    //
    // But if the tableview or collection view is invoking -reloadData, this -scrollViewDidScroll
    // will be called, and it will adjust offset if the table shrinks. Then the offset will be
    // great changed.
    // So in this case, not store the offset.
    if (_shouldAdjustContentSize && !scrollView.isReloadingData) {
        _contentOffsetQuene[@(_currentItemIndex)] = [NSValue valueWithCGPoint:scrollView.contentOffset];
    }
}

- (void)st_reloadData:(id)object {
    if (![object isKindOfClass:[UITableView class]] && ![object isKindOfClass:[UICollectionView class]]) {
        return;
    }
    // Mark the status when the item scrollview began -realodData, and it will
    // be reset when the contentsize be adjusted.
    ((UIScrollView *)object).isReloadingData = YES;
    // Reset the status of item scrollview after reload data.
    RunOnNextEventLoop(^{
        ((UIScrollView *)object).isReloadingData = NO;
    });
}

- (void)scrollViewContentOffsetDidChanged:(UIScrollView *)scrollView newValue:(id)newValue oldValue:(id)oldValue {
    if (_contentOffsetKVODisabled) {
        return;
    }
    
    // If allowed adjust contentsize, use this perproty to indicate the status when the
    // item scrollview is adjusting contentsize.
    //
    // And use the stored offset in the `contentOffsetQuene` to reset the original offset
    // after the item scrollview adjusted contentsize.
    if (_isAdjustingcontentSize) {
        // Get index of the scrollview.
        NSInteger index = scrollView.st_index;
        if (index == _currentItemIndex || index == _shouldVisibleItemIndex) {
            NSValue * offsetObj       = _contentOffsetQuene[@(index)];
            if (nil != offsetObj) {
                CGFloat requireOffsetY    = [offsetObj CGPointValue].y;
                // Follow is change offset of the scroll view, it will not call KVO,
                // but it will call -scrollViewDidScroll:.
                _contentOffsetKVODisabled = YES;
                scrollView.contentOffset  = CGPointMake(scrollView.contentOffset.x, requireOffsetY);
                _contentOffsetKVODisabled = NO;
            };
        }
    }
}

- (void)scrollViewContentSizeDidChanged:(UIScrollView *)scrollView newValue:(id)newValue oldValue:(id)oldValue {
    // adjust contentSize
    if (_shouldAdjustContentSize) {
        
        // Get the real itemview index which will adjust contentsize.
        NSInteger index = scrollView.st_index;
        if (index == _currentItemIndex || index == _shouldVisibleItemIndex) {
            CGFloat contentSizeH      = scrollView.contentSize.height;
            CGSize minRequireSize     = [_contentMinSizeQuene[@(index)] CGSizeValue];
            CGFloat minRequireSizeH   = STFloatPixelRound(minRequireSize.height);
            
            if (contentSizeH < minRequireSizeH) {
                _isAdjustingcontentSize = YES;
                minRequireSize = CGSizeMake(minRequireSize.width, minRequireSizeH);
                if ([scrollView isKindOfClass:STCollectionView.class]) {
                    STCollectionView * collectionView = (STCollectionView *)scrollView;
                    collectionView.minRequireContentSize = minRequireSize;
                }else {
                    scrollView.contentSize = minRequireSize;
                }
                
                RunOnNextEventLoop(^{
                    _isAdjustingcontentSize = NO;
                });
            }
        }
    }
}

#pragma mark - UIScrollView M

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger currentItemIndex = offsetX/scrollView.st_width + 0.5;
    
    if (currentItemIndex != _currentItemIndex) {
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:currentItemIndex inSection:0];
        UIView *currentItemView = [self.contentView cellForItemAtIndexPath:currentIndexPath].contentView.subviews.firstObject;
        
        if (_switchPageWithoutAnimation) {
            if (currentItemView) {
                self.currentItemIndex = currentItemIndex;
                self.currentItemView = currentItemView;
                
                RunOnNextEventLoop(^{
                    // Change the property on the next event loop, to enable the effect on the call back of KVO.
                    _switchPageWithoutAnimation = NO;
                    
                    // Move headerView to currentItemView after scrolling the view. And before this action
                    // the header view may be subview of self, if method -scrollToItemAtIndex:animated: was called
                    // and the animated is NO.
                    [self moveHeaderViewToItemView:_currentItemView.st_scrollView];
                    
                    // Call end decelerating delegate
                    [self scrollViewDidEndDecelerating:scrollView];
                });
                
                // Did index change call back.
                if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewCurrentItemIndexDidChange:)]) {
                    [_delegate swipeTableViewCurrentItemIndexDidChange:self];
                }
            }
            return;
        }
        
        self.currentItemIndex = currentItemIndex;
        self.currentItemView = currentItemView;
        
        // Did index change call back.
        if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewCurrentItemIndexDidChange:)]) {
            [_delegate swipeTableViewCurrentItemIndexDidChange:self];
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewDidScroll:)]) {
        [_delegate swipeTableViewDidScroll:self];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Move the header view to self, to keep the position relative to screen of the header view.
    [self moveHeaderViewToContentView:self];
    
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewWillBeginDragging:)]) {
        [_delegate swipeTableViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // Move the header view to current itemview after scrolling, to enable scroll the header view.
    if (!decelerate) {
        [self moveHeaderViewToItemView:_currentItemView.st_scrollView];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewDidEndDragging:willDecelerate:)]) {
        [_delegate swipeTableViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewWillBeginDecelerating:)]) {
        [_delegate swipeTableViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // Move the header view to current itemview after scrolling, to enable scroll the header view.
    [self moveHeaderViewToItemView:_currentItemView.st_scrollView];
    
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewDidEndDecelerating:)]) {
        [_delegate swipeTableViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewDidEndScrollingAnimation:)]) {
        [_delegate swipeTableViewDidEndScrollingAnimation:self];
    }
}


- (void)dealloc {
    [self setContentMinSizeQuene:nil];
    [self setContentOffsetQuene:nil];
}

@end



@implementation UIScrollView (SwipeTableView)
- (SwipeTableView *)swipeTableView {
    return self.st_swipeTableView;
}
@end



