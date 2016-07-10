//
//  STRefreshHeader.h
//  SwipeTableView
//
//  Created by Roy lee on 16/7/10.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kSTRefreshHeaderHeight  60
#define kSTRefreshImageWidth    40

@interface STRefreshHeader : UIView

+ (instancetype)headerWithRefreshingBlock:(void(^)(STRefreshHeader * header))refreshingBlock;
+ (instancetype)headerWithRefreshingTarget:(id)target refreshingAction:(SEL)action;

- (void)beganRefreshing;
- (void)endRefreshing;

@end
