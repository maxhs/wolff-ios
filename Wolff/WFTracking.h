//
//  WFTracking.h
//  Wolff
//
//  Created by Max Haines-Stiles on 7/24/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User+helper.h"
#import "Art+helper.h"
#import "Photo+helper.h"
#import "Artist+helper.h"
#import "Icon+helper.h"
#import "Tag+helper.h"
#import "Slide+helper.h"
#import "Slideshow+helper.h"
#import "Partner+helper.h"
#import "Material+helper.h"
#import "LightTable+helper.h"

@interface WFTracking : NSObject

+(void)aliasForCurrentUser:(NSNumber*)identifier;
+(void)registerSuperProperties:(NSDictionary*)superProperties;
+(void)setPeopleProperty:(NSString *)property to:(id)value;
+(void)trackScreen:(NSString*)screenPath;
+(void)identifyUserWithDeviceToken:(NSData*)deviceToken;
+(void)trackPushNotification:(NSDictionary*)pushPayload;
+(void)trackEvent:(NSString*)event withProperties:(NSMutableDictionary*)properties;
+(void)trackCharge:(NSNumber*)charge withProperties:(NSDictionary*)properties;
+(NSMutableDictionary*)generateTrackingPropertiesForSlideshow:(Slideshow*)slideshow;
+(NSMutableDictionary*)generateTrackingPropertiesForSlide:(Slide*)slide;
+(NSMutableDictionary*)generateTrackingPropertiesForArt:(Art*)art;
+(NSMutableDictionary*)generateTrackingPropertiesForPhoto:(Photo*)photo;
+(NSMutableDictionary*)generateTrackingPropertiesForUser:(User*)user;
+(NSMutableDictionary*)generateTrackingPropertiesForArtist:(Artist*)artist;
+(NSMutableDictionary*)generateTrackingPropertiesForIcon:(Icon*)icon;
+(NSMutableDictionary*)generateTrackingPropertiesForTag:(Tag*)tag;
+(NSMutableDictionary*)generateTrackingPropertiesForMaterial:(Material*)material;
+(NSMutableDictionary*)generateTrackingPropertiesForPartner:(Partner*)partner;
+(NSMutableDictionary*)generateTrackingPropertiesForLightTable:(LightTable*)lightTable;
+(void)incrementCatalogCount;
+(void)incrementArtMetadataViewCount;

@end
