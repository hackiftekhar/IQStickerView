//
//  IQStickerView.m
//  Created by Iftekhar Qurashi on 15/08/13.

#import "IQStickerView.h"
#import <QuartzCore/QuartzCore.h>

CG_INLINE CGPoint CGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CG_INLINE CGPoint CGPointRorate(CGPoint point, CGPoint basePoint, CGFloat angle)
{
    CGFloat x = cos(angle) * (point.x-basePoint.x) - sin(angle) * (point.y-basePoint.y) + basePoint.x;
    CGFloat y = sin(angle) * (point.x-basePoint.x) + cos(angle) * (point.y-basePoint.y) + basePoint.y;
    
    return CGPointMake(x,y);
}

CG_INLINE CGRect CGRectSetCenter(CGRect rect, CGPoint center)
{
    return CGRectMake(center.x-CGRectGetWidth(rect)/2, center.y-CGRectGetHeight(rect)/2, CGRectGetWidth(rect), CGRectGetHeight(rect));
}

CG_INLINE CGRect CGRectScale(CGRect rect, CGFloat wScale, CGFloat hScale)
{
    return CGRectMake(rect.origin.x * wScale, rect.origin.y * hScale, rect.size.width * wScale, rect.size.height * hScale);
}

CG_INLINE CGFloat CGPointGetDistance(CGPoint point1, CGPoint point2)
{
    //Saving Variables.
    CGFloat fx = (point2.x - point1.x);
    CGFloat fy = (point2.y - point1.y);
    
    return sqrt((fx*fx + fy*fy));
}

CG_INLINE CGFloat CGAffineTransformGetAngle(CGAffineTransform t)
{
    return atan2(t.b, t.a);
}


CG_INLINE CGSize CGAffineTransformGetScale(CGAffineTransform t)
{
    return CGSizeMake(sqrt(t.a * t.a + t.c * t.c), sqrt(t.b * t.b + t.d * t.d)) ;
}


static IQStickerView *lastTouchedView;

@implementation IQStickerView
{
    CGFloat _globalInset;

    CGRect initialBounds;
    CGFloat initialDistance;

    CGPoint beginningPoint;
    CGPoint beginningCenter;

    CGPoint prevPoint;
    CGPoint touchLocation;
    
    CGFloat deltaAngle;
    
    CGAffineTransform startTransform;
    CGRect beginBounds;
}

@synthesize contentView = _contentView;
@synthesize enableClose = _enableClose;
@synthesize enableResize = _enableResize;
@synthesize enableRotate = _enableRotate;
@synthesize delegate = _delegate;
@synthesize showContentShadow = _showContentShadow;

-(void)refresh
{
    if (self.superview)
    {
        CGSize scale = CGAffineTransformGetScale(self.superview.transform);
        CGAffineTransform t = CGAffineTransformMakeScale(scale.width, scale.height);
        [closeView setTransform:CGAffineTransformInvert(t)];
        [resizeView setTransform:CGAffineTransformInvert(t)];
        [rotateView setTransform:CGAffineTransformInvert(t)];
        
        if (_isShowingEditingHandles)   [_contentView.layer setBorderWidth:1/scale.width];
        else                            [_contentView.layer setBorderWidth:0.0];
    }
}

-(void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self refresh];
}

- (void)setFrame:(CGRect)newFrame
{
    [super setFrame:newFrame];
    [self refresh];
}

- (id)initWithFrame:(CGRect)frame
{
    /*(1+_globalInset*2)*/
    if (frame.size.width < (1+12*2))     frame.size.width = 25;
    if (frame.size.height < (1+12*2))   frame.size.height = 25;
 
    self = [super initWithFrame:frame];
    if (self)
    {
        _globalInset = 12;
        
        //        self = [[UIView alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
        self.backgroundColor = [UIColor clearColor];
        
        //Close button view which is in top left corner
        closeView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, _globalInset*2, _globalInset*2)];
        [closeView setAutoresizingMask:(UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin)];
        closeView.backgroundColor = [UIColor clearColor];
        closeView.image = [UIImage imageNamed:@"close"];
        closeView.userInteractionEnabled = YES;
        [self addSubview:closeView];
        
         //Rotating view which is in bottom left corner
        rotateView = [[UIImageView alloc]initWithFrame:CGRectMake(self.bounds.size.width-_globalInset*2, self.bounds.size.height-_globalInset*2, _globalInset*2, _globalInset*2)];
        [rotateView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin)];
        rotateView.backgroundColor = [UIColor clearColor];
        rotateView.image = [UIImage imageNamed:@"rotate_scale"];
        rotateView.userInteractionEnabled = YES;
        [self addSubview:rotateView];
        
        //Resizing view which is in bottom right corner
        resizeView = [[UIImageView alloc]initWithFrame:CGRectMake(0, self.bounds.size.height-_globalInset*2, _globalInset*2, _globalInset*2)];
        [resizeView setAutoresizingMask:(UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin)];
        resizeView.backgroundColor = [UIColor clearColor];
        resizeView.userInteractionEnabled = YES;
        resizeView.image = [UIImage imageNamed:@"resize" ];
        [self addSubview:resizeView];
        
        UILongPressGestureRecognizer* moveGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moveGesture:)];
        [moveGesture setMinimumPressDuration:0.1];
        [self addGestureRecognizer:moveGesture];
        
        UITapGestureRecognizer * singleTapShowHide = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTapped:)];
        [self addGestureRecognizer:singleTapShowHide];
        
        UITapGestureRecognizer * singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [closeView addGestureRecognizer:singleTap];
        
        UILongPressGestureRecognizer* panResizeGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(resizeTranslate:)];
        [panResizeGesture setMinimumPressDuration:0];
        [resizeView addGestureRecognizer:panResizeGesture];
        
        UILongPressGestureRecognizer* panRotateGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(rotateViewPanGesture:)];
        [panRotateGesture setMinimumPressDuration:0];
        [rotateView addGestureRecognizer:panRotateGesture];
        
        [moveGesture requireGestureRecognizerToFail:singleTap];
        
        [self setEnableClose:YES];
        [self setEnableResize:YES];
        [self setEnableRotate:YES];
        [self setShowContentShadow:YES];
        
        [self hideEditingHandles];
     }
    return self;
}

-(void)contentTapped:(UITapGestureRecognizer*)tapGesture
{
    if (_isShowingEditingHandles)
    {
        [self hideEditingHandles];
        [self.superview bringSubviewToFront:self];
    }
    else
        [self showEditingHandles];
}

-(void)setEnableClose:(BOOL)enableClose
{
    _enableClose = enableClose;
    [closeView setHidden:!_enableClose];
    [closeView setUserInteractionEnabled:_enableClose];
}

-(void)setEnableResize:(BOOL)enableResize
{
    _enableResize = enableResize;
    [resizeView setHidden:!_enableResize];
    [resizeView setUserInteractionEnabled:_enableResize];
}

-(void)setEnableRotate:(BOOL)enableRotate
{
    _enableRotate = enableRotate;
    [rotateView setHidden:!_enableRotate];
    [rotateView setUserInteractionEnabled:_enableRotate];
}

-(void)setShowContentShadow:(BOOL)showContentShadow
{
    _showContentShadow = showContentShadow;
    
    if (_showContentShadow)
    {
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 5)];
        [self.layer setShadowOpacity:1.0];
        [self.layer setShadowRadius:4.0];
    }
    else
    {
        [self.layer setShadowColor:[UIColor clearColor].CGColor];
        [self.layer setShadowOffset:CGSizeZero];
        [self.layer setShadowOpacity:0.0];
        [self.layer setShadowRadius:0.0];
    }
}

- (void)hideEditingHandles
{
    lastTouchedView = nil;

    _isShowingEditingHandles = NO;

    if (_enableClose)       closeView.hidden = YES;
    if (_enableResize)      resizeView.hidden = YES;
    if (_enableRotate)      rotateView.hidden = YES;
    
    [self refresh];
    
    if([_delegate respondsToSelector:@selector(stickerViewDidHideEditingHandles:)])
        [_delegate stickerViewDidHideEditingHandles:self];
}

- (void)showEditingHandles
{
    [lastTouchedView hideEditingHandles];

    _isShowingEditingHandles = YES;
    
    lastTouchedView = self;
    
    if (_enableClose)       closeView.hidden = NO;
    if (_enableResize)      resizeView.hidden = NO;
    if (_enableRotate)      rotateView.hidden = NO;
    
    [self refresh];
    
    if([_delegate respondsToSelector:@selector(stickerViewDidShowEditingHandles:)])
        [_delegate stickerViewDidShowEditingHandles:self];
}

-(void)setContentView:(UIView *)contentView
{
    [_contentView removeFromSuperview];
    
    _contentView = contentView;
    
    _contentView.frame = CGRectInset(self.bounds, _globalInset, _globalInset);
    
    [_contentView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.layer.borderColor = [[UIColor brownColor]CGColor];
    _contentView.layer.borderWidth = 1.0f;
    [self insertSubview:_contentView atIndex:0];
}

-(void)singleTap:(UITapGestureRecognizer *)recognizer
{
    [self removeFromSuperview];
    
    if([_delegate respondsToSelector:@selector(stickerViewDidClose:)]) {
        [_delegate stickerViewDidClose:self];
    }
}

-(void)moveGesture:(UIPanGestureRecognizer *)recognizer
{
    touchLocation = [recognizer locationInView:self.superview];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
//        [lastTouchedView hideEditingHandles];
        beginningPoint = touchLocation;
        beginningCenter = self.center;
 
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];

        beginBounds = self.bounds;
        
//        [UIView animateWithDuration:0.1 animations:^{
//            [self setBounds:CGRectMake(0, 0, 100, 100)];
//        }];
        
        if([_delegate respondsToSelector:@selector(stickerViewDidBeginEditing:)])
            [_delegate stickerViewDidBeginEditing:self];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
        if([_delegate respondsToSelector:@selector(stickerViewDidChangeEditing:)])
            [_delegate stickerViewDidChangeEditing:self];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
//        [UIView animateWithDuration:0.1 animations:^{
//            [self setBounds:beginBounds];
//        }];
        
        if([_delegate respondsToSelector:@selector(stickerViewDidEndEditing:)])
            [_delegate stickerViewDidEndEditing:self];
    }

    prevPoint = touchLocation;
}

-(void)resizeTranslate:(UIPanGestureRecognizer *)recognizer
{
    touchLocation = [recognizer locationInView:self.superview];
    //Reforming touch location to it's Identity transform.
    touchLocation = CGPointRorate(touchLocation, CGRectGetCenter(self.frame), -CGAffineTransformGetAngle(self.transform));
 
    if ([recognizer state]== UIGestureRecognizerStateBegan)
    {
        if([_delegate respondsToSelector:@selector(stickerViewDidBeginEditing:)])
            [_delegate stickerViewDidBeginEditing:self];
    }
    else if ([recognizer state] == UIGestureRecognizerStateChanged)
    {
        CGFloat wChange = (prevPoint.x - touchLocation.x); //Slow down increment
        CGFloat hChange = (touchLocation.y - prevPoint.y); //Slow down increment
        
        CGAffineTransform t = self.transform;
        [self setTransform:CGAffineTransformIdentity];
        
        CGRect scaleRect = CGRectMake(self.frame.origin.x, self.frame.origin.y,MAX(self.frame.size.width + (wChange*2), 1+_globalInset*2), MAX(self.frame.size.height + (hChange*2), 1+_globalInset*2));
        
        scaleRect = CGRectSetCenter(scaleRect, self.center);
        [self setFrame:scaleRect];
        
        [self setTransform:t];
        
        if([_delegate respondsToSelector:@selector(stickerViewDidChangeEditing:)])
            [_delegate stickerViewDidChangeEditing:self];
    }
    else if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        if([_delegate respondsToSelector:@selector(stickerViewDidEndEditing:)])
            [_delegate stickerViewDidEndEditing:self];
    }
    
    prevPoint = touchLocation;
}

-(void)rotateViewPanGesture:(UIPanGestureRecognizer *)recognizer
{
    touchLocation = [recognizer locationInView:self.superview];
    
    CGPoint center = CGRectGetCenter(self.frame);
    
    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        deltaAngle = atan2(touchLocation.y-center.y, touchLocation.x-center.x)-CGAffineTransformGetAngle(self.transform);
        
        initialBounds = self.bounds;
        initialDistance = CGPointGetDistance(center, touchLocation);
       
        if([_delegate respondsToSelector:@selector(stickerViewDidBeginEditing:)])
            [_delegate stickerViewDidBeginEditing:self];
    }
    else if ([recognizer state] == UIGestureRecognizerStateChanged)
    {
        float ang = atan2(touchLocation.y-center.y, touchLocation.x-center.x);
        
        float angleDiff = deltaAngle - ang;
//        float angleDiff = -ang;
        [self setTransform:CGAffineTransformMakeRotation(-angleDiff)];
        [self setNeedsDisplay];
        
        //Finding scale between current touchPoint and previous touchPoint
        double scale = sqrtf(CGPointGetDistance(center, touchLocation)/initialDistance);
        
        CGRect scaleRect = CGRectScale(initialBounds, scale, scale);
 
        if (scaleRect.size.width >= (1+_globalInset*2) && scaleRect.size.height >= (1+_globalInset*2))
        {
            [self setBounds:scaleRect];
        }
        
        if([_delegate respondsToSelector:@selector(stickerViewDidChangeEditing:)])
            [_delegate stickerViewDidChangeEditing:self];
    }
    else if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        if([_delegate respondsToSelector:@selector(stickerViewDidEndEditing:)])
            [_delegate stickerViewDidEndEditing:self];
    }
}




@end
