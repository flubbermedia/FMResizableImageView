//
//  FMResizableImageView.m
//
//  Created by Maurizio Cremaschi and Andrea Ottolina on 19/09/2012.
//  Copyright 2012 Flubber Media Ltd.
//
//  Distributed under the permissive zlib License
//  Get the latest version from https://github.com/flubbermedia/FMResizableImageView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "FMResizableImageView.h"

@interface FMResizableImageView()

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *rotateScaleButton;
@property (nonatomic, strong) CALayer *borderLayer;

@property (nonatomic, assign) CGAffineTransform savedTransform;

@property (nonatomic, assign) CGAffineTransform rotationTransform;
@property (nonatomic, assign) CGAffineTransform scaleTransform;

@property (nonatomic, assign) CGPoint savedAnchorPoint;

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
        
        _savedAnchorPoint = self.layer.anchorPoint;
        [self setAnchorPoint:CGPointMake(0.5, 0.5) forView:self];
	}
	
	if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint center = CGPointMake(CGRectGetMidX(gesture.view.superview.bounds), CGRectGetMidY(gesture.view.superview.bounds));
		CGPoint currentPoint = [gesture locationInView:gesture.view.superview];
		
		CGPoint translation = [gesture translationInView:gesture.view.superview];
		CGPoint originPoint = CGPointApplyAffineTransform(currentPoint, CGAffineTransformMakeTranslation(-translation.x, -translation.y));
		
		CGFloat originalDistance = _CGPointDistanceBetweenPoints(center, originPoint);
		CGFloat currentDistance = _CGPointDistanceBetweenPoints(center, currentPoint);
		CGFloat scale = currentDistance / originalDistance;
		
		CGFloat originalRotation = _CGPointAngleBetweenPoints(center, originPoint);
		CGFloat currentRotation = _CGPointAngleBetweenPoints(center, currentPoint);
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
    
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
    {
        [self setAnchorPoint:_savedAnchorPoint forView:self];
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

#pragma mark - Utilities

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

#pragma mark - Math

CGFloat _CGPointDistanceBetweenPoints(CGPoint first, CGPoint second)
{
	CGFloat dx = second.x - first.x;
	CGFloat dy = second.y - first.y;
	return sqrtf(dx * dx + dy * dy);
}

CGFloat _CGPointAngleBetweenPoints(CGPoint first, CGPoint second)
{
	CGFloat dx = second.x - first.x;
	CGFloat dy = second.y - first.y;
	return atan2f(dy, dx);
}

@end
