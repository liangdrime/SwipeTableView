//
//  UIView+STFrame.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "UIView+STFrame.h"

@implementation UIView (Frame)

-(CGFloat)st_x {
    return self.frame.origin.x;
}

-(void)setSt_x:(CGFloat)x {
    CGRect rect = self.frame;
    rect.origin.x = x;
    self.frame = rect;
}

-(CGFloat)st_y {
    return self.frame.origin.y;
}

-(void)setSt_y:(CGFloat)y {
    CGRect rect = self.frame;
    rect.origin.y = y;
    self.frame = rect;
}

-(CGFloat)st_width {
    return self.frame.size.width;
}

-(void)setSt_width:(CGFloat)width {
    CGRect rect = self.frame;
    rect.size.width = width;
    self.frame = rect;
}

-(CGFloat)st_height {
    return self.frame.size.height;
}

-(void)setSt_height:(CGFloat)height {
    CGRect rect = self.frame;
    rect.size.height = height;
    self.frame = rect;
}

-(CGFloat)st_centerX {
    return self.center.x;
}

-(void)setSt_centerX:(CGFloat)centerX {
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

-(CGFloat)st_centerY {
    return self.center.y;
}

-(void)setSt_centerY:(CGFloat)centerY {
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (CGSize)st_size {
    return self.frame.size;
}

- (void)setSt_size:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGFloat)st_top {
    return self.frame.origin.y;
}

- (void)setSt_top:(CGFloat)t {
    self.frame = CGRectMake(self.st_left, t, self.st_width, self.st_height);
}

- (CGFloat)st_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setSt_bottom:(CGFloat)b {
    self.frame = CGRectMake(self.st_left, b - self.st_height, self.st_width, self.st_height);
}

- (CGFloat)st_left {
    return self.frame.origin.x;
}

- (void)setSt_left:(CGFloat)l {
    self.frame = CGRectMake(l, self.st_top, self.st_width, self.st_height);
}

- (CGFloat)st_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setSt_right:(CGFloat)r {
    self.frame = CGRectMake(r - self.st_width, self.st_top, self.st_width, self.st_height);
}



@end
