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

@property (nonatomic, assign) CGAffineTransform finalTransform;
@property (nonatomic, assign) CGAffineTransform savedTransform;

@property (nonatomic, assign) CGPoint savedAnchorPoint;

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *rotateScaleRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *deleteRecognizer;

@end

@implementation FMResizableImageView

- (void)setup
{	
	_editingEnabled = NO;
	_controlsScaleCorrection = 1;
	_deletionHandler = nil;
	
	_finalTransform = self.transform;
	
	_imageView = [UIImageView new];
	_rotateControlImageView = [UIImageView new];
	_deleteControlImageView = [UIImageView new];
	
	[_imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:@"imageView.image"];
	[_rotateControlImageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:@"rotateControlImageView.image"];
	[_deleteControlImageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:@"deleteControlImageView.image"];
	
	_imageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
	_imageView.layer.borderWidth = 2.;
	
	
	
//	_borderLayer = [CALayer layer];
//	_borderLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
//	_borderLayer.borderWidth = 2.;
//	_borderLayer.frame = self.layer.bounds;
//	_borderLayer.hidden = !_editingEnabled;
//	[self.layer addSublayer:_borderLayer];
//	
//	_rotateScaleControl = [[UIImageView alloc] init];
//	_rotateScaleControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin;
//	_rotateScaleControl.hidden = !_editingEnabled;
//	[self addSubview:_rotateScaleControl];
//	
//	_deleteControl = [[UIImageView alloc] init];
//	_deleteControl.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
//	_deleteControl.hidden = !_editingEnabled;
//	[self addSubview:_deleteControl];
	
	_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[_tapRecognizer setDelegate:self];
	[self addGestureRecognizer:_tapRecognizer];
	
	_moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
	[_moveRecognizer setDelegate:self];
	[_moveRecognizer setMinimumNumberOfTouches:1];
	[_moveRecognizer setMaximumNumberOfTouches:1];
	[self addGestureRecognizer:_moveRecognizer];
	
	_rotateScaleRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateScale:)];
	[_rotateScaleRecognizer setEnabled:_editingEnabled];
	[_rotateScaleRecognizer setDelegate:self];
	[_rotateScaleRecognizer setMinimumNumberOfTouches:1];
	[_rotateScaleRecognizer setMaximumNumberOfTouches:1];
	[self addGestureRecognizer:_rotateScaleRecognizer];
	
	_deleteRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(delete:)];
	[_deleteRecognizer setEnabled:_editingEnabled];
	[_deleteRecognizer setDelegate:self];
	[self addGestureRecognizer:_deleteRecognizer];
	
}

- (void)dealloc
{
    [_imageView removeObserver:self forKeyPath:@"image" context:@"imageView.image"];
	[_rotateControlImageView removeObserver:self forKeyPath:@"image" context:@"rotateControlImageView.image"];
	[_deleteControlImageView removeObserver:self forKeyPath:@"image" context:@"deleteControlImageView.image"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self setup];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self setup];
	}
	return self;
}

#pragma mark - Image Updates

- (void)updateImageViewImage
{
	[_imageView sizeToFit];
	CGPoint savedCenter = self.center;
	self.frame = _imageView.frame;
	
	_imageView.frame = CGRectOffset(_imageView.frame, - CGRectGetMidX(_imageView.frame), - CGRectGetMidY(_imageView.frame));
	self.center = savedCenter;
	
//	CGPoint savedCenter = self.center;
//	CGRect newFrame = CGRectZero;
//	newFrame.size = newFrameSize;
//	self.frame
}

#pragma mark - Setter/Getter

//- (void)setEditingEnabled:(BOOL)enabled
//{
//	_editingEnabled = enabled;
//	_borderLayer.hidden = !_editingEnabled;
//	_rotateScaleControl.hidden = !_editingEnabled;
//	_deleteControl.hidden = !_editingEnabled;
//	
//	_rotateScaleRecognizer.enabled = _editingEnabled;
//	_deleteRecognizer.enabled = _editingEnabled;
//}
//
//- (void)setControlsScaleCorrection:(CGFloat)correction
//{
//	_controlsScaleCorrection = correction;
//	[self updateControls];
//}
//
//- (void)setDeleteImage:(UIImage *)deleteImage
//{
//	_deleteControl.image = deleteImage;
//	[_deleteControl sizeToFit];
//	_deleteControl.center = CGPointZero;
//}
//
//- (void)setRotateScaleImage:(UIImage *)rotateScaleImage
//{
//	_rotateScaleControl.image = rotateScaleImage;
//	[_rotateScaleControl sizeToFit];
//	_rotateScaleControl.center = CGPointMake(CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
//}

#pragma mark - Private methods

- (void)updateControls
{
//	CGAffineTransform controlsTransform = CGAffineTransformScale(CGAffineTransformInvert(_finalTransform), 1.0 / _controlsScaleCorrection, 1.0 / _controlsScaleCorrection);
//	_deleteControl.transform = controlsTransform;
//	_rotateScaleControl.transform = controlsTransform;
}

#pragma mark - Gestures

- (void)tap:(UITapGestureRecognizer *)gesture
{
	self.editingEnabled = !_editingEnabled;
}

- (void)move:(UIPanGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		if (!_editingEnabled) self.editingEnabled = !_editingEnabled;
	}
	
	if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint translation = [gesture translationInView:gesture.view.superview];
		gesture.view.center = CGPointMake(gesture.view.center.x + translation.x, gesture.view.center.y + translation.y);
		[gesture setTranslation:CGPointZero inView:gesture.view.superview];
	}
}

- (void)rotateScale:(UIPanGestureRecognizer *)gesture
{
	UIView *targetView = gesture.view;
	
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		_savedTransform = targetView.transform;
		
		_savedAnchorPoint = self.layer.anchorPoint;
		[self setAnchorPoint:CGPointMake(0.5, 0.5) forView:self];
	}
	
	if (gesture.state == UIGestureRecognizerStateChanged)
	{
		CGPoint center = CGPointMake(CGRectGetMidX(targetView.bounds), CGRectGetMidY(targetView.bounds));
		CGPoint currentPoint = [gesture locationInView:targetView];
		
		CGPoint translation = [gesture translationInView:targetView];
		CGPoint originPoint = CGPointApplyAffineTransform(currentPoint, CGAffineTransformMakeTranslation(-translation.x, -translation.y));
		
		CGFloat originalDistance = _CGPointDistanceBetweenPoints(center, originPoint);
		CGFloat currentDistance = _CGPointDistanceBetweenPoints(center, currentPoint);
		CGFloat scale = currentDistance / originalDistance;
		
		CGFloat originalRotation = _CGPointAngleBetweenPoints(center, originPoint);
		CGFloat currentRotation = _CGPointAngleBetweenPoints(center, currentPoint);
		CGFloat rotation = currentRotation - originalRotation;
		
		_finalTransform = _savedTransform;
		_finalTransform = CGAffineTransformScale(_finalTransform, scale, scale);
		
		if (_finalTransform.a < 0.5 && _finalTransform.d < 0.5)
		{
			_finalTransform.a = 0.5;
			_finalTransform.d = 0.5;
		}
		else if (_finalTransform.a > 2.0 && _finalTransform.d > 2.0)
		{
			_finalTransform.a = 2.0;
			_finalTransform.d = 2.0;
		}
		
		_finalTransform = CGAffineTransformRotate(_finalTransform, rotation);
		targetView.transform = _finalTransform;
		
		[self updateControls];
	}
	
	if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
	{
		[self setAnchorPoint:_savedAnchorPoint forView:self];
	}
}

- (void)delete:(UITapGestureRecognizer *)gesture
{
	[UIView animateWithDuration:0.3 animations:^{
		self.alpha = 0.;
	} completion:^(BOOL finished) {
		[self removeFromSuperview];
		if (_deletionHandler)
			_deletionHandler(self);
	}];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	
//	CGPoint pointInView = [touch locationInView:gestureRecognizer.view];
//	
//	if (gestureRecognizer.enabled && gestureRecognizer == _rotateScaleRecognizer && CGRectContainsPoint(_rotateScaleControl.frame, pointInView))
//	{
//		return YES;
//	}
//	
//	if (gestureRecognizer.enabled && gestureRecognizer == _deleteRecognizer && CGRectContainsPoint(_deleteControl.frame, pointInView))
//	{
//		return YES;
//	}
//	
//	if (gestureRecognizer.enabled && gestureRecognizer == _tapRecognizer && CGRectContainsPoint(self.bounds, pointInView))
//	{
//		return YES;
//	}
//
//	if (gestureRecognizer.enabled && gestureRecognizer == _moveRecognizer && CGRectContainsPoint(self.bounds, pointInView))
//	{
//		return YES;
//	}
	
	return NO;
}

#pragma mark - Touch

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView *returnView = [super hitTest:point withEvent:event];
	for (UIView *subview in self.subviews)
	{
        if (!subview.hidden && CGRectContainsPoint(subview.frame, point))
		{
			returnView = subview;
            break;
        }
    }
    return returnView;
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

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(__bridge NSString *)context isEqualToString:@"imageView.image"] && object == _imageView)
    {
        [self updateImageViewImage];
    }
	if ([(__bridge NSString *)context isEqualToString:@"rotateControlImageView.image"] && object == _rotateControlImageView)
    {
        //[self update];
    }
	if ([(__bridge NSString *)context isEqualToString:@"deleteControlImageView.image"] && object == _deleteControlImageView)
    {
        //[self update];
    }
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
