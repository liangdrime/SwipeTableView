//
//  STTransitions.m
//  SwipeTableView
//
//  Created by Roy lee on 16/6/24.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "STTransitions.h"
#import "STImageController.h"

#define kScreenWidth    [UIScreen mainScreen].bounds.size.width
#define kScreenHeight   [UIScreen mainScreen].bounds.size.height

@interface UIView (UIImageView)
- (UIImageView *)imageView;
@end


@interface STTransitions ()

@property (nonatomic, assign) NSTimeInterval transitionDuration;
@property (nonatomic, assign) CGFloat startingAlpha;
@property (nonatomic, assign) BOOL isPresenting;
@property (nonatomic, strong) id transitionContext;
@property (nonatomic, strong) UIView * fromView;

@end

@implementation STTransitions

- (instancetype)initWithTransitionDuration:(NSTimeInterval)transitionDuration fromView:(UIView *)fromView isPresenting:(BOOL)present {
    self = [super init];
    if (self) {
        _transitionDuration = transitionDuration;
        _isPresenting = present;;
        _fromView = fromView;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return _transitionDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIViewController * fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController * toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView * fromView = fromVC.view;
    UIView * toView = toVC.view;
    
    if (_isPresenting) {
        STImageController * imageVC = (STImageController *)toVC;
        UIImageView * fromImageView = _fromView.imageView;
        UIImageView * toImageView = imageVC.imageView;
        CGFloat imageH = fromImageView.image.size.height/fromImageView.image.size.width * kScreenWidth;
        CGRect toFrame = CGRectMake(0, (kScreenHeight - imageH)/2, kScreenWidth, imageH);
        toImageView.image = fromImageView.image;
        toImageView.frame = toFrame;
        UIImageView * transitionView = [[UIImageView alloc]initWithImage:fromImageView.image];
        
        fromView.alpha = 1.0f;
        toView.alpha = 0.3f;
        fromImageView.hidden = YES;
        toImageView.hidden = YES;
        transitionView.frame = [containerView convertRect:fromImageView.frame fromView:fromImageView.superview];
        [containerView addSubview:toVC.view];
        [containerView addSubview:transitionView];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            transitionView.frame = [containerView convertRect:toFrame fromView:toImageView.superview];
            fromView.alpha       = 0.0f;
            toView.alpha         = 1.0f;
        } completion:^(BOOL finished) {
            toImageView.hidden   = NO;
            [transitionView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }else {
        STImageController * imageVC = (STImageController *)fromVC;
        UIImageView * fromImageView = imageVC.imageView;
        UIImageView * toImageView = _fromView.imageView;
        UIImageView * transitionView = [[UIImageView alloc]initWithImage:fromImageView.image];
        
        fromView.alpha = 1.0f;
        toView.alpha = 0;
        fromImageView.hidden = YES;
        toImageView.hidden = YES;
        transitionView.frame = [containerView convertRect:fromImageView.frame fromView:fromImageView.superview];
        [containerView addSubview:toVC.view];
        [containerView addSubview:transitionView];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            transitionView.frame = [containerView convertRect:toImageView.frame fromView:toImageView.superview];
            fromView.alpha       = 0.0f;
            toView.alpha         = 1.0f;
            
        } completion:^(BOOL finished) {
            toImageView.hidden   = NO;
            [transitionView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}


@end


@implementation UIView (UIImageView)

- (UIImageView *)imageView {
    if ([self isKindOfClass:UIImageView.class]) {
        return (UIImageView *)self;
    }
    for (UIView * subView in self.subviews) {
        if ([subView isKindOfClass:UIImageView.class]) {
            return (UIImageView *)subView;
        }
    }
    return nil;
}

@end

