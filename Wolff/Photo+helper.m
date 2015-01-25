//
//  Photo+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Photo+helper.h"
#import "Art+helper.h"
#import "User+helper.h"
#import "Icon+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Photo (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary {
    //NSLog(@"Photo helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]){
        self.visible = [dictionary objectForKey:@"visible"];
    }
    if ([dictionary objectForKey:@"width"] && [dictionary objectForKey:@"width"] != [NSNull null]){
        self.width = [dictionary objectForKey:@"width"];
    }
    if ([dictionary objectForKey:@"height"] && [dictionary objectForKey:@"height"] != [NSNull null]){
        self.height = [dictionary objectForKey:@"height"];
    }
    if ([dictionary objectForKey:@"orientation"] && [dictionary objectForKey:@"orientation"] != [NSNull null]){
        self.orientation = [dictionary objectForKey:@"orientation"];
    }
    if ([dictionary objectForKey:@"created_epoch"] && [dictionary objectForKey:@"created_epoch"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_epoch"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"thumb_image_url"] && [dictionary objectForKey:@"thumb_image_url"] != [NSNull null]){
        self.thumbImageUrl = [dictionary objectForKey:@"thumb_image_url"];
    }
    if ([dictionary objectForKey:@"slide_image_url"] && [dictionary objectForKey:@"slide_image_url"] != [NSNull null]){
        self.slideImageUrl = [dictionary objectForKey:@"slide_image_url"];
    }
    if ([dictionary objectForKey:@"medium_image_url"] && [dictionary objectForKey:@"medium_image_url"] != [NSNull null]){
        self.mediumImageUrl = [dictionary objectForKey:@"medium_image_url"];
    }
    if ([dictionary objectForKey:@"large_image_url"] && [dictionary objectForKey:@"large_image_url"] != [NSNull null]){
        self.largeImageUrl = [dictionary objectForKey:@"large_image_url"];
    }
    if ([dictionary objectForKey:@"original_image_url"] && [dictionary objectForKey:@"original_image_url"] != [NSNull null]){
        self.originalImageUrl = [dictionary objectForKey:@"original_image_url"];
    }
    if ([dictionary objectForKey:@"credit"] && [dictionary objectForKey:@"credit"] != [NSNull null]){
        self.credit = [dictionary objectForKey:@"credit"];
    }
    if ([dictionary objectForKey:@"art_id"] && [dictionary objectForKey:@"art_id"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"art_id"]];
        Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!art){
            art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        art.identifier = [dictionary objectForKey:@"art_id"];
        self.art = art;
    } else if ([dictionary objectForKey:@"art"] && [dictionary objectForKey:@"art"] != [NSNull null]){
        NSDictionary *dict = [dictionary objectForKey:@"art"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!art){
            art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [art populateFromDictionary:dict];
        self.art = art;
    }
    if ([dictionary objectForKey:@"user_id"] && [dictionary objectForKey:@"user_id"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"user_id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        user.identifier = [dictionary objectForKey:@"user_id"];
        self.user = user;
    } else if ([dictionary objectForKey:@"user"] && [dictionary objectForKey:@"user"] != [NSNull null]){
        NSDictionary *dict = [dictionary objectForKey:@"user"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:dict];
        self.user = user;
    }
    if ([dictionary objectForKey:@"icons"] && [dictionary objectForKey:@"icons"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"icons"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Icon *icon = [Icon MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!icon){
                icon = [Icon MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [icon populateFromDictionary:dict];
            [set addObject:icon];
        }
        self.icons = set;
    }
}

- (BOOL)isLandscape {
    // 1 for landscape, 2 for portrait. landscape is default
    if ([self.orientation isEqualToNumber:@2]){
        return false;
    } else {
        return true;
    }
}
@end
