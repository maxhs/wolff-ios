//
//  Favorite+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Favorite+helper.h"
#import "Art+helper.h"
#import "User+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Favorite (helper)

- (void)populateFromDictionary:(NSDictionary*)dict {
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"created_epoch"] && [dict objectForKey:@"created_epoch"] != [NSNull null]) {
        NSTimeInterval _interval = [[dict objectForKey:@"created_epoch"] doubleValue];
        self.createdDate = [NSDate dateWithTimeIntervalSince1970:_interval];
    }
    if ([dict objectForKey:@"art"] && [dict objectForKey:@"art"] != [NSNull null]){
        if ([[dict objectForKey:@"art"] objectForKey:@"id"]){
            NSDictionary *artDict = [dict objectForKey:@"art"];
            Art *art = [Art MR_findFirstByAttribute:@"identifier" withValue:[artDict objectForKey:@"id"]inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!art){
                art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [art populateFromDictionary:artDict];
            self.art = art;
        }
    }
    if ([dict objectForKey:@"art_id"] && [dict objectForKey:@"art_id"] != [NSNull null]){
        Art *art = [Art MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"art_id"]inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!art){
            art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        art.identifier = [dict objectForKey:@"art_id"];
        self.art = art;
    }
    if ([dict objectForKey:@"user"] && [dict objectForKey:@"user"] != [NSNull null]){
        if ([[dict objectForKey:@"user"] objectForKey:@"id"]){
            NSDictionary *userDict = [dict objectForKey:@"user"];
            User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"]inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:userDict];
            self.user = user;
        }
    }
    if ([dict objectForKey:@"user_id"] && [dict objectForKey:@"user_id"] != [NSNull null]){
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"user_id"]inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        user.identifier = [dict objectForKey:@"user_id"];
        self.user = user;
    }
}

@end
