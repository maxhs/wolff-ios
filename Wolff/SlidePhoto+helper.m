//
//  SlidePhoto+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "SlidePhoto+helper.h"

@implementation SlidePhoto (helper)
- (void)populateFromDictionary:(NSDictionary *)dictionary {
    if ([dictionary objectForKey:@"id"] && [dictionary objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dictionary objectForKey:@"id"];
    }
    if ([dictionary objectForKey:@"scale"] && [dictionary objectForKey:@"scale"] != [NSNull null]){
        self.scale = [dictionary objectForKey:@"scale"];
    }
    if ([dictionary objectForKey:@"position_x"] && [dictionary objectForKey:@"position_x"] != [NSNull null]){
        self.positionX = [dictionary objectForKey:@"position_x"];
    }
    if ([dictionary objectForKey:@"position_y"] && [dictionary objectForKey:@"position_y"] != [NSNull null]){
        self.positionY = [dictionary objectForKey:@"position_y"];
    }
}
@end
