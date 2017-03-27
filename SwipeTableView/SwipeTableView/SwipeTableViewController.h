//
//  SwipeTableViewController.h
//  SwipeTableView
//
//  Created by Roylee on 2017/3/27.
//  Copyright © 2017年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeTableView.h"

@interface SwipeTableViewController : UIViewController

@property (nonatomic, readonly) SwipeTableView *swipeTableView;
@property (nonatomic, strong) NSArray *viewControllers;

@end
