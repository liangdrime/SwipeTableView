//
//  STViewController.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "STViewController.h"
#import "SwipeTableView.h"
#import "CustomTableView.h"
#import "CustomCollectionView.h"
#import "CustomSegmentControl.h"
#import "UIView+STFrame.h"
#import "STImageController.h"
#import "STTransitions.h"
#import "STRefresh.h"
#import <objc/message.h>


@interface STViewController ()<SwipeTableViewDataSource,SwipeTableViewDelegate,UIGestureRecognizerDelegate,UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) SwipeTableView * swipeTableView;
@property (nonatomic, strong) STHeaderView * tableViewHeader;
@property (nonatomic, strong) CustomSegmentControl * segmentBar;
@property (nonatomic, strong) CustomTableView * tableView;
@property (nonatomic, strong) CustomCollectionView * collectionView;
@property (nonatomic, strong) NSMutableDictionary * dataDic;

@end

@implementation STViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL disableBarScroll = _type == STControllerTypeDisableBarScroll;
    BOOL hiddenNavigationBar = _type == STControllerTypeHiddenNavBar;
    
    // init swipetableview
    self.swipeTableView = [[SwipeTableView alloc]initWithFrame:self.view.bounds];
    _swipeTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _swipeTableView.delegate = self;
    _swipeTableView.dataSource = self;
    _swipeTableView.shouldAdjustContentSize = YES;
    _swipeTableView.swipeHeaderView = disableBarScroll?nil:self.tableViewHeader;
    _swipeTableView.swipeHeaderBar = self.segmentBar;
    _swipeTableView.swipeHeaderBarScrollDisabled = disableBarScroll;
    if (hiddenNavigationBar) {
        _swipeTableView.swipeHeaderTopInset = 0;
    }
    [self.view addSubview:_swipeTableView];
    
    // nav bar
    UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
    UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
    self.navigationItem.leftBarButtonItem = disableBarScroll?nil:leftBarItem;
    self.navigationItem.rightBarButtonItem = disableBarScroll?nil:rightBarItem;
    
    // back bt
    UIButton * back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(10, 0, 40, 40);
    back.st_top = hiddenNavigationBar?25:74;
    back.backgroundColor = RGBColorAlpha(10, 202, 0, 0.95);
    back.layer.cornerRadius = back.st_height/2;
    back.layer.masksToBounds = YES;
    back.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    back.hidden = disableBarScroll;
    [back setTitle:@"Back" forState:UIControlStateNormal];
    [back setTitleColor:RGBColor(255, 255, 215) forState:UIControlStateNormal];
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
    
    [self.navigationController.navigationBar setTintColor:RGBColor(234, 39, 0)];
    
    // edge gesture
    [_swipeTableView.contentView.panGestureRecognizer requireGestureRecognizerToFail:self.screenEdgePanGestureRecognizer];
    
    // init data
    _dataDic = [@{} mutableCopy];
    
    // 根据滚动后的下标请求数据
    //    [self getDataAtIndex:0];
    
    // 一次性请求所有item的数据
    [self getAllData];
}

- (UIScreenEdgePanGestureRecognizer *)screenEdgePanGestureRecognizer {
    UIScreenEdgePanGestureRecognizer *screenEdgePanGestureRecognizer = nil;
    if (self.navigationController.view.gestureRecognizers.count > 0) {
        for (UIGestureRecognizer *recognizer in self.navigationController.view.gestureRecognizers) {
            if ([recognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
                screenEdgePanGestureRecognizer = (UIScreenEdgePanGestureRecognizer *)recognizer;
                break;
            }
        }
    }
    return screenEdgePanGestureRecognizer;
}

#pragma mark - Header & Bar

- (UIView *)tableViewHeader {
    if (nil == _tableViewHeader) {
        UIImage * headerImage = [UIImage imageNamed:@"onepiece_kiudai"];
        // swipe header
        self.tableViewHeader = [[STHeaderView alloc]init];
        _tableViewHeader.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth * (headerImage.size.height/headerImage.size.width));
        _tableViewHeader.backgroundColor = [UIColor whiteColor];
        _tableViewHeader.layer.masksToBounds = YES;
        
        // image view
        self.headerImageView = [[UIImageView alloc]initWithImage:headerImage];
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headerImageView.userInteractionEnabled = YES;
        _headerImageView.frame = _tableViewHeader.bounds;
        _headerImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        // title label
        UILabel * title = [[UILabel alloc]init];
        title.textColor = RGBColor(255, 255, 255);
        title.font = [UIFont boldSystemFontOfSize:17];
        title.text = @"Tap To Full Screen";
        title.textAlignment = NSTextAlignmentCenter;
        title.st_size = CGSizeMake(200, 30);
        title.st_centerX = _headerImageView.st_centerX;
        title.st_bottom = _headerImageView.st_bottom - 20;
        
        // tap gesture
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapHeader:)];
        
        [_tableViewHeader addSubview:_headerImageView];
        [_tableViewHeader addSubview:title];
        [_headerImageView addGestureRecognizer:tap];
        [self shimmerHeaderTitle:title];
    }
    return _tableViewHeader;
}

- (CustomSegmentControl * )segmentBar {
    if (nil == _segmentBar) {
        self.segmentBar = [[CustomSegmentControl alloc]initWithItems:@[@"Item0",@"Item1",@"Item2",@"Item3"]];
        _segmentBar.st_size = CGSizeMake(kScreenWidth, 40);
        _segmentBar.font = [UIFont systemFontOfSize:15];
        _segmentBar.textColor = RGBColor(100, 100, 100);
        _segmentBar.selectedTextColor = RGBColor(0, 0, 0);
        _segmentBar.backgroundColor = RGBColor(249, 251, 198);
        _segmentBar.selectionIndicatorColor = RGBColor(249, 104, 92);
        _segmentBar.selectedSegmentIndex = _swipeTableView.currentItemIndex;
        [_segmentBar addTarget:self action:@selector(changeSwipeViewIndex:) forControlEvents:UIControlEventValueChanged];
    }
    return _segmentBar;
}

#pragma mark -

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tapHeader:(UITapGestureRecognizer *)tap {
    STImageController * imageVC = [[STImageController alloc]init];
    imageVC.transitioningDelegate = self;
    [self presentViewController:imageVC animated:YES completion:nil];
}

// tap to change header's frame
- (void)_tapHeader:(UITapGestureRecognizer *)tap {
    
    CGFloat changeHeight = 50; // or -50, it will be parallax.
    UIScrollView * currentItem = _swipeTableView.currentItemView;
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    CGPoint contentOffset = currentItem.contentOffset;
    UIEdgeInsets inset = currentItem.contentInset;
    inset.top += changeHeight;
    contentOffset.y -= changeHeight;  // if you want the header change height from up, not do this.
    
    NSMutableDictionary * contentOffsetQuene = [self.swipeTableView valueForKey:@"contentOffsetQuene"];
    [contentOffsetQuene removeAllObjects];
    
    [UIView animateWithDuration:.35f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _tableViewHeader.st_height += changeHeight;
        currentItem.contentInset = inset;
        currentItem.contentOffset = contentOffset;
    } completion:^(BOOL finished) {
        [self.swipeTableView setValue:@(self.tableViewHeader.st_height) forKey:@"headerInset"];
    }];
#else
    UIView * tableHeaderView = ((UITableView *)currentItem).tableHeaderView;
    tableHeaderView.st_height += changeHeight;
    
    [UIView animateWithDuration:.35f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _tableViewHeader.st_height += changeHeight;
        [currentItem setValue:tableHeaderView forKey:@"tableHeaderView"];
    } completion:^(BOOL finished) {
        [self.swipeTableView setValue:@(self.tableViewHeader.st_height) forKey:@"headerInset"];
    }];
#endif
    
}

- (void)shimmerHeaderTitle:(UILabel *)title {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.75f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        title.transform = CGAffineTransformMakeScale(0.98, 0.98);
        title.alpha = 0.3;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.75f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            title.alpha = 1.0;
            title.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [weakSelf shimmerHeaderTitle:title];
        }];
    }];
}

- (void)setSwipeTableHeader:(UIBarButtonItem *)barItem {
    if (!_swipeTableView.swipeHeaderView) {
        _swipeTableView.swipeHeaderView = self.tableViewHeader;
        [_swipeTableView reloadData];
        
        UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
        self.navigationItem.rightBarButtonItem = rightBarItem;
    }else {
        _swipeTableView.swipeHeaderView = nil;
        
        UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"+ Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
        self.navigationItem.rightBarButtonItem = rightBarItem;
    }
}

- (void)setSwipeTableBar:(UIBarButtonItem *)barItem {
    if (!_swipeTableView.swipeHeaderBar) {
        _swipeTableView.swipeHeaderBar = self.segmentBar;
        _swipeTableView.scrollEnabled  = YES;
        
        UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
        self.navigationItem.leftBarButtonItem = leftBarItem;
    }else {
        _swipeTableView.swipeHeaderBar = nil;
        _swipeTableView.scrollEnabled  = NO;
        
        UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"+ Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
        self.navigationItem.leftBarButtonItem = leftBarItem;
    }
}

- (CustomTableView *)tableView {
    if (nil == _tableView) {
        _tableView = [[CustomTableView alloc]initWithFrame:_swipeTableView.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = RGBColor(255, 255, 225);
    }
    return _tableView;
}

- (CustomCollectionView *)collectionView {
    if (nil == _collectionView) {
        _collectionView = [[CustomCollectionView alloc]initWithFrame:_swipeTableView.bounds];
        _collectionView.backgroundColor = RGBColor(255, 255, 225);
    }
    return _collectionView;
}

- (void)changeSwipeViewIndex:(UISegmentedControl *)seg {
    [_swipeTableView scrollToItemAtIndex:seg.selectedSegmentIndex animated:NO];
    // request data at current index
    [self getDataAtIndex:seg.selectedSegmentIndex];
}

#pragma mark - Data Reuqest

// 请求数据（根据视图滚动到相应的index后再请求数据）
- (void)getDataAtIndex:(NSInteger)index {
    if (nil != _dataDic[@(index)]) {
        return;
    }
    NSInteger numberOfRows = 0;
    switch (index) {
        case 0:
            numberOfRows = _type == STControllerTypeNormal?8:10;
            break;
        case 1:
            numberOfRows = _type == STControllerTypeNormal?10:8;
            break;
        case 2:
            numberOfRows = _type == STControllerTypeNormal?5:6;
            break;
        case 3:
            numberOfRows = _type == STControllerTypeNormal?12:12;
            break;
        default:
            break;
    }
    // 请求数据后刷新相应的item
    ((void (*)(void *, SEL, NSNumber *, NSInteger))objc_msgSend)((__bridge void *)(self.swipeTableView.currentItemView),@selector(refreshWithData:atIndex:), @(numberOfRows),index);
    // 保存数据
    [_dataDic setObject:@(numberOfRows) forKey:@(index)];
}

// 请求数据（一次性获取所有item的数据）
- (void)getAllData {
    if (_type == STControllerTypeNormal) {
        [_dataDic setObject:@(8) forKey:@(0)];
        [_dataDic setObject:@(10) forKey:@(1)];
        [_dataDic setObject:@(5) forKey:@(2)];
        [_dataDic setObject:@(12) forKey:@(3)];
    }else {
        [_dataDic setObject:@(10) forKey:@(0)];
        [_dataDic setObject:@(12) forKey:@(1)];
        [_dataDic setObject:@(8) forKey:@(2)];
        [_dataDic setObject:@(14) forKey:@(3)];
    }
}


#pragma mark - SwipeTableView M

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    return 4;
}

- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view {
    switch (_type) {
        case STControllerTypeNormal:
        {
            
            CustomTableView * tableView = (CustomTableView *)view;
            // 重用
            if (nil == tableView) {
                tableView = [[CustomTableView alloc]initWithFrame:swipeView.bounds style:UITableViewStylePlain];
                tableView.backgroundColor = RGBColor(255, 255, 225);
            }
            
            // 获取当前index下item的数据，进行数据刷新
            id data = _dataDic[@(index)];
            [tableView refreshWithData:data atIndex:index];
            
            view = tableView;
        }
            break;
        case STControllerTypeHybrid:
        case STControllerTypeDisableBarScroll:
        case STControllerTypeHiddenNavBar:
        {
            
            // 混合的itemview只有同类型的item采用重用
            if (index == 0 || index == 2) {
                
                // 懒加载保证同样类型的item只创建一次，以达到重用
                CustomTableView * tableView = self.tableView;
                
                // 获取当前index下item的数据，进行数据刷新
                id data = _dataDic[@(index)];
                [tableView refreshWithData:data atIndex:index];
                
                view = tableView;
            }else {
                
                CustomCollectionView * collectionView = self.collectionView;
                
                // 获取当前index下item的数据，进行数据刷新
                id data = _dataDic[@(index)];
                [collectionView refreshWithData:data atIndex:index];
                
                view = self.collectionView;
            }
            
        }
            break;
        default:
            break;
    }
    
    // 在没有设定下拉刷新宏的条件下，自定义的下拉刷新需要做 refreshheader 的 frame 处理
    [self configRefreshHeaderForItem:view];
    
    return view;
}

// swipetableView index变化，改变seg的index
- (void)swipeTableViewCurrentItemIndexDidChange:(SwipeTableView *)swipeView {
    _segmentBar.selectedSegmentIndex = swipeView.currentItemIndex;
}

// 滚动结束请求数据
- (void)swipeTableViewDidEndDecelerating:(SwipeTableView *)swipeView {
    [self getDataAtIndex:swipeView.currentItemIndex];
}

/**
 *  以下两个代理，在未定义宏 #define ST_PULLTOREFRESH_HEADER_HEIGHT，并自定义下拉刷新的时候，必须实现
 *  如果设置了下拉刷新的宏，以下代理可根据需要实现即可
 */
- (BOOL)swipeTableView:(SwipeTableView *)swipeTableView shouldPullToRefreshAtIndex:(NSInteger)index {
    return YES;
}

- (CGFloat)swipeTableView:(SwipeTableView *)swipeTableView heightForRefreshHeaderAtIndex:(NSInteger)index {
    return kSTRefreshHeaderHeight;
}

/**
 *  采用自定义修改下拉刷新，此时不会定义宏 #define ST_PULLTOREFRESH_HEADER_HEIGHT
 *  对于一些下拉刷新控件，可能会在`layouSubViews`中设置RefreshHeader的frame。所以，需要在itemView有效的方法中改变RefreshHeader的frame，如 `scrollViewDidScroll:`
 */
- (void)configRefreshHeaderForItem:(UIScrollView *)itemView {
    if (_type == STControllerTypeDisableBarScroll) {
        itemView.header = nil;
        return;
    }
#if !defined(ST_PULLTOREFRESH_HEADER_HEIGHT)
    STRefreshHeader * header = itemView.header;
    header.st_y = - (header.st_height + (_segmentBar.st_height + _headerImageView.st_height));
#endif
}



#pragma  mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    return [[STTransitions alloc]initWithTransitionDuration:0.55f fromView:self.headerImageView isPresenting:YES];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [[STTransitions alloc]initWithTransitionDuration:0.5f fromView:self.headerImageView isPresenting:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:_type == STControllerTypeHiddenNavBar animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;
    self.navigationController.interactivePopGestureRecognizer.delegate = weakSelf;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
