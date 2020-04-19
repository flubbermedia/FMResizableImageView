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
#import <QuartzCore/QuartzCore.h>

static CGFloat const kBorderWidth = 2.0f;

@interface FMResizableImageView()

@property (nonatomic, strong) CALayer *borderLayer;
@property (nonatomic, strong) UIImageView *deleteControl;
@property (nonatomic, strong) UIImageView *rotateScaleControl;

@property (nonatomic, assign) CGPoint savedViewCenter;
@property (nonatomic, assign) CGPoint savedTouchPoint;
@property (nonatomic, assign) CGPoint savedAnchorPoint;

@property (nonatomic, assign) CGAffineTransform currentTransform;
@property (nonatomic, assign) CGAffineTransform savedTransform;

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *rotateScaleRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *deleteRecognizer;

@end

@implementation FMResizableImageView

- (void)awakeFromNib
{
	// default settings
	
	_editingEnabled = NO;
	_controlsScaleCorrection = 1;
	_deletionHandler = nil;
	_currentTransform = self.transform;
	
	// border setup
	
	_borderLayer = [CALayer layer];
	_borderLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
	_borderLayer.borderWidth = kBorderWidth;
	_borderLayer.frame = self.layer.bounds;
	_borderLayer.hidden = !_editingEnabled;
	[self.layer addSublayer:_borderLayer];
	
	// additional controls
	
	_deleteControl = [UIImageView new];
	_deleteControl.hidden = !_editingEnabled;
	[self addSubview:_deleteControl];
	
	_rotateScaleControl = [UIImageView new];
	_rotateScaleControl.hidden = !_editingEnabled;
	[self addSubview:_rotateScaleControl];
	
	// recognizers
	
	_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[_tapRecognizer setDelegate:self];
	[self addGestureRecognizer:_tapRecognizer];
	
	_moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
	[_moveRecognizer setDelegate:self];
	[self addGestureRecognizer:_moveRecognizer];
	
	_deleteRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(delete:)];
	[_deleteRecognizer setDelegate:self];
	[_deleteRecognizer setEnabled:_editingEnabled];
	[_deleteControl addGestureRecognizer:_deleteRecognizer];
	
	_rotateScaleRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateScale:)];
	[_rotateScaleRecognizer setDelegate:self];
	[_rotateScaleRecognizer setEnabled:_editingEnabled];
	[_rotateScaleControl addGestureRecognizer:_rotateScaleRecognizer];
	
	// Enable user interaction
	
	self.userInteractionEnabled = YES;
	_deleteControl.userInteractionEnabled = YES;
	_rotateScaleControl.userInteractionEnabled = YES;
	
	//	Useful for debugging
	
	//	self.tag = 1;
	//	_deleteControl.tag = 2;
	//	_rotateScaleControl.tag = 3;
	
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

#pragma mark - Setter/Getter

- (void)setTransform:(CGAffineTransform)transform
{
	[super setTransform:transform];
	_currentTransform = transform;
	[self updateControls];
}

- (void)setEditingEnabled:(BOOL)enabled
{
	_editingEnabled = enabled;
	_borderLayer.hidden = !_editingEnabled;
	_rotateScaleControl.hidden = !_editingEnabled;
	_deleteControl.hidden = !_editingEnabled;
	
	_rotateScaleRecognizer.enabled = _editingEnabled;
	_deleteRecognizer.enabled = _editingEnabled;
}

- (void)setControlsScaleCorrection:(CGFloat)correction
{
	_controlsScaleCorrection = correction;
	[self updateControls];
}

- (void)setDeleteImage:(UIImage *)deleteImage
{
	_deleteControl.image = deleteImage;
	[_deleteControl sizeToFit];
	_deleteControl.center = CGPointZero;
}

- (void)setRotateScaleImage:(UIImage *)rotateScaleImage
{
	_rotateScaleControl.image = rotateScaleImage;
	[_rotateScaleControl sizeToFit];
	_rotateScaleControl.center = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
}

#pragma mark - Public methods

- (void)flashBorder
{
	_borderLayer.hidden = NO;
	double delayInSeconds = 0.3;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		_borderLayer.hidden = YES;
	});
}

#pragma mark - Private methods

- (void)updateControls
{
	CGAffineTransform controlsTransform = CGAffineTransformScale(CGAffineTransformInvert(_currentTransform), 1.0 / _controlsScaleCorrection, 1.0 / _controlsScaleCorrection);
	_deleteControl.transform = controlsTransform;
	_rotateScaleControl.transform = controlsTransform;
	_borderLayer.borderWidth =  kBorderWidth * sqrt(controlsTransform.b * controlsTransform.b + controlsTransform.d * controlsTransform.d);
}

#pragma mark - Gestures

- (void)tap:(UITapGestureRecognizer *)gesture
{
	if (!_editingEnabled)
	{
		self.editingEnabled = YES;
	}
	else
	{
		
		int orientation;
		
		switch (self.image.imageOrientation) {
			case UIImageOrientationUp:
				orientation = UIImageOrientationUpMirrored;
				break;
			case UIImageOrientationDown:
				orientation = UIImageOrientationDownMirrored;
				break;
			case UIImageOrientationLeft:
				orientation = UIImageOrientationLeftMirrored;
				break;
			case UIImageOrientationRight:
				orientation = UIImageOrientationRightMirrored;
				break;
			case UIImageOrientationUpMirrored:
				orientation = UIImageOrientationUp;
				break;
			case UIImageOrientationDownMirrored:
				orientation = UIImageOrientationDown;
				break;
			case UIImageOrientationLeftMirrored:
				orientation = UIImageOrientationLeft;
				break;
			case UIImageOrientationRightMirrored:
				orientation = UIImageOrientationRight;
				break;
			default:
				break;
		}
		
		UIImage *flippedImage = [UIImage imageWithCGImage:self.image.CGImage scale:1.0 orientation:orientation];
		self.image = flippedImage;
		
	}
}

- (void)move:(UIPanGestureRecognizer *)gesture
{
	UIView *targetView = self;
	
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		_savedViewCenter = targetView.center;
		if (!_editingEnabled) self.editingEnabled = !_editingEnabled;
	}
	
	if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint translation = [gesture translationInView:targetView.superview];
		CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(translation.x, translation.y);
		targetView.center = CGPointApplyAffineTransform(_savedViewCenter, translationTransform);
	}
}

- (void)delete:(UITapGestureRecognizer *)gesture
{
	[UIView animateWithDuration:0.3 animations:^{
		self.alpha = 0.;
	} completion:^(BOOL finished) {
		[self removeFromSuperview];
        if (self->_deletionHandler)
            self->_deletionHandler(self);
	}];
}

- (void)rotateScale:(UIPanGestureRecognizer *)gesture
{
	UIView *targetView = self;
	
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		_savedTransform = targetView.transform;
		_savedViewCenter = self.center;
		_savedTouchPoint = [gesture locationInView:targetView.superview];
		_savedAnchorPoint = self.layer.anchorPoint;
		
		[self setAnchorPoint:CGPointMake(0.5, 0.5) forView:self];
	}
	
	if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint currentPoint = [gesture locationInView:targetView.superview];
		
		float originalDistance = [self distanceFrom:_savedViewCenter to:_savedTouchPoint];
		float currentDistance = [self distanceFrom:_savedViewCenter to:currentPoint];
		CGFloat scale = currentDistance / originalDistance;
		
		CGFloat originalRotation = [self angleBetween:_savedViewCenter and:_savedTouchPoint];
		CGFloat currentRotation = [self angleBetween:_savedViewCenter and:currentPoint];
		CGFloat rotation = currentRotation - originalRotation;
		
		_currentTransform = CGAffineTransformIdentity;
		_currentTransform = CGAffineTransformScale(_currentTransform, scale, scale);
		
		_currentTransform = CGAffineTransformRotate(_currentTransform, rotation);
		_currentTransform = CGAffineTransformConcat(_savedTransform, _currentTransform);
		targetView.transform = _currentTransform;
		
		[self updateControls];
	}
	
	if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
	{
		[self setAnchorPoint:_savedAnchorPoint forView:self];
	}
}

#pragma mark - Gestures Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	return (gestureRecognizer == _tapRecognizer ||
			gestureRecognizer == _moveRecognizer ||
			gestureRecognizer == _rotateScaleRecognizer ||
			gestureRecognizer == _deleteRecognizer);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	return (touch.view == gestureRecognizer.view);
}

#pragma mark - Touch

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	for (UIView *subview in self.subviews)
	{
        if (!subview.hidden && CGRectContainsPoint(subview.frame, point))
		{
			return subview;
        }
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark - Utilities

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
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

- (CGFloat)distanceFrom:(CGPoint)point1 to:(CGPoint)point2
{
	CGFloat dx = (point2.x - point1.x);
	CGFloat dy = (point2.y - point1.y);
	return sqrtf(dx * dx + dy * dy);
}

- (CGFloat)angleBetween:(CGPoint)point1 and:(CGPoint)point2
{
	CGFloat dx = point2.x - point1.x;
	CGFloat dy = point2.y - point1.y;
	return atan2f(dy, dx);
}

@end
