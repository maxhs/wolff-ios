//
//  ProgressHUD.m
//  Wolff
//
//  Thanks to Related Code for the HUD foundations
//

#import "ProgressHUD.h"

@implementation ProgressHUD

@synthesize window, hud, spinner, image, label;

+ (ProgressHUD *)shared
{
	static dispatch_once_t once = 0;
	static ProgressHUD *progressHUD;
	dispatch_once(&once, ^{ progressHUD = [[ProgressHUD alloc] init]; });
	return progressHUD;
}

+ (void)dismiss
{
	[[self shared] hudHide];
}

+ (void)show:(NSString *)status
{
	[[self shared] hudMake:status imgage:nil spin:YES hide:NO];
}

+ (void)showSuccess:(NSString *)status {
    [[self shared] hudMake:status imgage:[UIImage imageNamed:@"success"] spin:NO hide:YES];
}

+ (void)showError:(NSString *)status {
    [[self shared] hudMake:status imgage:nil spin:NO hide:YES];
}

- (id)init
{
	self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
	id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
	if ([delegate respondsToSelector:@selector(window)])
		window = [delegate performSelector:@selector(window)];
	else window = [[UIApplication sharedApplication] keyWindow];
	hud = nil; spinner = nil; image = nil; label = nil;
	self.alpha = 0;
	return self;
}

- (void)hudMake:(NSString *)status imgage:(UIImage *)img spin:(BOOL)spin hide:(BOOL)hide {
	[self hudCreate];
	label.text = status;
	label.hidden = (status == nil) ? YES : NO;

	image.image = img;
	image.hidden = (img == nil) ? YES : NO;

	if (spin) [spinner startAnimating]; else [spinner stopAnimating];
	[self hudOrient];
	[self hudSize];
	[self hudShow];
	if (hide) [NSThread detachNewThreadSelector:@selector(timedHide) toTarget:self withObject:nil];
}

- (void)hudCreate
{
    
	if (hud == nil)
	{
		hud = [[UIToolbar alloc] initWithFrame:CGRectZero];
        /*[hud setBackgroundImage:[UIImage new]
                      forToolbarPosition:UIBarPositionAny
                              barMetrics:UIBarMetricsDefault];*/
        [hud setShadowImage:[UIImage new]
                  forToolbarPosition:UIToolbarPositionAny];
        
        [hud setBarStyle:UIBarStyleDefault];
		hud.translucent = YES;
		hud.layer.cornerRadius = 7;
        //hud.layer.borderColor = kDarkerGrayColor.CGColor;
        //hud.layer.borderWidth = 1.f;
		hud.layer.masksToBounds = YES;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
	}
	if (hud.superview == nil) [window addSubview:hud];

	if (spinner == nil)
	{
		spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		spinner.color = [UIColor blackColor];
		spinner.hidesWhenStopped = YES;
	}
	if (spinner.superview == nil) [hud addSubview:spinner];
	if (image == nil)
	{
		image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
	}
	if (image.superview == nil) [hud addSubview:image];
	if (label == nil)
	{
		label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleSubheadline forFont:kMyriadLight] size:0];
        label.shadowColor = [UIColor clearColor];
		label.textColor = [UIColor blackColor];
		label.backgroundColor = [UIColor clearColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		label.numberOfLines = 0;
	}
	if (label.superview == nil) [hud addSubview:label];

}

- (void)hudDestroy {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[label removeFromSuperview];	label = nil;
	[image removeFromSuperview];	image = nil;
	[spinner removeFromSuperview];	spinner = nil;
	[hud removeFromSuperview];		hud = nil;
}

- (void)rotate:(NSNotification *)notification {
	[self hudOrient];
}

- (void)hudOrient {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        
    } else {
        CGFloat rotate;
        UIInterfaceOrientation orient;
        
        if (IDIOM == IPAD){
            orient = self.window.rootViewController.interfaceOrientation;
        } else {
            orient = [[UIApplication sharedApplication] statusBarOrientation];
        }
        if (orient == UIInterfaceOrientationPortrait)                   rotate = 0.0;
        else if (orient == UIInterfaceOrientationPortraitUpsideDown)	rotate = M_PI;
        else if (orient == UIInterfaceOrientationLandscapeLeft)         rotate = - M_PI_2;
        else if (orient == UIInterfaceOrientationLandscapeRight)		rotate = + M_PI_2;
        else rotate = 0.0;
        hud.transform = CGAffineTransformMakeRotation(rotate);
    }
}

- (void)hudSize
{
	CGRect labelRect = CGRectZero;
	CGFloat hudWidth = 140, hudHeight = 140;
	if (label.text != nil)
	{
		NSDictionary *attributes = @{NSFontAttributeName:label.font};
		NSInteger options = NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;
		labelRect = [label.text boundingRectWithSize:CGSizeMake(200, 300) options:options attributes:attributes context:NULL];

		labelRect.origin.x = 32;
		labelRect.origin.y = 86;

		hudWidth = labelRect.size.width + 64;
		hudHeight = labelRect.size.height + 120;

		if (hudWidth < 100)
		{
			hudWidth = 100;
			labelRect.origin.x = 0;
			labelRect.size.width = 100;
            labelRect.size.height += 40;
		}
	}
	CGSize screen = [UIScreen mainScreen].bounds.size;
	hud.center = CGPointMake(screen.width/2, screen.height/2);
	hud.bounds = CGRectMake(0, 0, hudWidth, hudHeight);
	CGFloat imagex = hudWidth/2;
	CGFloat imagey = (label.text == nil) ? hudHeight/2 : 56;
	image.center = spinner.center = CGPointMake(imagex, imagey);
	label.frame = labelRect;
}

- (void)hudShow
{
	if (self.alpha == 0)
	{
		self.alpha = 1;

		hud.alpha = 0;
		hud.transform = CGAffineTransformScale(hud.transform, 1.4, 1.4);

		NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut;

		[UIView animateWithDuration:0.15 delay:0 options:options animations:^{
			hud.transform = CGAffineTransformScale(hud.transform, 1/1.4, 1/1.4);
			hud.alpha = 1;
		}
		completion:^(BOOL finished){ }];
	}
}

- (void)hudHide
{
	if (self.alpha == 1)
	{
		NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn;

		[UIView animateWithDuration:0.15 delay:0 options:options animations:^{
			hud.transform = CGAffineTransformScale(hud.transform, 0.7, 0.7);
			hud.alpha = 0;
		}
		completion:^(BOOL finished)
		{
			[self hudDestroy];
			self.alpha = 0;
		}];
	}
}

- (void)timedHide {
	@autoreleasepool
	{
		double length = label.text.length;
		NSTimeInterval sleep = length * 0.04 + 0.5;
		
		[NSThread sleepForTimeInterval:sleep];
		[self hudHide];
	}
}

@end
