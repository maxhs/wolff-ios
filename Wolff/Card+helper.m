//
//  Card+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/20/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "Card+helper.h"
#import "User+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "WFUtilities.h"

@implementation Card (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"Alternate helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"created_at"] && [dictionary objectForKey:@"created_at"] != [NSNull null]) {
        self.createdDate = [WFUtilities parseDateTime:[dictionary objectForKey:@"created_at"]];
    }
    if ([dictionary objectForKey:@"brand"] && [dictionary objectForKey:@"brand"] != [NSNull null]){
        self.brand = [dictionary objectForKey:@"brand"];
    }
    if ([dictionary objectForKey:@"last4"] && [dictionary objectForKey:@"last4"] != [NSNull null]){
        self.last4 = [dictionary objectForKey:@"last4"];
    }
    if ([dictionary objectForKey:@"exp_month"] && [dictionary objectForKey:@"exp_month"] != [NSNull null]){
        self.expMonth = [dictionary objectForKey:@"exp_month"];
    }
    if ([dictionary objectForKey:@"exp_year"] && [dictionary objectForKey:@"exp_year"] != [NSNull null]){
        self.expYear = [dictionary objectForKey:@"exp_year"];
    }
    if ([dictionary objectForKey:@"user_id"] && [dictionary objectForKey:@"user_id"] != [NSNull null]){
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"user_id"]inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            user.identifier = [dictionary objectForKey:@"user_id"];
        }
        self.user = user;
    }
}
@end
