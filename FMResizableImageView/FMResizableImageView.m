//
//  FMResizerView.m
//  Demo
//
//  Created by Andrea Ottolina on 19/09/2012.
//  Copyright (c) 2012 Flubber Media Ltd. All rights reserved.
//

#import "FMResizableImageView.h"

@interface FMResizableImageView()

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *rotateScaleButton;
@property (nonatomic, strong) CALayer *borderLayer;

@property (nonatomic, assign) CGAffineTransform savedTransform;

@property (nonatomic, assign) CGAffineTransform rotationTransform;
@property (nonatomic, assign) CGAffineTransform scaleTransform;

@end

@implementation FMResizableImageView

- (void)awakeFromNib
{
	self.userInteractionEnabled = YES;
	
	_borderLayer = [CALayer layer];
	_borderLayer.borderColor = [UIColor blackColor].CGColor;
	_borderLayer.borderWidth = 1.;
	_borderLayer.frame = self.layer.bounds;
	
	[self.layer addSublayer:_borderLayer];
	
	_rotateScaleButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
	_rotateScaleButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
	_rotateScaleButton.center = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
	[self addSubview:_rotateScaleButton];

	_closeButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
	_closeButton.center = CGPointZero;
	_closeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
	[self addSubview:_closeButton];
	
	UIPanGestureRecognizer *moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
	[moveRecognizer setMinimumNumberOfTouches:1];
	[moveRecognizer setMaximumNumberOfTouches:1];
	[moveRecognizer setDelegate:self];
	[self addGestureRecognizer:moveRecognizer];
	
	UIPanGestureRecognizer *rotateScaleRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateScale:)];
	[rotateScaleRecognizer setMinimumNumberOfTouches:1];
	[rotateScaleRecognizer setMaximumNumberOfTouches:1];
	[rotateScaleRecognizer setDelegate:self];
	[_rotateScaleButton addGestureRecognizer:rotateScaleRecognizer];
	
	UITapGestureRecognizer *closeRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close:)];
	[closeRecognizer setDelegate:self];
	[_closeButton addGestureRecognizer:closeRecognizer];
}

- (id)initWithImage:(UIImage *)image
{
	self = [super initWithImage:image];
	if (self)
	{
		[self awakeFromNib];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self awakeFromNib];
	}
	return self;
}

#pragma mark - Gestures

- (void)move:(UIPanGestureRecognizer *)gesture
{
    CGPoint translation = [gesture translationInView:gesture.view.superview];

    gesture.view.center = CGPointMake(gesture.view.center.x + translation.x, gesture.view.center.y + translation.y);
    
    [gesture setTranslation:CGPointZero inView:gesture.view.superview];
}

- (void)rotateScale:(UIPanGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		_savedTransform = gesture.view.superview.transform;
	}
	
	if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint center = CGPointMake(CGRectGetMidX(gesture.view.superview.bounds), CGRectGetMidY(gesture.view.superview.bounds));
		CGPoint currentPoint = [gesture locationInView:gesture.view.superview];
		
		CGPoint translation = [gesture translationInView:gesture.view.superview];
		CGPoint originPoint = CGPointApplyAffineTransform(currentPoint, CGAffineTransformMakeTranslation(-translation.x, -translation.y));
		
		CGFloat originalDistance = CGPointDistanceBetweenPoints(center, originPoint);
		CGFloat currentDistance = CGPointDistanceBetweenPoints(center, currentPoint);
		CGFloat scale = currentDistance / originalDistance;
		
		CGFloat originalRotation = CGPointAngleBetweenPoints(center, originPoint);
		CGFloat currentRotation = CGPointAngleBetweenPoints(center, currentPoint);
		CGFloat rotation = currentRotation - originalRotation;
		
		CGAffineTransform finalTransform = _savedTransform;
		finalTransform = CGAffineTransformScale(finalTransform, scale, scale);

		if (finalTransform.a < 0.5 && finalTransform.d < 0.5)
		{
			finalTransform.a = 0.5;
			finalTransform.d = 0.5;
		}
		else if (finalTransform.a > 2.0 && finalTransform.d > 2.0)
		{
			finalTransform.a = 2.0;
			finalTransform.d = 2.0;
		}
		
		finalTransform = CGAffineTransformRotate(finalTransform, rotation);
		gesture.view.superview.transform = finalTransform;
		
		_closeButton.transform = CGAffineTransformInvert(finalTransform);
		_rotateScaleButton.transform = CGAffineTransformInvert(finalTransform);
	}
}

- (void)close:(UITapGestureRecognizer *)gesture
{
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - Touch

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	for (UIView *subview in self.subviews) {
        if (CGRectContainsPoint(subview.frame, point)) {
            return subview;
            break;
        }
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - Math

CGFloat CGPointDistanceBetweenPoints(CGPoint first, CGPoint second)
{
	CGFloat dx = second.x - first.x;
	CGFloat dy = second.y - first.y;
	return sqrtf(dx * dx + dy * dy);
}

CGFloat CGPointAngleBetweenPoints(CGPoint first, CGPoint second)
{
	CGFloat dx = second.x - first.x;
	CGFloat dy = second.y - first.y;
	return atan2f(dy, dx);
}

@end
