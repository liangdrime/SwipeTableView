//
//  SwipeTableViewController.m
//  SwipeTableView
//
//  Created by Roylee on 2017/3/27.
//  Copyright © 2017年 Roy lee. All rights reserved.
//

#import "SwipeTableViewController.h"
#import "STPrivateAssistant.h"
#import <objc/runtime.h>

static NSString *ViewControllerCacheKeyForView(UIView *view) {
    return [NSString stringWithFormat:@"viewController_%p",view];
}

@interface SwipeTableViewController ()<SwipeTableViewDelegate, SwipeTableViewDataSource>

@property (nonatomic, strong) SwipeTableView *swipeTableView;
@property (nonatomic, strong) NSMutableDictionary *viewControllerCache;
@property (nonatomic, assign) BOOL firstViewWillAppear;
@property (nonatomic, assign) BOOL firstViewDidAppear;
@property (nonatomic, assign) CGPoint startOffset;

@end

@implementation SwipeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self commonInit];
    [self initView];
}

- (void)commonInit {
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _firstViewWillAppear = YES;
    _firstViewDidAppear = YES;
}

- (void)initView {
    self.swipeTableView = [[SwipeTableView alloc] initWithFrame:self.view.bounds];
    _swipeTableView.backgroundColor = self.view.backgroundColor;
    _swipeTableView.delegate = self;
    _swipeTableView.dataSource = self;
    
    [self.view addSubview:_swipeTableView];
}

- (UIViewController *)viewControllerForView:(UIView *)view {
    NSString *key = ViewControllerCacheKeyForView(view);
    return _viewControllerCache[key];
}

- (void)setViewController:(UIViewController *)viewController forView:(UIView *)view {
    if (!_viewControllerCache) {
        _viewControllerCache = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    NSString *key = ViewControllerCacheKeyForView(view);
    _viewControllerCache[key] = viewController;
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index reusingView:(UIView *)view {
    UIViewController *viewController = nil;
    // Get the view controller.
    if (_dataSource && [_dataSource respondsToSelector:@selector(swipeTableViewController:viewControllerForIndex:reusingViewController:)]) {
        UIViewController *reusingViewController = [self viewControllerForView:view];
        viewController = [_dataSource swipeTableViewController:self
                                        viewControllerForIndex:index
                                         reusingViewController:reusingViewController];
    }else if (index >= 0 && index < _viewControllers.count) {
        viewController = [self viewControllerAtIndex:index];
    }
    return viewController;
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index {
    if (index < 0 || index > _viewControllers.count - 1) {
        return nil;
    }
    id viewController = _viewControllers[index];
    if ([viewController isKindOfClass:[NSString class]]) {
        viewController = [NSClassFromString(viewController) new];
    }else if (class_isMetaClass(object_getClass(viewController))) {
        viewController = [(Class)viewController new];
    }
    return viewController;
}

#pragma mark - 

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated {
    UIViewController *fromViewController = [self viewControllerForView:_swipeTableView.currentItemView];
    [fromViewController beginAppearanceTransition:NO animated:animated];
    
    [_swipeTableView scrollToItemAtIndex:index animated:animated];
    
    UIViewController *toViewController = [self viewControllerForView:_swipeTableView.currentItemView];
    [toViewController beginAppearanceTransition:YES animated:animated];
    
    if (!animated) {
        [fromViewController endAppearanceTransition];
        [toViewController endAppearanceTransition];
    }
}

#pragma mark - SwipeTableView M

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    if (_dataSource && [_dataSource respondsToSelector:@selector(numberOfControllersInSwipeTableViewController:)]) {
        return [_dataSource numberOfControllersInSwipeTableViewController:self];
    }
    return _viewControllers.count;
}

- (UIView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view {
    UIView *newView = view;
    
    // Get the view controller.
    UIViewController *viewController = [self viewControllerAtIndex:index reusingView:view];
    
    // Cache the view controller for view key.
    if (viewController && !viewController.parentViewController) {
        [self setViewController:viewController forView:newView];
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];
    }
    
    return newView;
}

- (void)swipeTableViewWillBeginDragging:(SwipeTableView *)swipeView {
    _startOffset = swipeView.contentView.contentOffset;
}

- (void)swipeTableViewDidEndDecelerating:(SwipeTableView *)swipeView {
    
}

- (void)swipeTableViewDidScroll:(SwipeTableView *)swipeView {
    // Handle the life cycle of child view controllers when swipe.
    UIScrollView *scrollView = swipeView.contentView;
    if (scrollView.isDragging) {
        CGFloat offsetX = scrollView.contentOffset.x;
        // move left
        
    }
}

#pragma mark - Life Cycle

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_swipeTableView setFrame:self.view.bounds];
}

/// Disabel auto change the life cycle of child view controller.
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Call view will appear to current view controller.
    if (_firstViewWillAppear) {
        _firstViewWillAppear = NO;
        [[self viewControllerForView:_swipeTableView.currentItemView] beginAppearanceTransition:YES
                                                                                       animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Call view did appear to current view controller.
    if (_firstViewDidAppear) {
        _firstViewDidAppear = NO;
        [[self viewControllerForView:_swipeTableView.currentItemView] endAppearanceTransition];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
