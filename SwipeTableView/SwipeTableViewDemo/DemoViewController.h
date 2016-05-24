//
//  DemoViewController.h
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString const * kShouldReuseableViewIdentifier;
UIKIT_EXTERN NSString const * kAdjustContentOffsetDefaultIdentifier;
UIKIT_EXTERN NSString const * kAdjustContentSizeToFitMaxItemIdentifier;
UIKIT_EXTERN NSString const * kHiddenNavigationBarIdentifier;


@interface DemoViewController : UIViewController

@property (nonatomic, strong) NSString * actionIdentifier;

@end

