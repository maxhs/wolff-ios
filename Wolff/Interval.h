//
//  Interval.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art;

@interface Interval : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * beginRange;
@property (nonatomic, retain) NSNumber * endRange;
@property (nonatomic, retain) NSString * beginSuffix;
@property (nonatomic, retain) NSString * endSuffix;
@property (nonatomic, retain) NSNumber * circa;
@property (nonatomic, retain) NSDate * exactDate;
@property (nonatomic, retain) NSString * epochString;
@property (nonatomic, retain) Art *art;

@end
