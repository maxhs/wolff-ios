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
    if ([dictionary objectForKey:@"begin_date_range"] && [dictionary objectForKey:@"begin_date_range"] != [NSNull null]){
        self.beginRange = [dictionary objectForKey:@"begin_date_range"];
    }
    if ([dictionary objectForKey:@"end_date_range"] && [dictionary objectForKey:@"end_date_range"] != [NSNull null]){
        self.endRange = [dictionary objectForKey:@"end_date_range"];
    }
    if ([dictionary objectForKey:@"exact"] && [dictionary objectForKey:@"exact"] != [NSNull null]){
        //self.exactDate = [dictionary objectForKey:@"exact"];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        NSDate *date;
        NSError *error;
        if (![dateFormat getObjectValue:&date forString:[dictionary objectForKey:@"exact"] range:nil error:&error]) {
            NSLog(@"Date '%@' could not be parsed: %@", [dictionary objectForKey:@"exact"], error);
        }
        self.exactDate = date;
    }
}
@end
