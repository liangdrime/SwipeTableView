//
//  STTransitions.h
//  SwipeTableView
//
//  Created by Roy lee on 16/6/24.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface STTransitions : NSObject <UIViewControllerAnimatedTransitioning>

- (instancetype)initWithTransitionDuration:(NSTimeInterval)transitionDuration isPresenting:(BOOL)present;

@end
