//
//  SlideshowPhoto+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/5/15.
//  Copyright © 2015 Wolff. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "SlideshowPhoto+helper.h"
#import "Photo+helper.h"
#import "Slideshow+helper.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation SlideshowPhoto (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    //NSLog(@"slideshow photo helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"created_unix"] && [dictionary objectForKey:@"created_unix"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_unix"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"photo"] && [dictionary objectForKey:@"photo"] != [NSNull null]){
        NSDictionary *dict = [dictionary objectForKey:@"photo"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!photo){
            photo = [Photo MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [photo populateFromDictionary:dict];
        self.photo = photo;
    }
    if ([dictionary objectForKey:@"slideshow_id"] && [dictionary objectForKey:@"slideshow_id"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"slideshow_id"]];
        Slideshow *slideshow = [Slideshow MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!slideshow){
            slideshow = [Slideshow MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            slideshow.identifier = [dictionary objectForKey:@"slideshow_id"];
        }
        self.slideshow = slideshow;
    }
}

@end
