//
//  SwipeTableViewController.h
//  SwipeTableView
//
//  Created by Roylee on 2017/3/27.
//  Copyright © 2017年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeTableView.h"

@class SwipeTableViewController;
@protocol SwipeTableViewControllerDelegate <NSObject>

- (void)swipeTableViewControllerDidScroll:(SwipeTableViewController *)swipeTableViewController;
- (void)swipeTableViewControllerCurrentItemIndexDidChange:(SwipeTableViewController *)swipeTableViewController;
- (void)swipeTableViewController:(SwipeTableViewController *)swipeTableViewController didSelectViewAtIndex:(NSInteger)index;

@end



@protocol SwipeTableViewControllerDataSource <NSObject>

- (NSInteger)numberOfControllersInSwipeTableViewController:(SwipeTableViewController *)swipeTableViewController;
- (UIViewController *)swipeTableViewController:(SwipeTableViewController *)swipeTableViewController viewControllerForIndex:(NSInteger)index reusingViewController:(UIViewController *)viewController;

@end



@interface SwipeTableViewController : UIViewController

@property (nonatomic, readonly) SwipeTableView *swipeTableView;
@property (nonatomic, weak) id <SwipeTableViewControllerDataSource>dataSource;
@property (nonatomic, weak) id <SwipeTableViewControllerDelegate>delegate;
@property (nonatomic, strong) NSArray *viewControllers;

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

@end
