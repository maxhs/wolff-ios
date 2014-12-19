//
//  Constants.h
//  Wolff
//
//  Created by Max Haines-Stiles on 5/31/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIFontDescriptor+Lato.h"

#ifndef Wolff_Constants_h
#define Wolff_Constants_h

static inline int screenHeight(){ return [UIScreen mainScreen].bounds.size.height; }
static inline int screenWidth(){ return [UIScreen mainScreen].bounds.size.width; }
#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad

#define kMainSplitWidth 310.f
#define kPresentationSplitWidth 244.f
#define kDefaultAnimationDuration .77f

#define kApiBaseUrl @"http://wolffapp.com/api/v1"
#define kBaseUrl @"http://wolffapp.com"
#define kTestFlightToken @"a37d3f4a-b21b-4f38-ac66-83c68b65a8a1"

#define MIXPANEL_TOKEN @"b091c81f24a93b828683bb5c3c260278"

#define kDarkBackgroundConstant 5298
#define kBlurredBackgroundConstant 5299

#define kUserDefaultsId @"user_id"
#define kUserDefaultsPassword @"password"
#define kUserDefaultsEmail @"email"
#define kUserDefaultsAuthToken @"authToken"
#define kUserDefaultsFirstName @"firstName"
#define kUserDefaultsLastName @"lastName"
#define kUserDefaultsDeviceToken @"deviceToken"
#define kUserDefaultsAdmin @"admin"
#define kUserDefaultsMobileToken @"mobileToken"

#define kMuseoSansLight @"MuseoSans-100"
#define kMuseoSansLightItalic @"MuseoSans-100Italic"
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
#define kUserAlreadyExists @"User already exists"

#endif
