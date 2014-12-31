//
//  Notification+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Notification+helper.h"

@implementation Notification (helper)
- (void)populateFromDictionary:(NSDictionary *)dict{
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"message"] && [dict objectForKey:@"message"] != [NSNull null]){
        self.message = [dict objectForKey:@"message"];
    }
}
@end
