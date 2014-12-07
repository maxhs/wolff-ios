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
- (void)populateFromDictionary:(NSDictionary *)dict{
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"title"] && [dict objectForKey:@"title"] != [NSNull null]){
        self.title = [dict objectForKey:@"title"];
    }
    if ([dict objectForKey:@"description"] && [dict objectForKey:@"description"] != [NSNull null]){
        self.presentationDescription = [dict objectForKey:@"description"];
    }
    if ([dict objectForKey:@"slides"] && [dict objectForKey:@"slides"] != [NSNull null]){
        NSMutableOrderedSet *slides = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *artDict in [dict objectForKey:@"slides"]){
            Slide *slide = [Slide MR_findFirstByAttribute:@"identifier" withValue:[artDict objectForKey:@"id"]inContext:[NSManagedObjectContext MR_defaultContext]];
            if (!slide){
                slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            }
            [slide populateFromDictionary:artDict];
            [slides addObject:slide];
        }
        for (Slide *slide in self.slides){
            if (![slides containsObject:slide]){
                NSLog(@"Removing a slide that no longer exist");
                [slide MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        }
        self.slides = slides;
    }
}

- (void)addSlide:(Slide *)slide {
    NSMutableOrderedSet *slideSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slides];
    [slideSet addObject:slide];
    self.slides = slideSet;
}
@end
