//
//  Table+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Table+helper.h"
#import "Slideshow+helper.h"
#import "Art+helper.h"
#import "Discussion+helper.h"
#import "User+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Table (helper)

- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]){
        self.tableDescription = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"code"] && [dictionary objectForKey:@"code"] != [NSNull null]){
        self.code = [dictionary objectForKey:@"code"];
    }
    if ([dictionary objectForKey:@"name"] && [dictionary objectForKey:@"name"] != [NSNull null]){
        self.name = [dictionary objectForKey:@"name"];
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]){
        self.visible = [dictionary objectForKey:@"visible"];
    }
    if ([dictionary objectForKey:@"private"] && [dictionary objectForKey:@"private"] != [NSNull null]){
        self.privateTable = [dictionary objectForKey:@"private"];
    }
    if ([dictionary objectForKey:@"slideshows"] && [dictionary objectForKey:@"slideshows"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"slideshows"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Slideshow *slideshow = [Slideshow MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slideshow){
                slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slideshow populateFromDictionary:dict];
            [set addObject:slideshow];
        }
        self.slideshows = set;
    }
    if ([dictionary objectForKey:@"photos"] && [dictionary objectForKey:@"photos"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"photos"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!photo){
                photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [photo populateFromDictionary:dict];
            [set addObject:photo];
        }
        self.photos = set;
    }
    if ([dictionary objectForKey:@"users"] && [dictionary objectForKey:@"users"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"users"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!user){
                user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [user populateFromDictionary:dict];
            [set addObject:user];
        }
        self.users = set;
    }
    if ([dictionary objectForKey:@"owner_id"] && [dictionary objectForKey:@"owner_id"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dictionary objectForKey:@"owner_id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        user.identifier = [dictionary objectForKey:@"owner_id"];
        [self addOwner:user];
    }
    if ([dictionary objectForKey:@"owner"] && [dictionary objectForKey:@"owner"] != [NSNull null]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"owner"] objectForKey:@"id"]];
        User *user = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!user){
            user = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [user populateFromDictionary:[dictionary objectForKey:@"owner"]];
        [self addOwner:user];
    }
    
    if ([dictionary objectForKey:@"owners"] && [dictionary objectForKey:@"owners"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"owners"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            User *owner = [User MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!owner){
                owner = [User MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [owner populateFromDictionary:dict];
            [set addObject:owner];
        }
        self.owners = set;
    }
    if ([dictionary objectForKey:@"discussions"] && [dictionary objectForKey:@"discussions"] != [NSNull null]){
        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id dict in [dictionary objectForKey:@"discussions"]){
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
            Discussion *discussion = [Discussion MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!discussion){
                discussion = [Discussion MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [discussion populateFromDictionary:dict];
            [set addObject:discussion];
        }
        self.discussions = set;
    }
}

- (void)addPhoto:(Photo *)photo {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet addObject:photo];
    self.photos = tempSet;
}

- (void)removePhoto:(Photo *)photo {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet removeObject:photo];
    self.photos = tempSet;
}

- (void)addOwner:(User *)owner {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.owners];
    [tempSet addObject:owner];
    self.owners = tempSet;
}

- (void)removeOwner:(User *)owner {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.owners];
    [tempSet removeObject:owner];
    self.owners = tempSet;
}

- (void)addSlideshow:(Slideshow *)slideshow {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slideshows];
    [tempSet addObject:slideshow];
    self.slideshows = tempSet;
}

- (void)removeSlideshow:(Slideshow *)slideshow {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slideshows];
    [tempSet removeObject:slideshow];
    self.slideshows = tempSet;
}

- (void)addPhotos:(NSArray *)array {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet addObjectsFromArray:array];
    self.photos = tempSet;
}

- (void)removePhotos:(NSArray *)array {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.photos];
    [tempSet removeObjectsInArray:array];
    self.photos = tempSet;
}

- (void)addUser:(User *)user {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
    [tempSet addObject:user];
    self.users = tempSet;
}

- (void)removeUser:(User *)user {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.users];
    [tempSet removeObject:user];
    self.users = tempSet;
}

- (BOOL)includesOwnerId:(NSNumber *)ownerId {
    __block BOOL ownership = NO;
    [self.owners enumerateObjectsUsingBlock:^(User *owner, NSUInteger idx, BOOL *stop) {
        if ([owner.identifier isEqualToNumber:ownerId]){
            ownership = YES;
            *stop = YES;
        }
    }];
    return ownership;
}

@end
