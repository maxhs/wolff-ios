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
#define kSlideResetAnimationDuration 1.1f
#define kMediumAnimationDuration 1.4f
#define kSlowAnimationDuration 2.3f

#if STAGING==1
#define MIXPANEL_TOKEN @"383bda487c05ab54bd15f4f9a1220913"
#define kApiBaseUrl @"https://staging.wolffapp.com/api/v1"
#define kBaseUrl @"https://staging.wolffapp.com/"
#define kStripePublishableKey @"pk_test_ZXELq5hTeexZnsrdWXpEbHeL"
#define API_LOGIN @"wolff_mobile"
#define API_KEY @"0fd11d82b574e0b13fc66b6227c4925c"
#else
#define MIXPANEL_TOKEN @"b091c81f24a93b828683bb5c3c260278"
#define kApiBaseUrl @"https://wolffapp.com/api/v1"
#define kBaseUrl @"https://wolffapp.com"
#define kStripePublishableKey @"pk_live_4sgQpIqXTKke1WwlPUSHAd6g"
#define API_LOGIN @"wolff_mobile"
#define API_KEY @"0fd11d82b574e0b13fc66b6227c4925c"
#endif

#define kDarkBackgroundConstant 5298
#define kBlurredBackgroundConstant 5299
#define kMetadataWidth 600
#define ART_THROTTLE 30

#define LOGGED_OUT @"LoggedOut"
#define LOGGED_IN @"LoggedIn"

#define kUserDefaultsId @"user_id"
#define kUserDefaultsPassword @"password"
#define kUserDefaultsEmail @"email"
#define kUserDefaultsAuthToken @"authToken"
#define kUserDefaultsFirstName @"firstName"
#define kUserDefaultsLastName @"lastName"
#define kUserDefaultsiPadToken @"iPadToken"
#define kUserDefaultsiPhoneToken @"iPhoneToken"
#define kUserDefaultsAdmin @"admin"
#define kUserDefaultsDeviceToken @"deviceToken"
#define kLogoutMessage @"You've been successfully logged out.\n\nSee you again real soon."

#define ART_METADATA_VIEW_COUNT @"Art metadata view count"
#define CATALOG_VIEW_COUNT @"Catalog view count"
#define SIGNUP_DATE @"Signup date"
#define LAUNCH_DATE @"Launch date"
#define kYes @"Yes"
#define kNo @"No"

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

#define kAddLocationPlaceholder @"+  add a new location"
#define kAddTagPlaceholder @"+  add a new tag"
#define kIncorrectPassword @"Incorrect password"
#define kNoEmail @"No email"
#define kInvalidToken @"Invalid token"
#define kUserAlreadyExists @"User already exists"
#define kNoUser @"No user"
#define kNoAccess @"No access"
#define kNoIcon @"No icon"
#define kNoMaterial @"No material"
#define kNoArt @"No art"
#define kNoPhoto @"No photo"
#define kNoSlideshow @"No slideshow"
#define kArtDeleted @"Art deleted"
#define kCopyright @"Copyright"
#define kIncorrectLightTableCode @"Incorrect light table code"
#define kNoLightTable @"No light table"
#define kLightTableDescriptionPlaceholder @"Describe your light table..."
#define kNotAuthorized @"Not authorized"
#define kExistingUser @"Existing user"
#define kExistingLightTable @"Existing light table"
#define kUserUrlPlaceholder @"e.g. affiliation website, academia.edu, linkedin"
#define kNoSearchResults @"No search results."
#define kSlideBackgroundColor [UIColor colorWithWhite:.95f alpha:1]
#define kSlideShadowColor [UIColor colorWithWhite:.4 alpha:1]
#define kSaffronColor [UIColor colorWithRed:244.f/255.f green:196.f/255.f blue:48.f/255.f alpha:1.f]
#define kPlaceholderTextColor [UIColor colorWithWhite:.67 alpha:1]
#define kRedBubbleColor [UIColor colorWithRed:226.f/255.f green:60.f/255.f blue:62.f/255.f alpha:1.f]
#define kElectricBlue [UIColor colorWithRed:(0.0/255.0) green:(128.0/255.0) blue:(255.0/255.0) alpha:1]
#define kDarkTableViewCellSelectionColor [UIColor colorWithWhite:1 alpha:.23]
#define kTextFieldBackground [UIColor colorWithWhite:1 alpha:.83]
#define kLightTablePlaceholderTextColor [UIColor colorWithWhite:0 alpha:.23]
#define kHeaderBackgroundColor [UIColor colorWithWhite:.97 alpha:1]

#endif
