//
//  Presentation+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Presentation+helper.h"
#import "Slide+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Presentation (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary{
    //NSLog(@"Presentation helper: %@",dictionary);
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"title"] && [dictionary objectForKey:@"title"] != [NSNull null]){
        self.title = [dictionary objectForKey:@"title"];
    }
    if ([dictionary objectForKey:@"visible"] && [dictionary objectForKey:@"visible"] != [NSNull null]){
        self.visible = [dictionary objectForKey:@"visible"];
    }
    if ([dictionary objectForKey:@"description"] && [dictionary objectForKey:@"description"] != [NSNull null]){
        self.presentationDescription = [dictionary objectForKey:@"description"];
    }
    if ([dictionary objectForKey:@"slides"] && [dictionary objectForKey:@"slides"] != [NSNull null]){
        NSMutableOrderedSet *slides = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *artDict in [dictionary objectForKey:@"slides"]){
            Slide *slide = [Slide MR_findFirstByAttribute:@"identifier" withValue:[artDict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slide){
                slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slide populateFromDictionary:artDict];
            [slides addObject:slide];
        }
        /*for (Slide *slide in self.slides){
            if (![slides containsObject:slide]){
                NSLog(@"Removing a slide that no longer exist");
                [slide MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }*/
        self.slides = slides;
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
}

- (void)addArt:(Art *)art {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.arts];
    [tempSet addObject:art];
    self.arts = tempSet;
}

- (void)removeArt:(Art *)art {
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.arts];
    [tempSet removeObject:art];
    self.arts = tempSet;
}

- (void)addSlide:(Slide *)slide {
    NSMutableOrderedSet *slideSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slides];
    [slideSet addObject:slide];
    self.slides = slideSet;
}

- (void)removeSlide:(Slide *)slide {
    NSMutableOrderedSet *slideSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slides];
    [slideSet removeObject:slide];
    self.slides = slideSet;
}
@end
