//
//  DemoViewController.h
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#define RGBColorAlpha(r,g,b,f)   [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:f]
#define RGBColor(r,g,b)          RGBColorAlpha(r,g,b,1)

UIKIT_EXTERN NSString const * kShouldReuseableViewIdentifier;
UIKIT_EXTERN NSString const * kHybridItemViewsIdentifier;
UIKIT_EXTERN NSString const * kAdjustContentSizeToFitMaxItemIdentifier;
UIKIT_EXTERN NSString const * kDisabledSwipeHeaderBarScrollIdentifier;
UIKIT_EXTERN NSString const * kHiddenNavigationBarIdentifier;

@interface DemoViewController : UIViewController

@property (nonatomic, strong) NSString * actionIdentifier;

@end


