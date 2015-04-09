//
//  Notification+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Notification+helper.h"
#import "Slide+helper.h"
#import "Slideshow+helper.h"
#import "Photo+helper.h"
#import "Art+helper.h"
#import "LightTable+helper.h"
#import "Discussion+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Notification (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary{
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"message"] && [dictionary objectForKey:@"message"] != [NSNull null]){
        self.message = [dictionary objectForKey:@"message"];
    }
    if ([dictionary objectForKey:@"notification_type"] && [dictionary objectForKey:@"notification_type"] != [NSNull null]){
        self.notificationType = [dictionary objectForKey:@"notification_type"];
    }
    if ([dictionary objectForKey:@"sent_at"] && [dictionary objectForKey:@"sent_at"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"sent_at"] doubleValue];
        self.sentAt = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"slideshow"] && [dictionary objectForKey:@"slideshow"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"slideshow"] objectForKey:@"id"]];
        Slideshow *slideshow = [Slideshow MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!slideshow){
            slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [slideshow populateFromDictionary:[dictionary objectForKey:@"slideshow"]];
        self.slideshow = slideshow;
    }
    if ([dictionary objectForKey:@"light_table"] && [dictionary objectForKey:@"light_table"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"light_table"] objectForKey:@"id"]];
        LightTable *lightTable = [LightTable MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!lightTable){
            lightTable = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [lightTable populateFromDictionary:[dictionary objectForKey:@"light_table"]];
        self.lightTable = lightTable;
    }
    if ([dictionary objectForKey:@"discussion"] && [dictionary objectForKey:@"discussion"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"discussion"] objectForKey:@"id"]];
        Discussion *discussion = [Discussion MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!discussion){
            discussion = [Discussion MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [discussion populateFromDictionary:[dictionary objectForKey:@"discussion"]];
        self.discussion = discussion;
    }
    if ([dictionary objectForKey:@"art"] && [dictionary objectForKey:@"art"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"art"] objectForKey:@"id"]];
        Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!art){
            art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [art populateFromDictionary:[dictionary objectForKey:@"art"]];
        self.art = art;
    }
    if ([dictionary objectForKey:@"photo"] && [dictionary objectForKey:@"photo"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"photo"] objectForKey:@"id"]];
        Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!photo){
            photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [photo populateFromDictionary:[dictionary objectForKey:@"photo"]];
        self.photo = photo;
    }
}
@end
