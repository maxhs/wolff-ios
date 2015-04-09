//
//  Favorite+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Favorite+helper.h"
#import "Art+helper.h"
#import "Photo+helper.h"
#import "User+helper.h"
#import "LightTable+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Favorite (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"created_epoch"] && [dictionary objectForKey:@"created_epoch"] != [NSNull null]) {
        NSTimeInterval _interval = [[dictionary objectForKey:@"created_epoch"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dictionary objectForKey:@"art_id"] && [dictionary objectForKey:@"art_id"] != [NSNull null]){
        Art *art = [Art MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"art_id"]inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!art){
            art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            art.identifier = [dictionary objectForKey:@"art_id"];
        }
        self.art = art;
    }
    if ([dictionary objectForKey:@"photo_id"] && [dictionary objectForKey:@"photo_id"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"photo_id"]];
        Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!photo){
            photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            photo.identifier = [dictionary objectForKey:@"photo_id"];
        }
        self.photo = photo;
    }
    if ([dictionary objectForKey:@"user_id"] && [dictionary objectForKey:@"user_id"] != [NSNull null]){
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"user_id"]inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            user.identifier = [dictionary objectForKey:@"user_id"];
        }
        self.user = user;
    }
    if ([dictionary objectForKey:@"light_table_id"] && [dictionary objectForKey:@"light_table_id"] != [NSNull null]){
        LightTable *table = [LightTable MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"light_table_id"]inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!table){
            table = [LightTable MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            table.identifier = [dictionary objectForKey:@"light_table_id"];
        }
        self.table = table;
    }
}

@end
