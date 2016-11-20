//
//  SLCircleAnimator.m
//
//  Created by 秦-政 on 2016/9/22.
//  Copyright © 2016年  All rights reserved.
//

#import "SLCircleAnimator.h"

@interface SLCircleAnimator() <UIViewControllerAnimatedTransitioning, CAAnimationDelegate>

@end

@implementation SLCircleAnimator {
    /// 是否展现标记
    BOOL _isPresented;
    
    /// 转场上下文
    __weak id <UIViewControllerContextTransitioning> _transitionContext;
}

/// 告诉控制器谁来提供展现转场动画
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    _isPresented = YES;
    
    return self;
}

/// 告诉控制器谁来提供解除转场动画
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    _isPresented = NO;
    
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning
/**
 返回动画时长

 @param transitionContext 转场上下文

 @return 动画时长
 */
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

/**
 是转场动画最核心的方法 - 由程序员提供自己的动画实现！

 @param transitionContext 转场上下文 - 提供转场动画的所有细节
 
 * 容器视图 - 是转场动画表演的舞台
 * 转场上下文会对展现的控制器`强`引用！
 */
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    // 1. 容器视图
    UIView *containerView = [transitionContext containerView];
    
    // 2. 获取目标视图，如果是展现，取 toView ／ 如果是解除，取 fromView
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
    UIView *view = _isPresented ? toView : fromView;
    
    // 3. 添加目标视图到容器视图
    if (_isPresented) {
        [containerView addSubview:view];
    }
    
    // 4. 针对 view 执行动画...
    // 应该在`动画完成`之后，在通知系统转场结束
    [self circleAnimWithView:view];
    
    // 5. !!!一定要完成 - 如果不完成，系统会一直等待转场完成，就无法接收用户的任何交互
    // [transitionContext completeTransition:YES];
    // 记录成员变量
    _transitionContext = transitionContext;
}

#pragma mark - CAAnimationDelegate
/**
 监听动画完成

 @param anim 动画
 @param flag 完成
 */
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
    NSLog(@"完成 - %@", anim);
    // !!!一定要完成 - 如果不完成，系统会一直等待转场完成，就无法接收用户的任何交互
    [_transitionContext completeTransition:YES];
}

#pragma mark - 动画方法
- (void)circleAnimWithView:(UIView *)view {
    
    // 1. 实例化图层
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    // 2. 设置图层属性
    // 路径
    CGFloat radius = 50;
    CGFloat margin = 20;
    CGFloat viewWidth = view.bounds.size.width;
    CGFloat viewHeight = view.bounds.size.height;
    
    // 初始位置
    CGRect rect = CGRectMake(viewWidth - radius - margin, margin, radius, radius);
    UIBezierPath *beginPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    
    layer.path = beginPath.CGPath;
    
    // 计算对角线 勾股定理
    CGFloat maxRadius = sqrt(viewWidth * viewWidth + viewHeight * viewHeight);
    
    // 结束位置 - 利用缩进，参数为负，是放大矩形，中心点保持不变
    CGRect endRect = CGRectInset(rect, -maxRadius, -maxRadius);
    UIBezierPath *endPath = [UIBezierPath bezierPathWithOvalInRect:endRect];
    
    // 3. 设置图层的遮罩 - 会裁切视图，视图本质上没有发生任何的变化，但是只会显示路径包含范围内的内容
    // 提示：一旦设置为 mask 属性，填充颜色无效！
    view.layer.mask = layer;
    
    // 4. 动画 - 如果要做 shapeLayer 的动画，不能使用 UIView 的动画方法，应该用核心动画
    // 1> 实例化动画对象
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    
    // 2> 设置动画属性 - 时长／fromValue / toValue
    anim.duration = [self transitionDuration:_transitionContext];
    
    // 判断是否是展现
    if (_isPresented) {
        anim.fromValue = (__bridge id _Nullable)(beginPath.CGPath);
        anim.toValue = (__bridge id _Nullable)(endPath.CGPath);
    } else {
        anim.fromValue = (__bridge id _Nullable)(endPath.CGPath);
        anim.toValue = (__bridge id _Nullable)(beginPath.CGPath);
    }
    
    // 设置向前填充模式
    anim.fillMode = kCAFillModeForwards;
    
    // 完成之后不删除
    anim.removedOnCompletion = NO;
    
    // 设置动画代理
    anim.delegate = self;
    
    // 3> 将动画添加到图层 - ShaperLayer，让哪个图层动画，就应该将动画添加到哪个图层
    [layer addAnimation:anim forKey:nil];
}

@end
