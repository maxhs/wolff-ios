//
//  User+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "User+helper.h"
#import "Art+helper.h"
#import "Institution+helper.h"
#import "Presentation+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation User (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    //NSLog(@"user helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"mobile_token"] && [dictionary objectForKey:@"mobile_token"] != [NSNull null]){
        self.mobileToken = [dictionary objectForKey:@"mobile_token"];
    }
    if ([dictionary objectForKey:@"first_name"] && [dictionary objectForKey:@"first_name"] != [NSNull null]){
        self.firstName = [dictionary objectForKey:@"first_name"];
    }
    if ([dictionary objectForKey:@"last_name"] && [dictionary objectForKey:@"last_name"] != [NSNull null]){
        self.lastName = [dictionary objectForKey:@"last_name"];
    }
    if ([dictionary objectForKey:@"bio"] && [dictionary objectForKey:@"bio"] != [NSNull null]){
        self.bio = [dictionary objectForKey:@"bio"];
    }
    if ([dictionary objectForKey:@"email"] && [dictionary objectForKey:@"email"] != [NSNull null]){
        self.email = [dictionary objectForKey:@"email"];
    }
    if ([dictionary objectForKey:@"email_permission"] && [dictionary objectForKey:@"email_permission"] != [NSNull null]){
        self.emailPermission = [dictionary objectForKey:@"email_permission"];
    }
    if ([dictionary objectForKey:@"push_permission"] && [dictionary objectForKey:@"push_permission"] != [NSNull null]){
        self.pushPermission = [dictionary objectForKey:@"push_permission"];
    }
    if ([dictionary objectForKey:@"text_permission"] && [dictionary objectForKey:@"text_permission"] != [NSNull null]){
        self.textPermission = [dictionary objectForKey:@"text_permission"];
    }
    if ([dictionary objectForKey:@"avatar_small"] && [dictionary objectForKey:@"avatar_small"] != [NSNull null]) {
        self.avatarSmall = [dictionary objectForKey:@"avatar_small"];
    }
    if ([dictionary objectForKey:@"avatar_medium"] && [dictionary objectForKey:@"avatar_medium"] != [NSNull null]) {
        self.avatarMedium = [dictionary objectForKey:@"avatar_medium"];
    }
    if ([dictionary objectForKey:@"avatar_large"] && [dictionary objectForKey:@"avatar_large"] != [NSNull null]) {
        self.avatarLarge = [dictionary objectForKey:@"avatar_large"];
    }
    
    if ([dictionary objectForKey:@"arts"] && [dictionary objectForKey:@"arts"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"arts"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Art *art = [Art MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!art){
                art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [art populateFromDictionary:dict];
            [set addObject:art];
        }
        self.arts = set;
    }
    
    if ([dictionary objectForKey:@"presentations"] && [dictionary objectForKey:@"presentations"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"presentations"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Presentation *presentation = [Presentation MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!presentation){
                presentation = [Presentation MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [presentation populateFromDictionary:dict];
            [set addObject:presentation];
        }
        self.presentations = set;
    }
    
    if ([dictionary objectForKey:@"institution"] && [dictionary objectForKey:@"institution"] != [NSNull null]){
    
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"institution"] objectForKey:@"id"]];
        Institution *institution = [Institution MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!institution){
            institution = [Institution MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [institution populateFromDictionary:[dictionary objectForKey:@"institution"]];
        self.institution = institution;
    }
}

- (NSString*) fullName {
    if (self.firstName.length){
        if (self.lastName.length) {
            return [NSString stringWithFormat:@"%@ %@",self.firstName, self.lastName];
        } else {
            return self.firstName;
        }
    } else if (self.email.length) {
        return self.email;
    } else {
        return @"";
    }
}

@end
