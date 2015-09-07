//
//  Alternate+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/20/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "Alternate+helper.h"
#import "User+helper.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation Alternate (helper)

- (void)populateFromDictionary:(NSDictionary *)dictionary {
    //NSLog(@"Alternate helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]){
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"phone"] && [dictionary objectForKey:@"phone"] != [NSNull null]){
        self.phone = [dictionary objectForKey:@"phone"];
    }
    if ([dictionary objectForKey:@"confirmed"] && [dictionary objectForKey:@"confirmed"] != [NSNull null]){
        self.confirmed = [dictionary objectForKey:@"confirmed"];
    }
    if ([dictionary objectForKey:@"user_id"] && [dictionary objectForKey:@"user_id"] != [NSNull null]){
        User *user = [User MR_findFirstByAttribute:@"identifier" withValue:[dictionary objectForKey:@"user_id"]inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            user.identifier = [dictionary objectForKey:@"user_id"];
        }
        self.user = user;
    }
}
@end
