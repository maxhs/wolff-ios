//
//  ProgressHUD.m
//  Wolff
//
//  Thanks to Related Code for the HUD foundations
//

@interface ProgressHUD : UIView
//-------------------------------------------------------------------------------------------------------------------------------------------------

+ (ProgressHUD *)shared;

+ (void)dismiss;
+ (void)show:(NSString *)status;
+ (void)showSuccess:(NSString *)status;
+ (void)showError:(NSString *)status;

@property (atomic, strong) UIWindow *window;
@property (atomic, strong) UIToolbar *hud;
@property (atomic, strong) UIActivityIndicatorView *spinner;
@property (atomic, strong) UIImageView *image;
@property (atomic, strong) UILabel *label;

@end
