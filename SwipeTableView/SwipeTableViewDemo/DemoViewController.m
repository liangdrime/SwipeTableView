//
//  DemoViewController.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "DemoViewController.h"
#import "SwipeTableView.h"
#import "CustomTableView.h"
#import "CustomCollectionView.h"
#import "UIView+Frame.h"

NSString const * kShouldReuseableViewIdentifier = @"setIsJustOneKindOfClassView";
NSString const * kAdjustContentOffsetDefaultIdentifier = @"doNothing";
NSString const * kAdjustContentSizeToFitMaxItemIdentifier = @"setFitItemsContentSize";
NSString const * kHiddenNavigationBarIdentifier = @"shouldHidenNavigationBar";

@interface DemoViewController ()<SwipeTableViewDataSource,SwipeTableViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) SwipeTableView * swipeTableView;
@property (nonatomic, assign) BOOL isJustOneKindOfClassView;
@property (nonatomic, assign) BOOL shouldHiddenNavigationBar;
@property (nonatomic, assign) BOOL shouldFitItemsContentSize;
@property (nonatomic, strong) UIView * tableViewHeader;
@property (nonatomic, strong) UISegmentedControl * segmentBar;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.swipeTableView = [[SwipeTableView alloc]initWithFrame:self.view.bounds];
    _swipeTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _swipeTableView.delegate = self;
    _swipeTableView.dataSource = self;
    _swipeTableView.shouldAdjustContentSize = _shouldFitItemsContentSize;
    _swipeTableView.swipeHeaderView = self.tableViewHeader;
    _swipeTableView.swipeHeaderBar = self.segmentBar;
    if (_shouldHiddenNavigationBar) {
        _swipeTableView.swipeHeaderTopInset = 0;
    }
    [self.view addSubview:_swipeTableView];
    
    // nav bar
    UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"Remove Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
    UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"Remove Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
    self.navigationItem.leftBarButtonItem = leftBarItem;
    self.navigationItem.rightBarButtonItem = rightBarItem;
    
    // back
    UIButton * back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(10, 70, 40, 40);
    back.backgroundColor = [UIColor orangeColor];
    back.layer.cornerRadius = back.height/2;
    back.layer.masksToBounds = YES;
    back.titleLabel.font = [UIFont systemFontOfSize:14];
    [back setTitle:@"Back" forState:UIControlStateNormal];
    [back setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
}

#pragma mark - 

- (void)setActionIdentifier:(NSString *)actionIdentifier {
    _actionIdentifier = actionIdentifier;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(_actionIdentifier) withObject:nil];
#pragma clang diagnostic pop
}

- (void)setIsJustOneKindOfClassView {
    _isJustOneKindOfClassView = YES;
}

- (void)setFitItemsContentSize {
    _shouldFitItemsContentSize = YES;
    _swipeTableView.shouldAdjustContentSize = _shouldFitItemsContentSize;
}

- (void)shouldHidenNavigationBar {
    _shouldHiddenNavigationBar = YES;
}

- (void)doNothing{};

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Header & Bar

- (UIView *)tableViewHeader {
    if (nil == _tableViewHeader) {
        self.tableViewHeader = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth * 3/5)];
        _tableViewHeader.backgroundColor = [UIColor purpleColor];
    }
    return _tableViewHeader;
}

- (UISegmentedControl * )segmentBar {
    if (nil == _segmentBar) {
        self.segmentBar = [[UISegmentedControl alloc]initWithItems:@[@"Item1",@"Item2",@"Item3",@"Item4"]];
        _segmentBar.size = CGSizeMake(kScreenWidth, 42);
        _segmentBar.backgroundColor = [UIColor whiteColor];
        _segmentBar.tintColor = [UIColor greenColor];
        _segmentBar.selectedSegmentIndex = _swipeTableView.currentItemIndex;
        [_segmentBar addTarget:self action:@selector(changeSwipeViewIndex:) forControlEvents:UIControlEventValueChanged];
    }
    return _segmentBar;
}

- (void)setSwipeTableHeader:(UIBarButtonItem *)barItem {
    if (!_swipeTableView.swipeHeaderView) {
        _swipeTableView.swipeHeaderView = self.tableViewHeader;
        [_swipeTableView reloadData];
        
        UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"Remove Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
        self.navigationItem.rightBarButtonItem = rightBarItem;
    }else {
        _swipeTableView.swipeHeaderView = nil;
        
        UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"Add Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
        self.navigationItem.rightBarButtonItem = rightBarItem;
    }
}

- (void)setSwipeTableBar:(UIBarButtonItem *)barItem {
    if (!_swipeTableView.swipeHeaderBar) {
        _swipeTableView.swipeHeaderBar = self.segmentBar;
        [_swipeTableView reloadData];
        
        UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"Remove Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
        self.navigationItem.leftBarButtonItem = leftBarItem;
    }else {
        _swipeTableView.swipeHeaderBar = nil;
        
        UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"Add Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
        self.navigationItem.leftBarButtonItem = leftBarItem;
    }
}

- (void)changeSwipeViewIndex:(UISegmentedControl *)seg {
    [_swipeTableView scrollToItemAtIndex:seg.selectedSegmentIndex animated:NO];
}

#pragma mark - SwipeTableView M

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    return 4;
}

- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view {
    NSInteger numberOfRows = 10;
    if (nil == view) {
        if (_isJustOneKindOfClassView || _shouldFitItemsContentSize || _shouldHiddenNavigationBar) {
            CustomTableView * talbeView = [[CustomTableView alloc]initWithFrame:swipeView.bounds style:UITableViewStylePlain];
            talbeView.backgroundColor = [UIColor whiteColor];
            view = talbeView;
        }else {
            if (index == 0 || index == 2) {
                CustomTableView * talbeView = [[CustomTableView alloc]initWithFrame:swipeView.bounds style:UITableViewStylePlain];
                talbeView.backgroundColor = [UIColor whiteColor];
                talbeView.numberOfRows = numberOfRows;
                view = talbeView;
            }else {
                CustomCollectionView * collectionView = [[CustomCollectionView alloc]initWithFrame:swipeView.bounds];
                collectionView.backgroundColor = [UIColor whiteColor];
                collectionView.numberOfItems = 2 *numberOfRows;
                view = collectionView;
            }
        }
    }
    if (_isJustOneKindOfClassView || _shouldFitItemsContentSize || _shouldHiddenNavigationBar) {
        if (index == 1 || index == 3) {
            numberOfRows = 5;
        }
        [view setValue:@(numberOfRows) forKey:@"numberOfRows"];
        [view setValue:@(index) forKey:@"itemIndex"];
    }
    [view performSelector:@selector(reloadData)];
    return view;
}

- (void)swipeTableViewCurrentItemIndexDidChange:(SwipeTableView *)swipeView {
    _segmentBar.selectedSegmentIndex = swipeView.currentItemIndex;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:_shouldHiddenNavigationBar animated:animated];
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
