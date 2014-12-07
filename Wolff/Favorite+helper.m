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
    if ([dict objectForKey:@"user"] && [dict objectForKey:@"user"] != [NSNull null]){
        if ([[dict objectForKey:@"user"] objectForKey:@"id"]){
            NSDictionary *userDict = [dict objectForKey:@"user"];
            User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[userDict objectForKey:@"id"]inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!user){
                user = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:userDict];
            self.user = user;
        }
    }
}

@end
