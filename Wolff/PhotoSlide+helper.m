//
//  PhotoSlide+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "PhotoSlide+helper.h"
#import "Photo+helper.h"
#import "Slide+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation PhotoSlide (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"PhotoSlide helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"scale"] && [dictionary objectForKey:@"scale"] != [NSNull null]){
        self.scale = [dictionary objectForKey:@"scale"];
    }
    if ([dictionary objectForKey:@"position_x"] && [dictionary objectForKey:@"position_x"] != [NSNull null]){
        self.positionX = [dictionary objectForKey:@"position_x"];
    }
    if ([dictionary objectForKey:@"position_y"] && [dictionary objectForKey:@"position_y"] != [NSNull null]){
        self.positionY = [dictionary objectForKey:@"position_y"];
    }
    if ([dictionary objectForKey:@"width"] && [dictionary objectForKey:@"width"] != [NSNull null]){
        self.width = [dictionary objectForKey:@"width"];
    }
    if ([dictionary objectForKey:@"height"] && [dictionary objectForKey:@"height"] != [NSNull null]){
        self.height = [dictionary objectForKey:@"height"];
    }
    if ([dictionary objectForKey:@"index"] && [dictionary objectForKey:@"index"] != [NSNull null]){
        self.index = [dictionary objectForKey:@"index"];
    }
    if ([dictionary objectForKey:@"photo"] && [dictionary objectForKey:@"photo"] != [NSNull null]){
        NSDictionary *photoDict = [dictionary objectForKey:@"photo"];
        Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[photoDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!photo){
            photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [photo populateFromDictionary:photoDict];
        self.photo = photo;
    }
    if ([dictionary objectForKey:@"slide_id"] && [dictionary objectForKey:@"slide_id"] != [NSNull null]){
        Slide *slide = [Slide MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"slide_id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!slide){
            slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        slide.identifier = [dictionary objectForKey:@"slide_id"];
        self.slide = slide;
    }
}

- (BOOL)hasValidFrame {
    if ([self.width isEqualToNumber:@0] || [self.width isEqualToNumber:@0] || [self.width isEqual:[NSNull null]] || [self.height isEqual:[NSNull null]] || !self.width || !self.height){
        return NO;
    } else {
        return YES;
    }
}

- (void)resetFrame {
    self.positionX = nil;
    self.positionY = nil;
    self.width = nil;
    self.height = nil;
    self.scale = nil;
}
@end
