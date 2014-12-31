//
//  Comment+helper.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Comment+helper.h"

@implementation Comment (helper)
- (void)populateFromDictionary:(NSDictionary *)dict{
    if ([dict objectForKey:@"id"] && [dict objectForKey:@"id"] != [NSNull null]){
        self.identifier = [dict objectForKey:@"id"];
    }
    if ([dict objectForKey:@"body"] && [dict objectForKey:@"body"] != [NSNull null]){
        self.body = [dict objectForKey:@"body"];
    }
}
@end
