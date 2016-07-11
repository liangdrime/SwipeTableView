//
//  CustomCollectionView.h
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STCollectionView.h"

#define kScreenWidth    [UIScreen mainScreen].bounds.size.width
#define kScreenHeight   [UIScreen mainScreen].bounds.size.height

@interface CustomCollectionView : STCollectionView

- (void)refreshWithData:(id)data atIndex:(NSInteger)index;

@end
