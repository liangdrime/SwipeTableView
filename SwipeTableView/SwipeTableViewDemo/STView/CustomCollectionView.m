//
//  CustomCollectionView.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "CustomCollectionView.h"
#import "UIView+STFrame.h"
#import "STRefresh.h"

#define RGBColor(r,g,b)     [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

@interface CustomCollectionView ()<STCollectionViewDataSource,STCollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray * itemSizes;
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, assign) BOOL isWaterFlow;

@end
@implementation CustomCollectionView

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)_layout {
    self = [super initWithFrame:frame collectionViewLayout:_layout];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    STCollectionViewFlowLayout * layout = self.st_collectionViewLayout;
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 5;
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    self.stDelegate = self;
    self.stDataSource = self;
    [self registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"item"];
    [self registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [self registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    
    self.header = [STRefreshHeader headerWithRefreshingBlock:^(STRefreshHeader *header) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [header endRefreshing];
        });
    }];
}

- (NSMutableArray *)itemSizes {
    if (nil == _itemSizes) {
        _itemSizes = [NSMutableArray array];
        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 100)]];
        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 80)]];
        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 70)]];
        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 90)]];
        
//        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 100)]];
//        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 100)]];
//        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 100)]];
//        [_itemSizes addObject:[NSValue valueWithCGSize:CGSizeMake(100, 100)]];

    }
    return _itemSizes;
}

- (void)refreshWithData:(id)numberOfItems atIndex:(NSInteger)index {
    _numberOfItems = [numberOfItems integerValue];
    _isWaterFlow = index == 1;
    
    NSLog(@"data === %ld   index === %ld   isWaterFlow === %d",[numberOfItems integerValue],index,_isWaterFlow);
    
    [self reloadData];
}


#pragma mark - STCollectionView M

- (NSInteger)collectionView:(UICollectionView *)collectionView layout:(STCollectionViewFlowLayout *)layout numberOfColumnsInSection:(NSInteger)section {
    return 4;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isWaterFlow) {
        return [[self.itemSizes objectAtIndex:indexPath.row % 4] CGSizeValue];
    }
    return CGSizeMake(0, 100);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (_numberOfItems <= 0) {
        return CGSizeZero;
    }
    return CGSizeMake(kScreenWidth, 35);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (_numberOfItems <= 0) {
        return CGSizeZero;
    }
    return CGSizeMake(kScreenWidth, 35);
}

- (UICollectionReusableView *)stCollectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView * reusableView = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        UILabel * title = [reusableView viewWithTag:777];
        if (nil == title) {
            title = [UILabel new];
            title.tag = 777;
            title.backgroundColor = RGBColor(113, 198, 113);
            title.textColor = [UIColor whiteColor];
            title.font = [UIFont systemFontOfSize:16];
            title.textAlignment = NSTextAlignmentCenter;
            [reusableView addSubview:title];
        }
        title.frame = reusableView.bounds;
        title.text = [NSString stringWithFormat:@"Header %ld",indexPath.section];
    }else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
        UILabel * footer = [reusableView viewWithTag:999];
        if (nil == footer) {
            footer = [UILabel new];
            footer.tag = 999;
            footer.backgroundColor = RGBColor(197, 193, 170);
            footer.textColor = [UIColor whiteColor];
            footer.font = [UIFont systemFontOfSize:16];
            footer.textAlignment = NSTextAlignmentCenter;
            [reusableView addSubview:footer];
        }
        footer.frame = reusableView.bounds;
        footer.text = [NSString stringWithFormat:@"Footer %ld",indexPath.section];
    }
    return reusableView;
}

- (NSInteger)numberOfSectionsInStCollectionView:(UICollectionView *)collectionView {
    if (_numberOfItems <= 0) {
        return 0;
    }
    return 2;
} 

- (NSInteger)stCollectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _numberOfItems;
}

- (UICollectionViewCell *)stCollectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"item" forIndexPath:indexPath];
    cell.backgroundColor = RGBColor(150, 215, 200);
    // title
    UILabel * title = [cell viewWithTag:888];
    if (nil == title) {
        title = [UILabel new];
        title.tag = 888;
        title.st_size = CGSizeMake(80, 40);
        title.textColor = [UIColor whiteColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont systemFontOfSize:16];
        [cell addSubview:title];
    }
    title.center = CGPointMake(cell.st_width/2, cell.st_height/2);
    title.text = [NSString stringWithFormat:@"Item %ld",indexPath.item];
    return cell;
}

@end
