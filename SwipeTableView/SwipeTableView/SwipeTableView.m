//
//  SwipeTableView.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "SwipeTableView.h"
#import <objc/runtime.h>
#import "UIView+STFrame.h"
#import "STCollectionView.h"

#if !__has_feature(objc_arc)
#error SwipeTableView is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface UICollectionViewCell (ScrollView)
- (UIScrollView *)scrollView;
@end

@interface UIScrollView (HeaderView)
- (void)setHeaderView:(UIView *)headerView;
- (UIView *)headerView;
@end

#pragma mark - Weak Refrence
@interface STBlockExecutor : NSObject
@property (nonatomic, copy) void(^block)();
- (id)initWithBlock:(void(^)())aBlock;
@end




@interface SwipeTableView ()<UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>

@property (nonatomic, readwrite) UICollectionView * contentView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIView * headerView;
@property (nonatomic, assign) CGFloat headerInset;
@property (nonatomic, assign) CGFloat barInset;
@property (nonatomic, assign) NSIndexPath * cunrrentItemIndexpath;
@property (nonatomic, readwrite) NSInteger currentItemIndex;
@property (nonatomic, readwrite) UIScrollView * currentItemView;
/// 将要显示的item的index
@property (nonatomic, assign) NSInteger shouldVisibleItemIndex;

/// 将要显示的itemView
@property (nonatomic, strong) UIScrollView * shouldVisibleItemView;

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

@end

static NSString * const SwipeContentViewCellIdfy       = @"SwipeContentViewCellIdfy";
static const void *SwipeTableViewItemTopInsetKey       = &SwipeTableViewItemTopInsetKey;
static void * SwipeTableViewItemContentOffsetContext   = &SwipeTableViewItemContentOffsetContext;
static void * SwipeTableViewItemContentSizeContext     = &SwipeTableViewItemContentSizeContext;
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

- (void)setCurrentItemView:(UIScrollView *)currentItemView {
    // Set property `scrollsToTop` YES of currentItemView only,it will scoll to top when tap status bar.
    _currentItemView.scrollsToTop = NO;
    _currentItemView = currentItemView;
    currentItemView.scrollsToTop = YES;
}

#pragma mark -

- (void)reloadData {
    CGFloat headerOffsetY = _itemContentTopFromHeaderViewBottom ? -(_headerInset + _barInset) : 0;
    
    [self.contentOffsetQuene removeAllObjects];
    [self.contentSizeQuene removeAllObjects];
    [self.contentMinSizeQuene removeAllObjects];
    [self.contentView reloadData];
    [self.currentItemView setContentOffset:CGPointMake(0, headerOffsetY)];
}

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    // record last item content offset
    CGPoint contentOffset = self.currentItemView.contentOffset;
    CGSize contentSize    = self.currentItemView.contentSize;
    self.contentOffsetQuene[@(_currentItemIndex)] = [NSValue valueWithCGPoint:contentOffset];
    self.contentSizeQuene[@(_currentItemIndex)]   = [NSValue valueWithCGSize:contentSize];
    
    // Move the header view to self, and move it to the current itemview until scroll the
    // item to next, it happens on the next event loop when change value of the property
    // `switchPageWithoutAnimation` if the animated is NO.
    //
    // If not, it may make the subviews of heder view disorder when change the superview
    // of the header view frequently.
    [self moveHeaderViewToContentView:self];
    
    // Scroll to target item index
    // 此处要先设置状态，因为scrollviewToItem的方法会导致先调用scrollViewDidScroll:然后再cellForRow重用item
    self.switchPageWithoutAnimation = !animated;
    NSIndexPath * indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.contentView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
}

#pragma mark - UICollectionView M

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfItemsInSwipeTableView:)]) {
        return [_dataSource numberOfItemsInSwipeTableView:self];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:SwipeContentViewCellIdfy forIndexPath:indexPath];
    
    UIScrollView * subView = cell.scrollView;
    if (_dataSource && [_dataSource respondsToSelector:@selector(swipeTableView:viewForItemAtIndex:reusingView:)]) {
        UIScrollView * newSubView = [_dataSource swipeTableView:self viewForItemAtIndex:indexPath.row reusingView:subView];
        newSubView.scrollsToTop = NO;
        
        // 公共 header 采用 contentInsets
        if (_itemContentTopFromHeaderViewBottom) {
            // top inset
            CGFloat topInset = _headerInset + _barInset;
            UIEdgeInsets contentInset = newSubView.contentInset;
            BOOL setTopInset = [objc_getAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey) boolValue];
            if (!setTopInset) {
                contentInset.top += topInset;
                newSubView.contentInset = contentInset;
                newSubView.scrollIndicatorInsets = contentInset;
                newSubView.contentOffset = CGPointMake(0, - topInset);  // set default contentOffset after init
                objc_setAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }else {
                // update
                CGFloat deltaTopInset = topInset - contentInset.top;
                contentInset.top += deltaTopInset;
                newSubView.contentInset = contentInset;
                newSubView.scrollIndicatorInsets = contentInset;
            }
            
        }
        // 公共 header 的留白采用 tableHeaderView...
        else {
            NSAssert([newSubView isKindOfClass:UITableView.class] || [newSubView isKindOfClass:STCollectionView.class], @"The item view from dataSouce must be kind of UITalbeView class or STCollectionView class!");
            
            // header view
            UIView * headerView = [newSubView viewWithTag:666];
            if (nil == headerView) {
                headerView = [[UIView alloc]init];
                headerView.st_width = newSubView.st_width;
                headerView.tag = 666;
            }
            CGFloat headerHeight = _headerInset + _barInset;
            BOOL setHeaderHeight = [objc_getAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey) boolValue];
            if (!setHeaderHeight) {
                headerView.st_height += headerHeight;
                objc_setAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }else {
                // update
                CGFloat deltHeaderHeight = headerHeight - headerView.st_height;
                headerView.st_height += deltHeaderHeight;
            }
            newSubView.headerView = headerView;
        }
        
        // add new subview
        if (newSubView != subView) {
            [subView removeFromSuperview];
            [cell.contentView addSubview:newSubView];
            subView = newSubView;
        }
        
    }
    
    // reuse itemView observe
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentOffset"];
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentSize"];
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
    self.shouldVisibleItemIndex = indexPath.item;
    self.shouldVisibleItemView  = subView;
    [_shouldVisibleItemView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
    [_shouldVisibleItemView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
    [_shouldVisibleItemView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemPanGestureContext];
    
    // init currentItemView
    if (!_currentItemView) {
        self.currentItemView = subView;
        [_currentItemView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
        [_currentItemView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
        [_currentItemView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemPanGestureContext];
        // move headerView to currentItemView first
        [self moveHeaderViewToItemView:subView];
    }
    
    UIScrollView * lastItemView = _currentItemView;
    NSInteger lastIndex         = _currentItemIndex;
    
    if (_switchPageWithoutAnimation) {
        // Change observe
        [_currentItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_currentItemView removeObserver:self forKeyPath:@"contentSize"];
        [_currentItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
        [subView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
        [subView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
        [subView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemPanGestureContext];
        self.currentItemIndex = indexPath.row;
        self.currentItemView  = subView;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Change the property on the next event loop, to enable the effect on the call back of KVO.
            _switchPageWithoutAnimation = !_switchPageWithoutAnimation;
            // Move headerView to currentItemView after scrolling the view. And before this action
            // the header view may be subview of self, if method scrollToItemAtIndex:animated: was called
            // and the animated is NO.
            [self moveHeaderViewToItemView:subView];
        });
    }
    
    // make the itemview's contentoffset same
    [self adjustItemViewContentOffset:subView atIndex:indexPath.item fromLastItemView:lastItemView lastIndex:lastIndex];
    
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
    
    /**
     *  First init or reloaddata,this condition will be executed when the item init or call the method `reloadData`.
     */
    if (lastIndex == index) {
        CGPoint initContentOffset = CGPointMake(0, -itemView.contentInset.top);
        
        // save current contentOffset before reset contentSize,to reset contentOffset when KVO contentSize.
        _contentOffsetQuene[@(index)] = [NSValue valueWithCGPoint:initContentOffset];
        
        // adjust contentSize
        [self adjustItemViewContentSize:itemView atIndex:index];
        
        return;
    }
    
    /**
     *  Adjust contentOffset
     */
    // save current item contentoffset
    CGPoint contentOffset  = lastItemView.contentOffset;
    if (lastItemView != itemView) {
        self.contentOffsetQuene[@(lastIndex)] = [NSValue valueWithCGPoint:contentOffset];
    }else {
        // 非滚动切换item，由于重用关系前后itemView是同一个
        contentOffset = [self.contentOffsetQuene[@(lastIndex)] CGPointValue];
    }
    
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
    topMarginOffsetY = floor(topMarginOffsetY);
    if (contentOffset.y >= topMarginOffsetY) {
        // 比较过去记录的offset与当前应该设的offset，决定是否对齐相邻item的顶部
        if (itemContentOffset.y < topMarginOffsetY) {
            itemContentOffset.y = topMarginOffsetY;
        }
    }else {
        itemContentOffset.y = contentOffset.y;
    }
    
    // save current contentOffset before reset contentSize,to reset contentOffset when KVO contentSize.
    _contentOffsetQuene[@(index)] = [NSValue valueWithCGPoint:itemContentOffset];
    
    
    /**
     *  Adjust contentsize
     */
    [self adjustItemViewContentSize:itemView atIndex:index];
    
    // reset contentOffset after reset contentSize
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
        itemView.contentSize           = contentSize;
        _isAdjustingcontentSize        = YES;
        // 自适应contentSize的状态在当前事件循环之后解除
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _isAdjustingcontentSize = NO;
        });
    }
}

- (void)moveHeaderViewToItemView:(UIScrollView *)itemView {
    UIView * superView = _itemContentTopFromHeaderViewBottom ? itemView : itemView.headerView;
    if (_headerView.superview == superView) {
        return;
    }
    _headerView.st_top = _itemContentTopFromHeaderViewBottom ? -_headerView.st_height : 0;
    
    /// Add the header view to current item view,
    /// Note that, can not call -removeFromSuperView here, it will hold the main quene some times.
    [superView addSubview:_headerView];
}

- (void)moveHeaderViewToContentView:(UIView *)contentView {
    if (_headerView.superview == contentView) {
        return;
    }
    CGPoint origin = [_headerView.superview convertPoint:_headerView.frame.origin toView:contentView];
    _headerView.st_top = origin.y;
    
    /// Add the header view to current item view,
    /// Note that, can not call -removeFromSuperView here, it will hold the main quene some times.
    [contentView addSubview:_headerView];
}

#pragma mark - observe

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    /** contentOffset */
    if (context == SwipeTableViewItemContentOffsetContext) {
        
        CGFloat newOffsetY      = [change[NSKeyValueChangeNewKey] CGPointValue].y;
        UIScrollView * itemView = object;
        
        if (!_switchPageWithoutAnimation && !_stickyHeaderDiabled && itemView == _currentItemView) {
            CGFloat topStickyOffset = _itemContentTopFromHeaderViewBottom ? -_barInset : _headerInset;
            topStickyOffset        -= _stickyHeaderTopInset;
            CGFloat maxTopOffset    = _itemContentTopFromHeaderViewBottom ? -_headerView.st_height : 0;
            maxTopOffset           -= _currentItemView.contentInset.top;
            
            // sticky the header view
            if (newOffsetY > topStickyOffset) {
                [self moveHeaderViewToContentView:self];
                _headerView.st_bottom = _barInset + _stickyHeaderTopInset;
            }
            else {
                if (newOffsetY < maxTopOffset && _swipeHeaderAlwaysOnTop) {
                    [self moveHeaderViewToContentView:self];
                    _headerView.st_top = _currentItemView.contentInset.top; // 0 or not.
                }else {
                    [self moveHeaderViewToItemView:_currentItemView];
                }
            }
        }
        
        /*
         * 在自适应contentSize的状态下，itemView初始化后（初始化会导致contentOffset变化，此时又可能会做相邻itemView自适应处理），contentOffset变化受影响，这里做处理保证contentOffset准确
         */
        if (_isAdjustingcontentSize) {
            // 当前scrollview所对应的index
            NSInteger index = _currentItemIndex;
            if (object != _currentItemView) {
                index = _shouldVisibleItemIndex;
            }
            UIScrollView * scrollView = object;
            NSValue * offsetObj       = _contentOffsetQuene[@(index)];
            if (nil != offsetObj) {
                CGFloat contentOffsetY    = scrollView.contentOffset.y;
                CGPoint requireOffset     = [offsetObj CGPointValue];
                // round 之后，解决像素影响问题
                CGFloat requireOffsetY = round(requireOffset.y);
                if (round(contentOffsetY) != requireOffsetY) {
                    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, requireOffsetY);
                }
            }
        }
        
    }
    /** contentSize */
    else if (context == SwipeTableViewItemContentSizeContext) {
        // adjust contentSize
        if (_shouldAdjustContentSize) {
            // 当前scrollview所对应的index
            NSInteger index = _currentItemIndex;
            if (object != _currentItemView) {
                index   = _shouldVisibleItemIndex;
            }
            UIScrollView * scrollView = object;
            CGFloat contentSizeH      = scrollView.contentSize.height;
            CGSize minRequireSize     = [_contentMinSizeQuene[@(index)] CGSizeValue];
            CGFloat minRequireSizeH   = round(minRequireSize.height);
            if (contentSizeH < minRequireSizeH) {
                _isAdjustingcontentSize = YES;
                minRequireSize = CGSizeMake(minRequireSize.width, minRequireSizeH);
                if ([scrollView isKindOfClass:STCollectionView.class]) {
                    STCollectionView * collectionView = (STCollectionView *)scrollView;
                    collectionView.minRequireContentSize = minRequireSize;
                }else {
                    scrollView.contentSize = minRequireSize;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    _isAdjustingcontentSize = NO;
                });
            }
        }
    }
    /** panGestureRecognizer */
    else if (context == SwipeTableViewItemPanGestureContext) {
        UIGestureRecognizerState state = (UIGestureRecognizerState)[change[NSKeyValueChangeNewKey] integerValue];
        switch (state) {
            case UIGestureRecognizerStateBegan:
            {
                /*
                 * 拖拽当前item的时候,移除当前item记录的offset,防止在`shouldAdjustContentSize`模式下适应offset的时候使用旧的offset.
                 */
                [_contentOffsetQuene removeObjectForKey:@(self.currentItemIndex)];
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - UIScrollView M

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger currentItemIndex = offsetX/scrollView.st_width + 0.5;
    
    if (currentItemIndex != _currentItemIndex) {
        if (_switchPageWithoutAnimation) {
            return;
        }
        // Change observe
        [_currentItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_currentItemView removeObserver:self forKeyPath:@"contentSize"];
        [_currentItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
        
        _currentItemIndex = currentItemIndex;
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:_currentItemIndex inSection:0];
        self.currentItemView = [self.contentView cellForItemAtIndexPath:currentIndexPath].scrollView;
        
        [_currentItemView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
        [_currentItemView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
        [_currentItemView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemPanGestureContext];
        
        // Did index change
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
        [self moveHeaderViewToItemView:_currentItemView];
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
    [self moveHeaderViewToItemView:_currentItemView];
    
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
    @try {
        [_currentItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_currentItemView removeObserver:self forKeyPath:@"contentSize"];
        [_currentItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
        [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentSize"];
        [_shouldVisibleItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
    }
    @catch (NSException *exception) {
        
    }
    [self setContentMinSizeQuene:nil];
    [self setContentOffsetQuene:nil];
    
}

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


@implementation UICollectionViewCell (ScrollView)
- (UIScrollView *)scrollView {
    UIScrollView * scrollView = nil;
    for (UIView * subView in self.contentView.subviews) {
        if ([subView isKindOfClass:UIScrollView.class]) {
            scrollView = (UIScrollView *)subView;
            break;
        }
    }
    return scrollView;
}
@end


@implementation UIScrollView (SwipeTableView)
- (SwipeTableView *)swipeTableView {
    SwipeTableView * swipeTableView = objc_getAssociatedObject(self, "swipeTableView");
    if (nil != swipeTableView) {
        return swipeTableView;
    }
    for (UIView * nextRes = self; nextRes; nextRes = nextRes.superview) {
        if ([nextRes isKindOfClass:SwipeTableView.class]) {
            SwipeTableView * swipeTableView = (SwipeTableView *)nextRes;
            // weak refrence by runtime.
            objc_setAssociatedObject(self, "swipeTableView", swipeTableView, OBJC_ASSOCIATION_ASSIGN);
            [swipeTableView st_runAtDealloc:^{
                objc_setAssociatedObject(self, "swipeTableView", nil, OBJC_ASSOCIATION_ASSIGN);
            }];
            return (SwipeTableView *)nextRes;
        }
    }
    return nil;
}
@end


@implementation UIScrollView (HeaderView)

- (void)setHeaderView:(UIView *)headerView {
    if ([self isKindOfClass:UITableView.class]) {
        [self setValue:headerView forKey:@"tableHeaderView"];
    }else if ([self isKindOfClass:UICollectionView.class]) {
        [self setValue:headerView forKey:@"collectionHeadView"];
    }
}

- (UIView *)headerView {
    if ([self isKindOfClass:UITableView.class]) {
        return [self valueForKey:@"tableHeaderView"];
    }else if ([self isKindOfClass:UICollectionView.class]) {
        return [self valueForKey:@"collectionHeadView"];
    }
    return nil;
}

@end




