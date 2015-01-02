//
//  Interval+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Interval+helper.h"
#import "Art+helper.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@implementation Interval (helper)
- (void)populateFromDictionary:(NSDictionary*)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"begin_range"] && [dictionary objectForKey:@"begin_range"] != [NSNull null]){
        self.beginRange = [dictionary objectForKey:@"begin_range"];
    }
    if ([dictionary objectForKey:@"end_range"] && [dictionary objectForKey:@"end_range"] != [NSNull null]){
        self.endRange = [dictionary objectForKey:@"end_range"];
    }
    if ([dictionary objectForKey:@"circa"] && [dictionary objectForKey:@"circa"] != [NSNull null]){
        self.circa = [dictionary objectForKey:@"circa"];
    }
    if ([dictionary objectForKey:@"suffix"] && [dictionary objectForKey:@"suffix"] != [NSNull null]){
        self.suffix = [dictionary objectForKey:@"suffix"];
    }
    if ([dictionary objectForKey:@"year"] && [dictionary objectForKey:@"year"] != [NSNull null]){
        self.year = [dictionary objectForKey:@"year"];
    }
    if ([dictionary objectForKey:@"month"] && [dictionary objectForKey:@"month"] != [NSNull null]){
        self.month = [dictionary objectForKey:@"month"];
    }
    if ([dictionary objectForKey:@"day"] && [dictionary objectForKey:@"day"] != [NSNull null]){
        self.day = [dictionary objectForKey:@"day"];
    }
    if ([dictionary objectForKey:@"single"] && [dictionary objectForKey:@"single"] != [NSNull null]){
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        NSDate *date;
        NSError *error;
        if (![dateFormat getObjectValue:&date forString:[dictionary objectForKey:@"single"] range:nil error:&error]) {
            NSLog(@"Date '%@' could not be parsed: %@", [dictionary objectForKey:@"single"], error);
        }
        self.single = date;
    }
}
@end
