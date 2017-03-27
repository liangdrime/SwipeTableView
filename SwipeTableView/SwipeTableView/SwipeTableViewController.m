//
//  SwipeTableViewController.m
//  SwipeTableView
//
//  Created by Roylee on 2017/3/27.
//  Copyright © 2017年 Roy lee. All rights reserved.
//

#import "SwipeTableViewController.h"

@interface SwipeTableViewController ()<SwipeTableViewDelegate, SwipeTableViewDataSource>

@property (nonatomic, strong) SwipeTableView *swipeTableView;

@end

@implementation SwipeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self initView];
}

- (void)initView {
    self.swipeTableView = [[SwipeTableView alloc] initWithFrame:self.view.bounds];
    _swipeTableView.backgroundColor = self.view.backgroundColor;
    _swipeTableView.delegate = self;
    _swipeTableView.dataSource = self;
    
    [self.view addSubview:_swipeTableView];
    
}

#pragma mark - SwipeTableView M

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    return 0;
}

- (UIView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    return view;
}


#pragma mark - Life Cycle

/// Disabel auto change the life cycle of child view controller.
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
     
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
