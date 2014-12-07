//
//  NSArray+ToSentence.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/25/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "NSArray+ToSentence.h"

@implementation NSArray (ToSentence)

- (NSString *)toSentence {
    if (self.count <= 2) return [self componentsJoinedByString:@" and "];
    NSArray *allButLastObject = [self subarrayWithRange:NSMakeRange(0, self.count-1)];
    NSString *result = [allButLastObject componentsJoinedByString:@", "];
    return [result stringByAppendingFormat:@", and %@", self.lastObject];
}

@end
