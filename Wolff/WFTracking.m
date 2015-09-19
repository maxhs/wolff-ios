//
//  WFTracking.m
//  Wolff
//
//  Created by Max Haines-Stiles on 7/24/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFTracking.h"
#import <Mixpanel/Mixpanel.h>
#import <MagicalRecord/MagicalRecord.h>
#import "Constants.h"

@implementation WFTracking

+(void)aliasForCurrentUser:(NSNumber *)identifier {
    // Mixpanel
    Mixpanel* mixpanel = [Mixpanel sharedInstance];
    [mixpanel createAlias:[NSString stringWithFormat:@"%@",identifier] forDistinctID:mixpanel.distinctId];
    [mixpanel identify:mixpanel.distinctId];
    //NSLog(@"Mixpanel aliasing %@ for %@",identifier,mixpanel.distinctId);
}

+(void)registerSuperProperties:(NSDictionary *)superProperties {
    // Mixpanel
    Mixpanel* mixpanel = [Mixpanel sharedInstance];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [mixpanel identify:[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]];
    }
    [mixpanel registerSuperProperties:superProperties];
    //NSLog(@"Registering the following mixpanel super properties: %@",superProperties);
}

+(void)setPeopleProperty:(NSString *)property to:(id)value {
    Mixpanel* mixpanel = [Mixpanel sharedInstance];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [mixpanel identify:[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]];
    }
    [mixpanel.people set:property to:value];
}

+(void)incrementArtMetadataViewCount {
    NSNumber *detailViewCount = [[NSUserDefaults standardUserDefaults] objectForKey:ART_METADATA_VIEW_COUNT];
    [[NSUserDefaults standardUserDefaults] setObject:@(detailViewCount.intValue+1) forKey:ART_METADATA_VIEW_COUNT];
    [self registerSuperProperties:@{ART_METADATA_VIEW_COUNT:@(detailViewCount.intValue+1)}];
    //NSLog(@"Detail view count: %@",[[NSUserDefaults standardUserDefaults] objectForKey:ART_METADATA_VIEW_COUNT]);
}

+(void)incrementCatalogCount {
    NSNumber *feedViewCount = [[NSUserDefaults standardUserDefaults] objectForKey:CATALOG_VIEW_COUNT];
    [[NSUserDefaults standardUserDefaults] setObject:@(feedViewCount.intValue+1) forKey:CATALOG_VIEW_COUNT];
    [self registerSuperProperties:@{CATALOG_VIEW_COUNT:@(feedViewCount.intValue+1)}];
    //NSLog(@"Feed view count: %@",[[NSUserDefaults standardUserDefaults] objectForKey:CATALOG_VIEW_COUNT]);
}

+(void)trackScreen:(NSString *)screenPath {
    // Mixpanel
    Mixpanel* mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:screenPath properties:nil];
}

+(void)identifyUserWithDeviceToken:(NSData *)deviceToken {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        return;
    }
    [mixpanel identify:[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]];
    [mixpanel.people addPushDeviceToken:deviceToken];
}

+(void)trackEvent:(NSString *)event withProperties:(NSMutableDictionary *)properties {
    Mixpanel* mixpanel = [Mixpanel sharedInstance];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [mixpanel identify:[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]];
    }
    [mixpanel track:event properties:properties];
}

+(void)trackCharge:(NSNumber *)charge withProperties:(NSDictionary *)properties {
    Mixpanel* mixpanel = [Mixpanel sharedInstance];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [mixpanel identify:[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]];
    }
    [mixpanel.people trackCharge:charge withProperties:properties];
}


+(NSMutableDictionary*)generateTrackingPropertiesForSlideshow:(Slideshow *)s {
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    Slideshow *slideshow = [s MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (slideshow){
        [trackingProperties setObject:slideshow.identifier forKey:@"SLIDESHOW ID"];
        [trackingProperties setObject:@(slideshow.photos.count) forKey:@"PHOTO COUNT"];
        if (slideshow.title.length){
            [trackingProperties setObject:slideshow.title forKey:@"TITLE"];
        }
        
        __block NSInteger slideTextsCount = 0; __block NSInteger slidePhotosCount = 0;
        [slideshow.slides enumerateObjectsUsingBlock:^(Slide *slide, NSUInteger idx, BOOL * stop) {
            if (slide.photoSlides.count){
                slidePhotosCount += slide.photoSlides.count;
            }
            if (slide.slideTexts.count){
                slidePhotosCount += slide.slideTexts.count;
            }
        }];
        if (slideTextsCount > 0){
            [trackingProperties setObject:@(slideTextsCount) forKey:@"SLIDE TEXTS COUNT"];
        }
        if (slidePhotosCount > 0){
            [trackingProperties setObject:@(slidePhotosCount) forKey:@"SLIDE PHOTOS COUNT"];
        }
        
    } else {
        return nil;
    }
    
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForSlide:(Slide *)s {
    Slide *slide = [s MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    if (slide){
        [trackingProperties setObject:slide.identifier forKey:@"SLIDE ID"];

    } else {
        return nil;
    }
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForArt:(Art *)a {
    Art *art = [a MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!art) return nil;
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    if (art.identifier)[trackingProperties setObject:art.identifier forKey:@"ART ID"];
    if (art.title.length)[trackingProperties setObject:art.title forKey:@"ART TITLE"];
    
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForArtist:(Artist *)a {
    Artist *artist = [a MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!artist) return nil;
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    [trackingProperties setObject:artist.identifier forKey:@"ARTIST ID"];
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForTag:(Tag *)t {
    Tag *tag = [t MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!tag) return nil;
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    [trackingProperties setObject:tag.identifier forKey:@"TAG ID"];
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForMaterial:(Material *)m {
    Material *material = [m MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!material) return nil;
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    [trackingProperties setObject:material.identifier forKey:@"MATERIAL ID"];
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForLightTable:(LightTable *)l {
    LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!lightTable) return nil;
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    [trackingProperties setObject:lightTable.identifier forKey:@"LIGHT TABLE ID"];
    [trackingProperties setObject:@(lightTable.users.count) forKey:@"MEMBER COUNT"];
    [trackingProperties setObject:@(lightTable.photos.count) forKey:@"PHOTO COUNT"];
    [trackingProperties setObject:@(lightTable.owners.count) forKey:@"OWNER COUNT"];
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForPartner:(Partner *)p {
    Partner *partner = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!partner) return nil;
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    [trackingProperties setObject:partner.identifier forKey:@"PARTNER ID"];
    [trackingProperties setObject:partner.identifier forKey:@"PARTNER NAME"];
    [trackingProperties setObject:@(partner.photos.count) forKey:@"PHOTO COUNT"];
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForPhoto:(Photo *)p {
    Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!photo) return nil;
    NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
    [trackingProperties setObject:photo.identifier forKey:@"PHOTO ID"];
    if (photo.art){
        [trackingProperties setObject:photo.art.title forKey:@"ART TITLE"];
    }
    return trackingProperties;
}

+(NSMutableDictionary*)generateTrackingPropertiesForUser:(User *)u {
    User *user = [u MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (user){
        NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
        [trackingProperties setObject:user.fullName forKey:@"FULL NAME"];
        [trackingProperties setObject:user.email forKey:@"EMAIL"];
        return trackingProperties;
    } else {
        return nil;
    }
    
}

+(NSMutableDictionary*)generateTrackingPropertiesForIcon:(Icon *)i {
    Icon *icon = [i MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (icon){
        NSMutableDictionary *trackingProperties = [NSMutableDictionary dictionary];
        [trackingProperties setObject:icon.identifier forKey:@"ICON ID"];
        [trackingProperties setObject:icon.name forKey:@"ICON NAME"];
        return trackingProperties;
    } else {
        return nil;
    }
}

+(void)trackPushNotification:(NSDictionary *)pushPayload {
    // Mixpanel
    Mixpanel* mixpanel = [Mixpanel sharedInstance];
    [mixpanel trackPushNotification:pushPayload];
}

@end
