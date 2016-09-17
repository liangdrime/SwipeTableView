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

@interface UIScrollView (PanGestureRecognizer)
- (void)setHeaderView:(UIView *)headerView;
void STSwizzleMethod(Class c, SEL origSEL, SEL newSEL);
@end

#pragma mark - Weak Refrence
@interface STBlockExecutor : NSObject
@property (nonatomic, copy) void(^block)();
- (id)initWithBlock:(void(^)())aBlock;
@end




@interface SwipeTableView ()<UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate,STHeaderViewDelegate>

@property (nonatomic, strong, readwrite) UICollectionView * contentView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, assign) CGFloat headerInset;
@property (nonatomic, assign) CGFloat barInset;
@property (nonatomic, assign) NSIndexPath * cunrrentItemIndexpath;
@property (nonatomic, readwrite) NSInteger currentItemIndex;
@property (nonatomic, strong, readwrite) UIScrollView * currentItemView;
/**
 *  将要显示的item的index
 */
@property (nonatomic, assign) NSInteger shouldVisibleItemIndex;

/**
 *  将要显示的itemView
 */
@property (nonatomic, strong) UIScrollView * shouldVisibleItemView;

/**
 *  记录重用中各个item的contentOffset，最后还原用
 */
@property (nonatomic, strong) NSMutableDictionary * contentOffsetQuene;

/**
 *  记录item的contentSize
 */
@property (nonatomic, strong) NSMutableDictionary * contentSizeQuene;

/**
 *  记录item所要求的最小contentSize
 */
@property (nonatomic, strong) NSMutableDictionary * contentMinSizeQuene;

/**
 *  调用 scrollToItemAtIndex:animated: animated为NO的状态
 */
@property (nonatomic, assign) BOOL switchPageWithoutAnimation;

/**
 *  标记itemView自适应contentSize的状态，用于在observe中修改当前itemView的contentOffset（重设contentSize影响contentOffset）
 */
@property (nonatomic, assign) BOOL isAdjustingcontentSize;

/**
 *  设置当前scrollViewItem的contentOffset时，在KVO中不对contentOffset进行观察处理
 */
@property (nonatomic, assign) BOOL contentOffsetKVODisabled;


@end

static NSString * const SwipeContentViewCellIdfy       = @"SwipeContentViewCellIdfy";
static const void *SwipeTableViewItemTopInsetKey       = &SwipeTableViewItemTopInsetKey;
static void * SwipeTableViewItemContentOffsetContext   = &SwipeTableViewItemContentOffsetContext;
static void * SwipeTableViewItemContentSizeContext     = &SwipeTableViewItemContentSizeContext;
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
    self.contentView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:self.layout];
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
    
    [self addSubview:autoAdjustInsetsView];
    [self addSubview:_contentView];
    
    self.contentOffsetQuene  = [NSMutableDictionary dictionaryWithCapacity:0];
    self.contentSizeQuene    = [NSMutableDictionary dictionaryWithCapacity:0];
    self.contentMinSizeQuene = [NSMutableDictionary dictionaryWithCapacity:0];
    _swipeHeaderTopInset = 64;
    _headerInset = 0;
    _barInset = 0;
    _currentItemIndex = 0;
    _switchPageWithoutAnimation = YES;
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
    self.swipeHeaderBarScrollDisabled &= nil == _swipeHeaderView;
    self.swipeHeaderBar.st_top = _swipeHeaderView.st_bottom;
    if (_swipeHeaderBarScrollDisabled) {
        _swipeHeaderBar.st_top = _swipeHeaderTopInset;
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self reloadData];
}

- (void)setSwipeHeaderView:(UIView *)swipeHeaderView {
    if (_swipeHeaderView != swipeHeaderView) {
        [_swipeHeaderView removeFromSuperview];
        [self addSubview:swipeHeaderView];
        
        _swipeHeaderView       = swipeHeaderView;
        _swipeHeaderView.st_y += _swipeHeaderTopInset;
        _headerInset           = _swipeHeaderView.bounds.size.height;
        
        BOOL isSTHeaderView = [swipeHeaderView isKindOfClass:STHeaderView.class];
        if (isSTHeaderView) {
            [(STHeaderView *)swipeHeaderView setDelegate:self];
        }

        [self reloadData];
        [self layoutIfNeeded];
    }
}

- (void)setSwipeHeaderBar:(UIView *)swipeHeaderBar {
    if (_swipeHeaderBar != swipeHeaderBar) {
        [_swipeHeaderBar removeFromSuperview];
        [self addSubview:swipeHeaderBar];
        
        _swipeHeaderBar       = swipeHeaderBar;
        _swipeHeaderBar.st_y += _swipeHeaderTopInset;
        _barInset             = _swipeHeaderBar.bounds.size.height;
        
        [self reloadData];
        [self layoutIfNeeded];
    }
}

- (void)setSwipeHeaderTopInset:(CGFloat)swipeHeaderTopInset {
    if (_swipeHeaderView) {
        _swipeHeaderView.st_y += (swipeHeaderTopInset - _swipeHeaderTopInset);
    }
    if (_swipeHeaderBar) {
        _swipeHeaderBar.st_y += (swipeHeaderTopInset - _swipeHeaderTopInset);
    }
    _swipeHeaderTopInset = swipeHeaderTopInset;
    
    [self reloadData];
    [self layoutIfNeeded];
}

- (void)setAlwaysBounceHorizontal:(BOOL)alwaysBounceHorizontal {
    _alwaysBounceHorizontal = alwaysBounceHorizontal;
    self.contentView.alwaysBounceHorizontal = alwaysBounceHorizontal;
}

- (void)setSwipeHeaderBarScrollDisabled:(BOOL)swipeHeaderBarScrollDisabled {
    _swipeHeaderBarScrollDisabled = swipeHeaderBarScrollDisabled && nil == _swipeHeaderView;
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
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    CGFloat headerOffsetY = - (_headerInset + _swipeHeaderTopInset + _barInset);
#else
    CGFloat headerOffsetY = - _swipeHeaderTopInset;
#endif
    [self setSwitchPageWithoutAnimation:YES]; // to set current itemview after reloaddata
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
    // scroll to target item index
    /*！
     * 此处要先设置状态，因为scrollviewToItem的方法会导致先调用scrollViewDidScroll:然后再cellForRow重用item
     */
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
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    UIScrollView * subView = cell.scrollView;
    if (_dataSource && [_dataSource respondsToSelector:@selector(swipeTableView:viewForItemAtIndex:reusingView:)]) {
        UIScrollView * newSubView = [_dataSource swipeTableView:self viewForItemAtIndex:indexPath.row reusingView:subView];
        newSubView.scrollsToTop = NO;
        // top inset
        CGFloat topInset = _headerInset + _barInset + _swipeHeaderTopInset;
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
        
        if (newSubView != subView) {
            [subView removeFromSuperview];
            [cell.contentView addSubview:newSubView];
            subView = newSubView;
        }
    }
#else
    UIScrollView * subView = cell.scrollView;
    if (_dataSource && [_dataSource respondsToSelector:@selector(swipeTableView:viewForItemAtIndex:reusingView:)]) {
        UIScrollView * newSubView = [_dataSource swipeTableView:self viewForItemAtIndex:indexPath.row reusingView:subView];
        NSAssert([newSubView isKindOfClass:UITableView.class] || [newSubView isKindOfClass:STCollectionView.class], @"The item view from dataSouce must be kind of UITalbeView class or STCollectionView class!");
        newSubView.scrollsToTop = NO;
        // top inset
        CGFloat headerHeight = _headerInset + _barInset;
        UIEdgeInsets contentInset = newSubView.contentInset;
        contentInset.top = _swipeHeaderTopInset;
        newSubView.contentInset = contentInset;
        // header view
        UIView * headerView = [newSubView viewWithTag:666];
        if (nil == headerView) {
            headerView = [[UIView alloc]init];
            headerView.st_width = newSubView.st_width;
            headerView.tag = 666;
        }
        BOOL setHeaderHeight = [objc_getAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey) boolValue];
        if (!setHeaderHeight) {
            headerView.st_height += headerHeight;
            objc_setAssociatedObject(newSubView, SwipeTableViewItemTopInsetKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }else {
            // update
            CGFloat deltHeaderHeight = headerHeight - headerView.st_height;
            headerView.st_height += deltHeaderHeight;
        }
        contentInset.top = headerView.st_height + _swipeHeaderTopInset;
        newSubView.scrollIndicatorInsets = contentInset;
        newSubView.headerView = headerView;
        
        if (newSubView != subView) {
            [subView removeFromSuperview];
            [cell.contentView addSubview:newSubView];
            subView = newSubView;
        }
    }
#endif
    // reuse item view observe
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentOffset"];
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentSize"];
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
    self.shouldVisibleItemIndex = indexPath.item;
    self.shouldVisibleItemView  = subView;
    [_shouldVisibleItemView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
    [_shouldVisibleItemView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
    [_shouldVisibleItemView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemPanGestureContext];
    
    UIScrollView * lastItemView = _currentItemView;
    NSInteger lastIndex         = _currentItemIndex;
    
    if (_switchPageWithoutAnimation) {
        // observe
        [_currentItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_currentItemView removeObserver:self forKeyPath:@"contentSize"];
        [_currentItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
        [subView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
        [subView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
        [subView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemPanGestureContext];
        self.currentItemIndex = indexPath.row;
        self.currentItemView  = subView;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _switchPageWithoutAnimation = !_switchPageWithoutAnimation;
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

#pragma mark -

- (void)adjustItemViewContentOffset:(UIScrollView *)itemView atIndex:(NSInteger)index fromLastItemView:(UIScrollView *)lastItemView lastIndex:(NSInteger)lastIndex {
    
    /** 
     *  First init or reloaddata,this condition will be executed when the item init or call the method `reloadData`.
     */
    if (lastIndex == index) {
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
        CGPoint initContentOffset = CGPointMake(0, -(_swipeHeaderTopInset + _headerInset + _barInset));
#else
        CGPoint initContentOffset = CGPointMake(0, - _swipeHeaderTopInset);
#endif
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
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    CGFloat topMarginOffsetY  = - (_swipeHeaderTopInset + _barInset);
#else
    CGFloat topMarginOffsetY  = _headerInset - _swipeHeaderTopInset;
#endif
    NSValue *offsetObj = [self.contentOffsetQuene objectForKey:@(index)];
    CGPoint itemContentOffset = [offsetObj CGPointValue];
    if (nil == offsetObj) {  // init
        itemContentOffset.y = topMarginOffsetY;
    }
    
    // 顶部悬停
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
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    CGFloat minRequireHeight = itemView.st_height - (_swipeHeaderTopInset + _barInset);
#else
    CGFloat minRequireHeight = itemView.st_height - _swipeHeaderTopInset + _headerInset;
#endif
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

#pragma mark - observe

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    /** contentOffset */
    if (context == SwipeTableViewItemContentOffsetContext) {
        
        if (_contentOffsetKVODisabled) {
            return;
        }
        if (!_swipeHeaderBarScrollDisabled) {
            CGFloat newOffsetY      = [change[NSKeyValueChangeNewKey] CGPointValue].y;
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
            CGFloat topMarginOffset = _swipeHeaderTopInset + _barInset;
            // stick the bar
            if (newOffsetY < - topMarginOffset) {
                if (_swipeHeaderBar) {
                    _swipeHeaderBar.st_bottom  = - newOffsetY;
                    _swipeHeaderView.st_bottom = _swipeHeaderBar.st_top;
                }else {
                    _swipeHeaderView.st_bottom = - newOffsetY;
                }
            }else {
                _swipeHeaderBar.st_bottom  = topMarginOffset;
                // 'fmax' is used to fix the bug below iOS8.3 : the position of the bar will not correct when the swipeHeaderView is outside of the screen. 
                _swipeHeaderView.st_bottom = fmax(- (newOffsetY + _barInset), 0);
            }
#else
            CGFloat topMarginOffset = _headerInset - _swipeHeaderTopInset;
            // stick the bar
            if (newOffsetY < topMarginOffset) {
                if (_swipeHeaderView) {
                    _swipeHeaderView.st_top = - newOffsetY;
                    _swipeHeaderBar.st_top  = _swipeHeaderView.st_bottom;
                }else {
                    _swipeHeaderBar.st_top  = - newOffsetY;
                }
            }else {
                _swipeHeaderBar.st_top  = _swipeHeaderTopInset;
                // 'fmax' is used to fix the bug below iOS8.3 : the position of the bar will not correct when the swipeHeaderView is outside of the screen.
                _swipeHeaderView.st_top = fmax(- newOffsetY, - _headerInset);
            }
#endif
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
                if (round(contentOffsetY) != round(requireOffset.y)) {
                    scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, round(requireOffset.y));
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

#pragma mark - STHeaderViewDelegate

- (CGPoint)minHeaderViewFrameOrgin {
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    CGFloat minOrginY = - ((self.currentItemView.contentSize.height + _headerInset + _barInset) - self.currentItemView.bounds.size.height);
#else
    CGFloat minOrginY = - (self.currentItemView.contentSize.height - self.currentItemView.bounds.size.height);
#endif
    // 'fmin' is used to fix the case when contentSize is smaller than bounds
    minOrginY = fmin(minOrginY, _swipeHeaderTopInset);
    return CGPointMake(0, minOrginY);
}

- (CGPoint)maxHeaderViewFrameOrgin {
    return CGPointMake(0, _swipeHeaderTopInset);
}

- (void)headerViewDidFrameChanged:(STHeaderView *)headerView {
    
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    CGFloat offsetY = - (headerView.frame.origin.y + _headerInset + _barInset);
#else
    CGFloat offsetY = - headerView.frame.origin.y;
#endif
    _swipeHeaderBar.st_top = fmax(_swipeHeaderTopInset, headerView.st_bottom);
    
    _contentOffsetKVODisabled = YES;
    CGPoint contentOffset = self.currentItemView.contentOffset;
    contentOffset.y       = offsetY;
    self.currentItemView.contentOffset = contentOffset;
    _contentOffsetKVODisabled = NO;
}

- (void)headerView:(STHeaderView *)headerView didPan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateEnded) {
        CGFloat refreshHeaderHeight = CGFLOAT_MAX;
        BOOL shouldRefresh = NO;
#if defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
        refreshHeaderHeight = ST_PULLTOREFRESH_HEADER_HEIGHT;
        shouldRefresh = YES;
#endif
        if (_delegate && [_delegate respondsToSelector:@selector(swipeTableView:heightForRefreshHeaderAtIndex:)]) {
            refreshHeaderHeight = [_delegate swipeTableView:self heightForRefreshHeaderAtIndex:self.currentItemIndex];
        }
        CGFloat offsetY = - headerView.frame.origin.y;
        if (offsetY < - (_swipeHeaderTopInset + refreshHeaderHeight)) {
            if (_delegate && [_delegate respondsToSelector:@selector(swipeTableView:shouldPullToRefreshAtIndex:)]) {
                shouldRefresh = [_delegate swipeTableView:self shouldPullToRefreshAtIndex:self.currentItemIndex];
            }
            if (!shouldRefresh) {
                return;
            }
            [headerView endDecelerating];
            // remove the saved contentOffset, avoid to reset the offset with saved contentOffset when pull to refresh
            [_contentOffsetQuene removeObjectForKey:@(self.currentItemIndex)];
            
            // call KVO to enable the pull-to-refresh
            CGPoint contentOffset = self.currentItemView.contentOffset;
            self.currentItemView.contentOffset = contentOffset;
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
        // observe
        [_currentItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_currentItemView removeObserver:self forKeyPath:@"contentSize"];
        [_currentItemView removeObserver:self forKeyPath:@"panGestureRecognizer.state"];
        
        _currentItemIndex = currentItemIndex;
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:_currentItemIndex inSection:0];
        self.currentItemView = [self.contentView cellForItemAtIndexPath:currentIndexPath].scrollView;
        
        [_currentItemView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
        [_currentItemView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
        [_currentItemView addObserver:self forKeyPath:@"panGestureRecognizer.state" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemPanGestureContext];
        
        // did index change
        if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewCurrentItemIndexDidChange:)]) {
            [_delegate swipeTableViewCurrentItemIndexDidChange:self];
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewDidScroll:)]) {
        [_delegate swipeTableViewDidScroll:self];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_delegate && [_delegate respondsToSelector:@selector(swipeTableViewWillBeginDragging:)]) {
        [_delegate swipeTableViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
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


@implementation UIScrollView (PanGestureRecognizer)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        STSwizzleMethod([self class],
                        @selector(isDragging),
                        @selector(st_isDragging));
        STSwizzleMethod([self class],
                        @selector(isTracking),
                        @selector(st_isTracking));
        STSwizzleMethod([self class],
                        @selector(isDecelerating),
                        @selector(st_isDecelerating));
    });
}

- (BOOL)st_isTracking {
    SwipeTableView * swipeTableView = self.swipeTableView;
    UIView * headerView = swipeTableView.swipeHeaderView;
    if ([headerView isKindOfClass:STHeaderView.class]) {
        STHeaderView * header = (STHeaderView *)headerView;
        if (header.isTracking && self == swipeTableView.currentItemView) {
            return YES;
        }
        return [self st_isTracking];
    }
    return [self st_isTracking];
}

- (BOOL)st_isDragging {
    SwipeTableView * swipeTableView = self.swipeTableView;
    UIView * headerView = swipeTableView.swipeHeaderView;
    if ([headerView isKindOfClass:STHeaderView.class]) {
        STHeaderView * header = (STHeaderView *)headerView;
        if (header.isDragging && self == swipeTableView.currentItemView) {
            return YES;
        }
        return [self st_isDragging];
    }
    return [self st_isDragging];
}

- (BOOL)st_isDecelerating {
    SwipeTableView * swipeTableView = self.swipeTableView;
    UIView * headerView = swipeTableView.swipeHeaderView;
    if ([headerView isKindOfClass:STHeaderView.class]) {
        STHeaderView * header = (STHeaderView *)headerView;
        if (header.isDecelerating && self == swipeTableView.currentItemView) {
            return YES;
        }
        return [self st_isDecelerating];
    }
    return [self st_isDecelerating];
}

- (void)setHeaderView:(UIView *)headerView {
    if ([self isKindOfClass:UITableView.class]) {
        [self setValue:headerView forKey:@"tableHeaderView"];
    }else if ([self isKindOfClass:UICollectionView.class]) {
        [self setValue:headerView forKey:@"collectionHeadView"];
    }
}

void STSwizzleMethod(Class c, SEL origSEL, SEL newSEL) {
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method newMethod = nil;
    if (!origMethod) {
        origMethod = class_getClassMethod(c, origSEL);
        if (!origMethod) {
            return;
        }
        newMethod = class_getClassMethod(c, newSEL);
        if (!newMethod) {
            return;
        }
    }else{
        newMethod = class_getInstanceMethod(c, newSEL);
        if (!newMethod) {
            return;
        }
    }
    
    if(class_addMethod(c, origSEL, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))){
        class_replaceMethod(c, newSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }else{
        method_exchangeImplementations(origMethod, newMethod);
    }
}

@end




