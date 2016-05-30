//
//  SwipeTableView.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "SwipeTableView.h"
#import <objc/runtime.h>
#import "UIView+SwipeTableViewFrame.h"


@interface UICollectionViewCell (ScrollView)
- (UIScrollView *)scrollView;
@end



@interface SwipeTableView ()<UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>

@property (nonatomic, strong, readwrite) UICollectionView * contentView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, assign) CGFloat headerInset;
@property (nonatomic, assign) CGFloat barInset;
@property (nonatomic, assign) NSIndexPath * cunrrentItemIndexpath;
@property (nonatomic, readwrite) NSInteger currentItemIndex;
@property (nonatomic, strong, readwrite) UIScrollView * currentItemView;
/*!
 *  将要显示的item的index
 */
@property (nonatomic, assign) NSInteger shouldVisibleItemIndex;

/*!
 *  将要显示的itemView
 */
@property (nonatomic, strong) UIScrollView * shouldVisibleItemView;

/*!
 *  记录重用中各个item的contentOffset，最后还原用
 */
@property (nonatomic, strong) NSMutableDictionary * contentOffsetQuene;

/*!
 *  记录item的contentSize
 */
@property (nonatomic, strong) NSMutableDictionary * contentSizeQuene;

/*!
 *  记录item所要求的最小contentSize
 */
@property (nonatomic, strong) NSMutableDictionary * contentMinSizeQuene;

/*!
 *  调用 scrollToItemAtIndex:animated: animated为NO的状态
 */
@property (nonatomic, assign) BOOL switchPageWithoutAnimation;

/*!
 *  标记itemView自适应contentSize的状态，用于在observe中修改当前itemView的contentOffset（重设contentSize影响contentOffset）
 */
@property (nonatomic, assign) BOOL isAdjustingcontentSize;

@end

static NSString * const SwipeContentViewCellIdfy               = @"SwipeContentViewCellIdfy";
static const void *SwipeTableViewItemTopInsetKey               = &SwipeTableViewItemTopInsetKey;
static void * SwipeTableViewItemContentOffsetContext           = &SwipeTableViewItemContentOffsetContext;
static void * SwipeTableViewItemContentSizeContext             = &SwipeTableViewItemContentSizeContext;

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
    _contentView.delegate = self;
    _contentView.dataSource = self;
    [_contentView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:SwipeContentViewCellIdfy];
    
    // 添加一个空白视图，抵消iOS7后导航栏对scrollview的insets影响 - (void)automaticallyAdjustsScrollViewInsets:
    UIScrollView * autoAdjustInsetsView  = [UIScrollView new];
    
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
    self.swipeHeaderBar.top = _swipeHeaderView.bottom;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self reloadData];
}

- (void)setSwipeHeaderView:(UIView *)swipeHeaderView {
    if (_swipeHeaderView != swipeHeaderView) {
        [_swipeHeaderView removeFromSuperview];
        [self addSubview:swipeHeaderView];
        
        _swipeHeaderView    = swipeHeaderView;
        _swipeHeaderView.y += _swipeHeaderTopInset;
        _headerInset        = _swipeHeaderView.bounds.size.height;
        
        [self reloadData];
        [self layoutIfNeeded];
    }
}

- (void)setSwipeHeaderBar:(UIView *)swipeHeaderBar {
    if (_swipeHeaderBar != swipeHeaderBar) {
        [_swipeHeaderBar removeFromSuperview];
        [self addSubview:swipeHeaderBar];
        
        _swipeHeaderBar    = swipeHeaderBar;
        _swipeHeaderBar.y += _swipeHeaderTopInset;
        _barInset          = _swipeHeaderBar.bounds.size.height;
        
        [self reloadData];
        [self layoutIfNeeded];
    }
}

- (void)setSwipeHeaderTopInset:(CGFloat)swipeHeaderTopInset {
    if (_swipeHeaderView) {
        _swipeHeaderView.y += (swipeHeaderTopInset - _swipeHeaderTopInset);
    }
    if (_swipeHeaderBar) {
        _swipeHeaderBar.y += (swipeHeaderTopInset - _swipeHeaderTopInset);
    }
    _swipeHeaderTopInset = swipeHeaderTopInset;
    
    [self reloadData];
    [self layoutIfNeeded];
}

- (void)setAlwaysBounceHorizontal:(BOOL)alwaysBounceHorizontal {
    _alwaysBounceHorizontal = alwaysBounceHorizontal;
    self.contentView.alwaysBounceHorizontal = alwaysBounceHorizontal;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    self.contentView.scrollEnabled = scrollEnabled;
}

#pragma mark -

- (void)reloadData {
    CGFloat headerOffsetY = - (_headerInset + _swipeHeaderTopInset + _barInset);
    [self.currentItemView setContentOffset:CGPointMake(0, headerOffsetY)];
    [self.contentView reloadData];
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
    UIScrollView * subView = cell.scrollView;
    if (_dataSource && [_dataSource respondsToSelector:@selector(swipeTableView:viewForItemAtIndex:reusingView:)]) {
        UIScrollView * newSubView = [_dataSource swipeTableView:self viewForItemAtIndex:indexPath.row reusingView:subView];
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
            CGFloat deltTopInset = topInset - contentInset.top;
            contentInset.top += deltTopInset;
            newSubView.contentInset = contentInset;
        }
        
        if (newSubView != subView) {
            [subView removeFromSuperview];
            [cell addSubview:newSubView];
            subView = newSubView;
        }
    }
    // reuse item view observe
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentOffset"];
    [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentSize"];
    self.shouldVisibleItemIndex = indexPath.item;
    self.shouldVisibleItemView  = subView;
    [_shouldVisibleItemView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
    [_shouldVisibleItemView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
    
    UIScrollView * lastItemView = _currentItemView;
    NSInteger lastIndex         = _currentItemIndex;
    
    if (_switchPageWithoutAnimation) {
        // observe
        [_currentItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_currentItemView removeObserver:self forKeyPath:@"contentSize"];
        [subView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
        [subView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
        _currentItemIndex           = indexPath.row;
        _currentItemView            = subView;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _switchPageWithoutAnimation = !_switchPageWithoutAnimation;
        });
    }
    
    // make the itemview'contentoffset same
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
    // adjust content offset
    if (lastIndex == index) {
        return;
    }
    // save current item contentoffset
    CGPoint contentOffset  = lastItemView.contentOffset;
    CGSize itemContentSize = itemView.contentSize;
    if (lastItemView != itemView) {
        self.contentOffsetQuene[@(lastIndex)] = [NSValue valueWithCGPoint:contentOffset];
    }else {
        // 非滚动切换item，由于重用关系前后itemView是同一个
        contentOffset = [self.contentOffsetQuene[@(lastIndex)] CGPointValue];
        // 取出之前存储的contentSize，如果没有就用当前itemView的contentSize
        NSValue * contentSizeObj = self.contentSizeQuene[@(index)];
        if (nil != contentSizeObj) {
            itemContentSize = [contentSizeObj CGSizeValue];
        }else {
            itemContentSize = itemView.contentSize;
        }
    }
    
    // 取出记录的offset
    CGFloat topMarginOffsetY  = - (_swipeHeaderTopInset + _barInset);
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
    
    // adjust contentsize
    CGFloat contentHeight        = itemView.height + itemContentOffset.y;    // scrollview内容的高度
    CGFloat maxVisibleRectHeight = itemView.height - (_swipeHeaderTopInset + _barInset);  // 显示屏幕的最大高度
    CGFloat minRequireHeight     = MIN(maxVisibleRectHeight, contentHeight);   // 最小要求的contentsize的高度
    itemContentSize.height       = MAX(minRequireHeight, itemContentSize.height);  // 重设contentsize的高度
    
    // save current data
    _contentOffsetQuene[@(index)] = [NSValue valueWithCGPoint:itemContentOffset];
    
    // set shoudVisible item contentOffset and contentSzie
    if (_shouldAdjustContentSize) {
        CGSize minRequireContentSize   = CGSizeMake(itemContentSize.width, minRequireHeight);
        _contentSizeQuene[@(index)]    = [NSValue valueWithCGSize:itemContentSize];
        _contentMinSizeQuene[@(index)] = [NSValue valueWithCGSize:minRequireContentSize];
        itemView.contentSize           = itemContentSize;
        _isAdjustingcontentSize        = YES;
        // 自适应contentSize的状态在当前事件循环之后解除
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _isAdjustingcontentSize = NO;
        });
    }
    itemView.contentOffset = itemContentOffset;
    
}

#pragma mark - observe

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == SwipeTableViewItemContentOffsetContext) {
        
        CGFloat newOffsetY        = [change[NSKeyValueChangeNewKey] CGPointValue].y;
        CGFloat topMarginInset    = _swipeHeaderTopInset + _barInset;
        UIView * headerBottomView = _swipeHeaderBar?_swipeHeaderBar:_swipeHeaderView;
        
        if (newOffsetY < -topMarginInset) {
            headerBottomView.bottom = fabs(newOffsetY);
        }else {
            headerBottomView.bottom = topMarginInset;
        }
        if (_swipeHeaderBar) {
            _swipeHeaderView.bottom = _swipeHeaderBar.top;
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
    
    if (context == SwipeTableViewItemContentSizeContext) {
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
            if (contentSizeH < minRequireSize.height) {
                _isAdjustingcontentSize = YES;
                scrollView.contentSize = minRequireSize;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    _isAdjustingcontentSize = NO;
                });
            }
        }
    }
}

#pragma mark - UIScrollView M

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger currentItemIndex = offsetX/scrollView.width + 0.5;
    
    if (currentItemIndex != _currentItemIndex) {
        if (_switchPageWithoutAnimation) {
            return;
        }
        // observe
        [_currentItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_currentItemView removeObserver:self forKeyPath:@"contentSize"];
        
        _currentItemIndex = currentItemIndex;
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:_currentItemIndex inSection:0];
        self.currentItemView = [self.contentView cellForItemAtIndexPath:currentIndexPath].scrollView;
        
        [_currentItemView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentOffsetContext];
        [_currentItemView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:SwipeTableViewItemContentSizeContext];
        
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
        [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentOffset"];
        [_shouldVisibleItemView removeObserver:self forKeyPath:@"contentSize"];
    }
    @catch (NSException *exception) {
        
    }
    [self setContentMinSizeQuene:nil];
    [self setContentOffsetQuene:nil];
}

@end







@implementation UICollectionViewCell (ScrollView)

- (UIScrollView *)scrollView {
    UIScrollView * scrollView = nil;
    for (UIView * subView in self.subviews) {
        if ([subView isKindOfClass:UIScrollView.class]) {
            scrollView = (UIScrollView *)subView;
            break;
        }
    }
    return scrollView;
}

@end




