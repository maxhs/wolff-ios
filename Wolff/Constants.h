//
//  Constants.h
//  Wolff
//
//  Created by Max Haines-Stiles on 5/31/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIFontDescriptor+Custom.h"

#ifndef Wolff_Constants_h
#define Wolff_Constants_h

static inline int screenHeight(){ return [UIScreen mainScreen].bounds.size.height; }
static inline int screenWidth(){ return [UIScreen mainScreen].bounds.size.width; }
#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad
#define SYSTEM_VERSION     [[[UIDevice currentDevice] systemVersion] floatValue]

#define kSidebarWidth 280.f
#define kFastAnimationDuration .23f
#define kDefaultAnimationDuration .77f
#define kMediumAnimationDuration 1.4f
#define kSlowAnimationDuration 2.3f

#define kApiBaseUrl @"https://wolffapp.com/api/v1"
#define kBaseUrl @"https://wolffapp.com"
#define kTestFlightToken @"a37d3f4a-b21b-4f38-ac66-83c68b65a8a1"

#define MIXPANEL_TOKEN @"b091c81f24a93b828683bb5c3c260278"

#define kDarkBackgroundConstant 5298
#define kBlurredBackgroundConstant 5299
#define kMetadataWidth 600

#define kUserDefaultsId @"user_id"
#define kUserDefaultsPassword @"password"
#define kUserDefaultsEmail @"email"
#define kUserDefaultsAuthToken @"authToken"
#define kUserDefaultsFirstName @"firstName"
#define kUserDefaultsLastName @"lastName"
#define kUserDefaultsDeviceToken @"deviceToken"
#define kUserDefaultsAdmin @"admin"
#define kUserDefaultsMobileToken @"mobileToken"
#define kLogoutMessage @"You've been successfully logged out.\n\nSee you again real soon."

#define kMuseoSansThin @"MuseoSans-100"
#define kMuseoSansThinItalic @"MuseoSans-100Italic"
#define kMuseoSansLight @"MuseoSans-300"
#define kMuseoSansLightItalic @"MuseoSans-300Italic"
#define kMuseoSans @"MuseoSans-500"
#define kMuseoSansItalic @"MuseoSans-500Italic"
#define kMuseoSansSemibold @"MuseoSans-700"
#define kMuseoSansSemiboldItalic @"MuseoSans-700Italic"
#define kMuseoSansBold @"MuseoSans-900"
#define kMuseoSansBoldItalic @"MuseoSans-900Italic"
#define kLato @"Lato-Regular"
#define kLatoItalic @"Lato-Italic"
#define kLatoLight @"Lato-Light"
#define kLatoLightItalic @"Lato-LightItalic"
#define kLatoHairline @"Lato-Hairline"
#define kLatoHairlineItalic @"Lato-HairlineItalic"
#define kLatoBlack @"Lato-Black"
#define kLatoBlackItalic @"Lato-BlackItalic"
#define kLatoBold @"Lato-Bold"
#define kLatoBoldItalic @"Lato-BoldItalic"

#define kIncorrectPassword @"Incorrect password"
#define kNoEmail @"No email"
#define kInvalidToken @"Invalid token"
#define kUserAlreadyExists @"User already exists"
#define kNoUser @"No User"
#define kNoAccess @"No Access"
#define kNoArt @"No Art"
#define kNoPresentation @"No Presentation"
#define kIncorrectLightTableCode @"Incorrect light table code"
#define kNoLightTable @"No light table"
#define kNotAuthorized @"Not authorized"
#define kExistingUser @"ExistingUser"
#define kExistingLightTable @"Existing light table"
#define kUserUrlPlaceholder @"e.g. affiliation website, academia.edu, linkedin"
#define kSlideBackgroundColor [UIColor colorWithWhite:.95f alpha:1]
#define kSlideShadowColor [UIColor colorWithWhite:.4 alpha:1]
#define kSaffronColor [UIColor colorWithRed:244.f/255.f green:196.f/255.f blue:48.f/255.f alpha:1.f]
#define kPlaceholderTextColor [UIColor colorWithWhite:.67 alpha:1]
#define kRedBubbleColor [UIColor colorWithRed:226.f/255.f green:60.f/255.f blue:62.f/255.f alpha:1.f]
#define kElectricBlue [UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1]
#define kDarkTableViewCellSelectionColor [UIColor colorWithWhite:1 alpha:.23]
#define kTextFieldBackground [UIColor colorWithWhite:1 alpha:.83]

#endif
