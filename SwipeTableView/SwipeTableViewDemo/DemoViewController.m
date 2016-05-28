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
#import "CustomSegmentControl.h"
#import "UIView+Frame.h"

NSString const * kShouldReuseableViewIdentifier = @"setIsJustOneKindOfClassView";
NSString const * kHybridItemViewsIdentifier = @"doNothing";
NSString const * kAdjustContentSizeToFitMaxItemIdentifier = @"setFitItemsContentSize";
NSString const * kHiddenNavigationBarIdentifier = @"shouldHidenNavigationBar";

@interface DemoViewController ()<SwipeTableViewDataSource,SwipeTableViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) SwipeTableView * swipeTableView;
@property (nonatomic, assign) BOOL isJustOneKindOfClassView;
@property (nonatomic, assign) BOOL shouldHiddenNavigationBar;
@property (nonatomic, assign) BOOL shouldFitItemsContentSize;
@property (nonatomic, strong) UIImageView * tableViewHeader;
@property (nonatomic, strong) CustomSegmentControl * segmentBar;

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
    UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
    UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
    self.navigationItem.leftBarButtonItem = leftBarItem;
    self.navigationItem.rightBarButtonItem = rightBarItem;
    
    // back
    UIButton * back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(10, 0, 40, 40);
    back.top = _shouldHiddenNavigationBar?25:74;
    back.backgroundColor = RGBColorAlpha(10, 230, 0, 0.95);
    back.layer.cornerRadius = back.height/2;
    back.layer.masksToBounds = YES;
    back.titleLabel.font = [UIFont systemFontOfSize:14];
    [back setTitle:@"Back" forState:UIControlStateNormal];
    [back setTitleColor:RGBColor(236, 255, 236) forState:UIControlStateNormal];
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
    
    // edge gesture
    [_swipeTableView.contentView.panGestureRecognizer requireGestureRecognizerToFail:self.screenEdgePanGestureRecognizer];
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
        UIImage * headerImage = [UIImage imageNamed:@"onepiece_kiudai"];
        self.tableViewHeader = [[UIImageView alloc]initWithImage:headerImage];
        _tableViewHeader.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth * (headerImage.size.height/headerImage.size.width));
        _tableViewHeader.backgroundColor = [UIColor purpleColor];
    }
    return _tableViewHeader;
}

- (CustomSegmentControl * )segmentBar {
    if (nil == _segmentBar) {
        self.segmentBar = [[CustomSegmentControl alloc]initWithItems:@[@"Item0",@"Item1",@"Item2",@"Item3"]];
        _segmentBar.size = CGSizeMake(kScreenWidth, 40);
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

- (void)changeSwipeViewIndex:(UISegmentedControl *)seg {
    [_swipeTableView scrollToItemAtIndex:seg.selectedSegmentIndex animated:NO];
}

#pragma mark - SwipeTableView M

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    return 4;
}

- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view {
    NSInteger numberOfRows = 10;
    if (_isJustOneKindOfClassView || _shouldFitItemsContentSize || _shouldHiddenNavigationBar) {
        // 重用
        if (nil == view) {
            CustomTableView * tableView = [[CustomTableView alloc]initWithFrame:swipeView.bounds style:UITableViewStylePlain];
            tableView.backgroundColor = RGBColor(255, 255, 225);
            view = tableView;
        }
        if (index == 1 || index == 3) {
            numberOfRows = 5;
        }
        [view setValue:@(numberOfRows) forKey:@"numberOfRows"];
        [view setValue:@(index) forKey:@"itemIndex"];
        
    }else {
        // 混合的itemview只有同类型的item采用重用
        if (index == 0 || index == 2) {
            CustomTableView * tableView = [swipeView viewWithTag:1000];
            if (nil == tableView) {
                tableView = [[CustomTableView alloc]initWithFrame:swipeView.bounds style:UITableViewStylePlain];
                tableView.backgroundColor = RGBColor(255, 255, 225);
                tableView.tag = 1000;
                tableView.numberOfRows = numberOfRows;
            }
            view = tableView;
        }else {
            CustomCollectionView * collectionView = [swipeView viewWithTag:1001];
            if (nil == collectionView) {
                collectionView = [[CustomCollectionView alloc]initWithFrame:swipeView.bounds];
                collectionView.backgroundColor = RGBColor(255, 255, 225);
                collectionView.tag = 1001;
                collectionView.numberOfItems = 2 *numberOfRows;
            }
            view = collectionView;
        }
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
