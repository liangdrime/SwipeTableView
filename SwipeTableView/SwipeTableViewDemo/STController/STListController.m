//
//  STListController.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/2.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "STListController.h"
#import "STViewController.h"

@interface STListController ()

@property (nonatomic, strong) NSArray * dataSource;

@end

@implementation STListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = @[@{
                            @"title":@"SingleOneKindView",
                            @"type":@(STControllerTypeNormal),
                            },
                        @{
                            @"title":@"HybridItemViews",
                            @"type":@(STControllerTypeHybrid),
                            },
                        @{
                            @"title":@"DisabledBarScroll",
                            @"type":@(STControllerTypeDisableBarScroll),
                            },
                        @{
                            @"title":@"HiddenNavigationBar",
                            @"type":@(STControllerTypeHiddenNavBar),
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
    STViewController * demoVC = [segue destinationViewController];
    UITableViewCell * cell  = sender;
    NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
    demoVC.type             = (STControllerType)[_dataSource[indexPath.row][@"type"] integerValue];
    demoVC.title            = _dataSource[indexPath.row][@"title"];
    [super prepareForSegue:segue sender:sender];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
