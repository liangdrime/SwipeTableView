//
//  STCollectionView.m
//  SwipeTableView
//
//  Created by Roy lee on 16/6/29.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "STCollectionView.h"
#import "SwipeTableView.h"

NSString *const STCollectionElementKindSectionHeader = @"STCollectionElementKindSectionHeader";
NSString *const STCollectionHeaderIdfy               = @"STCollectionHeaderIdfy";


@interface STCollectionView ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIView * collectionHeadView;
@property (nonatomic, strong) STCollectionViewFlowLayout * st_collectionViewLayout;

@end


@implementation STCollectionView

- (instancetype)initWithFrame:(CGRect)frame {
    STCollectionViewFlowLayout * flowLayout = [[STCollectionViewFlowLayout alloc]init];
    self = [super initWithFrame:frame collectionViewLayout:flowLayout];
    if (self) {
        [self registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:STCollectionElementKindSectionHeader withReuseIdentifier:STCollectionHeaderIdfy];
        [self setDataSource:self];
        [self setDelegate:self];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        STCollectionViewFlowLayout * flowLayout = [[STCollectionViewFlowLayout alloc]init];
        self.collectionViewLayout = flowLayout;
        [self registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:STCollectionElementKindSectionHeader withReuseIdentifier:STCollectionHeaderIdfy];
        [self setDataSource:self];
        [self setDelegate:self];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [self initWithFrame:frame];
    if (!self) {
        return nil;
    }
    return self;
}

- (STCollectionViewFlowLayout *)st_collectionViewLayout {
    return (STCollectionViewFlowLayout *)self.collectionViewLayout;
}

- (void)setCollectionViewLayout:(STCollectionViewFlowLayout *)collectionViewLayout {
    NSAssert([collectionViewLayout isKindOfClass:STCollectionViewFlowLayout.class], @"collectionViewLayout must be class of STCollectionViewFlowLayout or subclass of STCollectionViewFlowLayout ");
    [super setCollectionViewLayout:collectionViewLayout];
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout

// header view
- (UICollectionReusableView *)collectionView:(STCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView * headerView = nil;
    if (kind == STCollectionElementKindSectionHeader) {
        headerView = [collectionView dequeueReusableSupplementaryViewOfKind:STCollectionElementKindSectionHeader withReuseIdentifier:STCollectionHeaderIdfy forIndexPath:indexPath];
        if (nil != _collectionHeadView) {
            headerView.frame = _collectionHeadView.bounds;
            [headerView addSubview:_collectionHeadView];
        }
    }else {
        if (self.stDataSource && [self.stDataSource respondsToSelector:@selector(stCollectionView:viewForSupplementaryElementOfKind:atIndexPath:)]) {
            headerView = [self.stDataSource stCollectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
        }
    }
    return headerView;
}

// override methods below by subclass
- (NSInteger)numberOfSectionsInCollectionView:(STCollectionView *)collectionView {
    NSInteger sectionNum = 1;
    if (self.stDataSource && [_stDataSource respondsToSelector:@selector(numberOfSectionsInStCollectionView:)]) {
        sectionNum = [_stDataSource numberOfSectionsInStCollectionView:collectionView];
    }
    return fmax(1, sectionNum);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger itemNum = 0;
    if (self.stDataSource && [_stDataSource respondsToSelector:@selector(stCollectionView:numberOfItemsInSection:)]) {
        itemNum = [_stDataSource stCollectionView:collectionView numberOfItemsInSection:section];
    }
    return itemNum;
}

- (UICollectionViewCell *)collectionView:(STCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell * cell = nil;
    if (_stDataSource && [_stDataSource respondsToSelector:@selector(stCollectionView:cellForItemAtIndexPath:)]) {
        cell = [_stDataSource stCollectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
    return cell;
}

#pragma mark - Setter
/**
 *  override to setter methods to associate `STCollectionViewFlowLayoutDelegate` & `STCollectionViewDataSource`
 */
- (void)setDelegate:(id<UICollectionViewDelegate>)delegate {
    [super setDelegate:delegate];
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource {
    [super setDataSource:self];
    self.stDataSource = (id<STCollectionViewDataSource>)dataSource;
}

- (void)setMinRequireContentSize:(CGSize)minRequireContentSize {
    _minRequireContentSize = minRequireContentSize;
    [self.st_collectionViewLayout invalidateLayout];
    
}


@end



@interface STCollectionViewFlowLayout ()

/** 
 *   在支持下拉刷新状态下,顶部留白 header 的 attributes & height
 */
@property (nonatomic, strong) UICollectionViewLayoutAttributes * headerAttributes;
@property (nonatomic, assign) CGFloat headerHeight;

/**
 *   存储每个区的 rect.
 */
@property (nonatomic, strong) NSMutableArray * sectionRects;

/**
 *   字典形式存储每个区的所有列的所有 item 的 rect.
 *   结构是:每个区的数据 section 为 key,存储所有列中所有 item 的 rect 的大数组作为 value, 大数组存放与列数相同个数的数组,每个小数组存放对应列的的所有 items 的 rect.
 */
@property (nonatomic, strong) NSMutableDictionary * columnRectsInSection;

/**
 *   所有 items 的 attributes.
 */
@property (nonatomic, strong) NSMutableDictionary * layoutItemAttributes;

/**
 *   存储所有 header 与 footer 的 attributes.
 */
@property (nonatomic, strong) NSDictionary * headerFooterItemAttributes;

@end


@implementation STCollectionViewFlowLayout
@synthesize minimumLineSpacing = _minimumLineSpacing;
@synthesize minimumInteritemSpacing = _minimumInteritemSpacing;
@synthesize itemSize = _itemSize;
@synthesize sectionInset = _sectionInset;

// 判断当前 layout 是不是自定义的子类
BOOL isSubClass(STCollectionViewFlowLayout * self) {
    if (![self isMemberOfClass:STCollectionViewFlowLayout.class]) {
        return YES;
    }
    return NO;
}

- (void)prepareLayout {
    
    NSUInteger numberOfSections = self.collectionView.numberOfSections;
    self.sectionRects         = [[NSMutableArray alloc] initWithCapacity:numberOfSections];
    self.columnRectsInSection = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    self.layoutItemAttributes = [[NSMutableDictionary alloc] initWithCapacity:numberOfSections];
    self.headerFooterItemAttributes = @{UICollectionElementKindSectionHeader:[NSMutableArray array],
                                        UICollectionElementKindSectionFooter:[NSMutableArray array]};
    
    // Creat top palceholder header attributes.
    [self calculateTopHeaderAttributes];
    // If self is subclass of STCollectionViewFlowLayout class,return after creat top header.
    if (isSubClass(self)) {
        return;
    }
    for (NSUInteger section = 0; section < numberOfSections; section ++) {
        NSUInteger itemsInSection = [self.collectionView numberOfItemsInSection:section];
        [self.layoutItemAttributes setObject:[NSMutableArray array] forKey:@(section)];
        [self prepareLayoutInSection:section numberOfItems:itemsInSection];
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:STCollectionElementKindSectionHeader]) {
        return self.headerAttributes;
    }
    return self.headerFooterItemAttributes[kind][indexPath.section];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.layoutItemAttributes[@(indexPath.section)][indexPath.item];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (isSubClass(self)) {
        if (CGRectContainsRect(rect, _headerAttributes.frame)) {
            return @[_headerAttributes];
        }
        return @[];
    }
    return [self searchVisibleLayoutAttributesInRect:rect];
}

- (CGSize)collectionViewContentSize {
    // update contentSize in super layout.
    [super collectionViewContentSize];
    
    if (isSubClass(self)) {
        CGSize contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), _headerHeight);
        return contentSize;
    }
    
    CGRect lastSectionRect = [[self.sectionRects lastObject] CGRectValue];
    CGSize contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), CGRectGetMaxY(lastSectionRect));
    // fit mincontentSize
    STCollectionView * collectionView = (STCollectionView *)self.collectionView;
    contentSize.width  = fmax(contentSize.width, collectionView.minRequireContentSize.width);
    contentSize.height = fmax(contentSize.height, collectionView.minRequireContentSize.height);
    
    return contentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    CGRect oldBounds = self.collectionView.bounds;
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds)) {
        return YES;
    }
    return NO;
}


#pragma mark - Privated
- (void)calculateTopHeaderAttributes {
    STCollectionView * collectionView = (STCollectionView *)self.collectionView;
    NSIndexPath * sectionIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    self.headerHeight = 0.0f;
    if(nil != collectionView.collectionHeadView) {
        
        // Initialize the header rectangles.
        CGRect headerFrame;
        headerFrame.origin.x = 0.0f;
        headerFrame.origin.y = 0.0f;
        
        CGSize headerSize = collectionView.collectionHeadView.bounds.size;
        headerFrame.size.height = headerSize.height;
        headerFrame.size.width  = headerSize.width;
        
        UICollectionViewLayoutAttributes * headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:STCollectionElementKindSectionHeader withIndexPath:sectionIndexPath];
        headerAttributes.frame = headerFrame;
        
        _headerHeight = headerFrame.size.height;
        self.headerAttributes = headerAttributes;
    }
}

- (void)prepareLayoutInSection:(NSUInteger)section numberOfItems:(NSUInteger)items {
    
    STCollectionView * collectionView = (STCollectionView *)self.collectionView;
    NSIndexPath * indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    
    /** Get the rectangles of last section. */
    CGRect previousSectionRect = [self rectForSectionAtIndex:indexPath.section - 1];
    CGRect sectionRect;
    sectionRect.origin.x = 0;
    sectionRect.origin.y = CGRectGetHeight(previousSectionRect) + CGRectGetMinY(previousSectionRect);
    sectionRect.size.width = collectionView.bounds.size.width;
    
    /** Section Header */
    id delegate = collectionView.stDelegate;
    
    CGFloat headerHeight = 0.0f;
    if([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
        
        // Initialize the header rectangles.
        CGRect headerFrame;
        headerFrame.origin.x = 0.0f;
        headerFrame.origin.y = sectionRect.origin.y;
        
        CGSize headerSize = [delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:indexPath.section];
        headerFrame.size.height = headerSize.height;
        headerFrame.size.width = headerSize.width;
        
        UICollectionViewLayoutAttributes *headerAttributes =
        [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
        headerAttributes.frame = headerFrame;
        
        headerHeight = headerFrame.size.height;
        [self.headerFooterItemAttributes[UICollectionElementKindSectionHeader] addObject:headerAttributes];
    }
    
    /** Items In Section. */
    UIEdgeInsets sectionInsets = self.sectionInset;
    if([delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        sectionInsets = [delegate collectionView:collectionView layout:self insetForSectionAtIndex:section];
    }
    
    // Set the lineSpacing & interitemSpacing between the items, default values is 0.0f.
    CGFloat lineSpacing = self.minimumLineSpacing;
    CGFloat interitemSpacing = self.minimumInteritemSpacing;
    
    if ([delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
        interitemSpacing = [delegate collectionView:collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
    }
    if ([delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
        lineSpacing = [delegate collectionView:collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
    }
    
    // All the items' rectangles in the section
    CGRect itemsContentRect;
    itemsContentRect.origin.x = sectionInsets.left;
    itemsContentRect.origin.y = headerHeight + sectionInsets.top;
    
    NSAssert(nil != delegate && [delegate respondsToSelector:@selector(collectionView:layout:numberOfColumnsInSection:)], @"The stDelegate of STCollectionView must implementation method `collectionView:layout:numberOfColumnsInSection:`");
    NSUInteger numberOfColumns = [delegate collectionView:collectionView layout:self numberOfColumnsInSection:section];
    itemsContentRect.size.width = CGRectGetWidth(collectionView.bounds) - (sectionInsets.left + sectionInsets.right);
    
    CGFloat columnSpace = itemsContentRect.size.width - (interitemSpacing * (numberOfColumns - 1));
    CGFloat columnWidth = (columnSpace/numberOfColumns);
    
    // Initialize an empty mutable array earch column.
    NSMutableArray * columnRects = [NSMutableArray arrayWithCapacity:numberOfColumns];
    for (NSUInteger coluIndex = 0; coluIndex < numberOfColumns; coluIndex ++) {
        [columnRects addObject:[NSMutableArray array]];
    }
    [self.columnRectsInSection setObject:columnRects forKey:@(section)];
    
    // Calculate every item's rectangles.
    for (NSInteger itemIndex = 0; itemIndex < items; itemIndex ++) {
        // Get the possion of the shortest column in the section, it's preferred
        NSIndexPath * itemIndexPath  = [NSIndexPath indexPathForItem:itemIndex inSection:section];
        NSInteger destColumnIdx      = [self shortestColumnIndexInSection:section];
        NSInteger destRowInColumn    = [self numberOfItemsForColumn:destColumnIdx inSection:section];
        CGFloat lastItemInColumnMaxY = [self lastItemMaxYForColumn:destColumnIdx inSection:section];
        
        // First item in column
        if (destRowInColumn == 0) {
            lastItemInColumnMaxY += sectionRect.origin.y;
        }
        
        // Default item's rectangles is a square.
        CGRect itemRect;
        itemRect.origin.x = itemsContentRect.origin.x + destColumnIdx * (interitemSpacing + columnWidth);
        itemRect.origin.y = lastItemInColumnMaxY + (destRowInColumn > 0 ? lineSpacing: sectionInsets.top);
        itemRect.size.width = columnWidth;
        itemRect.size.height = columnWidth;
        
        if (self.itemSize.height > 0) {
            itemRect.size.height = _itemSize.height;
        }
        // Check the flow layout if implementation the `collectionView:layout:sizeForItemAtIndexPath:` protocol methods. If implementation set the itemRect size's height is the protocol return size's height.
        if ([delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
            CGSize itemSize = [delegate collectionView:collectionView layout:self sizeForItemAtIndexPath:itemIndexPath];
            itemRect.size.height = itemSize.height;
        }
        UICollectionViewLayoutAttributes * itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:itemIndexPath];
        itemAttributes.frame = itemRect;
        [self.layoutItemAttributes[@(section)] addObject:itemAttributes];
        [self.columnRectsInSection[@(section)][destColumnIdx] addObject:[NSValue valueWithCGRect:itemRect]];
    }
    
    itemsContentRect.size.height = [self heightOfItemsContentInSection:section];
    
    /* Section Footer */
    CGFloat footerHeight = 0.0f;
    if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]) {
        CGRect footerFrame;
        footerFrame.origin.x = 0;
        footerFrame.origin.y = sectionRect.origin.y + headerHeight + itemsContentRect.size.height + (sectionInsets.top + sectionInsets.bottom);
        
        CGSize footerSize = [delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:indexPath.section];
        footerFrame.size.height = footerSize.height;
        footerFrame.size.width = footerSize.width;
        
        UICollectionViewLayoutAttributes *footerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:indexPath];
        footerAttributes.frame = footerFrame;
        
        footerHeight = footerFrame.size.height;
        
        [self.headerFooterItemAttributes[UICollectionElementKindSectionFooter] addObject:footerAttributes];
    }
    
    sectionRect.size.height = itemsContentRect.size.height + (headerHeight + footerHeight) + (sectionInsets.top + sectionInsets.bottom);
    
    [self.sectionRects addObject:[NSValue valueWithCGRect:sectionRect]];
}

- (CGFloat)heightOfItemsContentInSection:(NSUInteger)sectionIdx {
    CGFloat maxHeight = 0.0f;
    NSArray * columnsInSection = self.columnRectsInSection[@(sectionIdx)];
    for (NSUInteger columnIdx = 0; columnIdx < columnsInSection.count; columnIdx ++) {
        if (columnsInSection.count > 0) {
            CGFloat heightOfColumn  = CGRectGetMaxY([[columnsInSection[columnIdx] lastObject] CGRectValue]);
            heightOfColumn -= CGRectGetMinY([[columnsInSection[columnIdx] firstObject] CGRectValue]);
            maxHeight = MAX(maxHeight, heightOfColumn);
        }
    }
    return maxHeight;
}

- (NSInteger)numberOfItemsForColumn:(NSInteger)columnIdx inSection:(NSInteger)sectionIdx {
    return [self.columnRectsInSection[@(sectionIdx)][columnIdx] count];
}

- (CGFloat)lastItemMaxYForColumn:(NSInteger)columnIdx inSection:(NSInteger)sectionIdx {
    NSArray * itemsInColumn = self.columnRectsInSection[@(sectionIdx)][columnIdx];
    if (itemsInColumn.count == 0) {
        if([self.headerFooterItemAttributes[UICollectionElementKindSectionHeader] count] > sectionIdx) {
            CGRect headerFrame = [self.headerFooterItemAttributes[UICollectionElementKindSectionHeader][sectionIdx] frame];
            return headerFrame.size.height;
        }
        return 0.0f;
    } else {
        CGRect lastItemRect = [[itemsInColumn lastObject] CGRectValue];
        return CGRectGetMaxY(lastItemRect);
    }
}

// Get the shortest column cell index in the section. It's preferred which cell is shortest column height.
- (NSInteger)shortestColumnIndexInSection:(NSInteger)sectionIdx {
    NSUInteger shortestColumnIdx   = 0;
    CGFloat heightOfShortestColumn = CGFLOAT_MAX;
    NSInteger columnCount = [self.columnRectsInSection[@(sectionIdx)] count];
    for (NSUInteger columnIdx = 0; columnIdx < columnCount; columnIdx ++) {
        CGFloat columnHeight = [self lastItemMaxYForColumn:columnIdx inSection:sectionIdx];
        if (columnHeight < heightOfShortestColumn) {
            shortestColumnIdx = columnIdx;
            heightOfShortestColumn = columnHeight;
        }
    }
    return shortestColumnIdx;
}

// Get the rectangles of the section.
- (CGRect)rectForSectionAtIndex:(NSInteger)sectionIdx {
    if (sectionIdx < 0) {
        // Leave the placeholder header height
        return (CGRect){0, _headerHeight, 0, 0};
    }else if (sectionIdx > self.sectionRects.count - 1) {
        return CGRectZero;
    }
    return [self.sectionRects[sectionIdx] CGRectValue];
}

#pragma mark - Show Attributes Methods
// Get the visible cells's layout attributes in collectionView's visible rectangles on the screen.
- (NSArray *)searchVisibleLayoutAttributesInRect:(CGRect)rect {
    NSMutableArray * itemAttrs = [[NSMutableArray alloc] init];
    // Check placeholder header
    if (_headerAttributes && CGRectContainsRect(rect, self.headerAttributes.frame)) {
        [itemAttrs addObject:self.headerAttributes];
    }
    // Other attributes
    NSIndexSet * visibleSections = [self sectionIndexesInRect:rect];
    [visibleSections enumerateIndexesUsingBlock:^(NSUInteger sectionIdx, BOOL *stop) {
        
        // Check item layout attributes's rectangles if intersectes the collectionView's rectangles.
        for (UICollectionViewLayoutAttributes * itemAttr in self.layoutItemAttributes[@(sectionIdx)]) {
            CGRect itemRect = itemAttr.frame;
            itemAttr.zIndex = 1;
            BOOL isVisible = CGRectIntersectsRect(rect, itemRect);
            if (isVisible) {
                [itemAttrs addObject:itemAttr];
            }
        }
        
        // Check footer layout attributes's rectangles if intersectes the collectionView's rectangles.
        if ([self.headerFooterItemAttributes[UICollectionElementKindSectionFooter] count] > sectionIdx) {
            UICollectionViewLayoutAttributes * footerAttribute = self.headerFooterItemAttributes[UICollectionElementKindSectionFooter][sectionIdx];
            BOOL isVisible = CGRectIntersectsRect(rect, footerAttribute.frame);
            if (isVisible && footerAttribute) {
                [itemAttrs addObject:footerAttribute];
            }
        }
        
        // Check header layout attributes's rectangles if intersectes the collectionView's rectangles.
        if([self.headerFooterItemAttributes[UICollectionElementKindSectionHeader] count] > sectionIdx) {
            UICollectionViewLayoutAttributes *headerAttribute = self.headerFooterItemAttributes[UICollectionElementKindSectionHeader][sectionIdx];
            
            BOOL isVisibleHeader = CGRectIntersectsRect(rect, headerAttribute.frame);
            
            if (isVisibleHeader && headerAttribute) {
                [itemAttrs addObject:headerAttribute];
            }
        }
    }];
    return itemAttrs;
}

// Get the indexes of section in collectionView's visible rectangles on the screen.
- (NSIndexSet *)sectionIndexesInRect:(CGRect)rect {
    CGRect theRect = rect;
    NSMutableIndexSet * visibleIndexes = [[NSMutableIndexSet alloc] init];
    NSUInteger numberOfSections = self.collectionView.numberOfSections;
    for (NSUInteger sectionIdx = 0; sectionIdx < numberOfSections; sectionIdx ++) {
        CGRect sectionRect = [self.sectionRects[sectionIdx] CGRectValue];
        BOOL isVisible = CGRectIntersectsRect(theRect, sectionRect);
        if (isVisible)
            [visibleIndexes addIndex:sectionIdx];
    }
    return visibleIndexes;
}


@end



