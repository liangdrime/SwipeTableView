//
//  STViewController.h
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#define RGBColorAlpha(r,g,b,f)   [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:f]
#define RGBColor(r,g,b)          RGBColorAlpha(r,g,b,1)

typedef NS_ENUM(NSInteger,STControllerType) {
    STControllerTypeNormal,
    STControllerTypeHybrid,
    STControllerTypeDisableBarScroll,
    STControllerTypeHiddenNavBar,
};

@interface STViewController : UIViewController

@property (nonatomic, assign) STControllerType type;
@property (nonatomic, strong) UIImageView * headerImageView;

@end


