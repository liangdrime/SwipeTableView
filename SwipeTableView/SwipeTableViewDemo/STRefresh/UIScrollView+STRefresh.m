//
//  UIScrollView+STRefresh.m
//  SwipeTableView
//
//  Created by Roy lee on 16/7/10.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "UIScrollView+STRefresh.h"
#import <objc/runtime.h>

@implementation UIScrollView (STRefresh)

- (STRefreshHeader *)header {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHeader:(STRefreshHeader *)header {
    [self.header removeFromSuperview];
    [self addSubview:header];
    
    SEL key = @selector(header);
    objc_setAssociatedObject(self, key, header, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
