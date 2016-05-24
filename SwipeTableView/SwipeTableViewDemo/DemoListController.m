//
//  DemoListController.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/2.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "DemoListController.h"
#import "DemoViewController.h"

@interface DemoListController ()

@property (nonatomic, strong) NSArray * dataSource;

@end

@implementation DemoListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = @[@{
                            @"title":@"ReuseOneKindView",
                            @"actionIdfy":kShouldReuseableViewIdentifier,
                          },
                        @{
                            @"title":@"AdjustItemsContentOffset",
                            @"actionIdfy":kAdjustContentOffsetDefaultIdentifier,
                            },
                        @{
                            @"title":@"AdjustItemsContentSize",
                            @"actionIdfy":kAdjustContentSizeToFitMaxItemIdentifier,},
                        @{
                            @"title":@"HiddenNavigationBar",
                            @"actionIdfy":kHiddenNavigationBarIdentifier,
                            }];
}

#pragma mark - UITableView M
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"list_cell" forIndexPath:indexPath];
    cell.textLabel.text = _dataSource[indexPath.row][@"title"];
    return cell;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    DemoViewController * demoVC = [segue destinationViewController];
    UITableViewCell * cell = sender;
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    demoVC.actionIdentifier = _dataSource[indexPath.row][@"actionIdfy"];
    demoVC.title            = _dataSource[indexPath.row][@"title"];
    [super prepareForSegue:segue sender:sender];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
