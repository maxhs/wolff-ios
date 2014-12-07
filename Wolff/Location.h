//
//  Location.h
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * street1;
@property (nonatomic, retain) NSString * street2;
@property (nonatomic, retain) NSNumber * inSitu;
@property (nonatomic, retain) NSNumber * original;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * state;
@property (nonatomic, retain) NSNumber * zip;
@property (nonatomic, retain) NSManagedObject *institution;
@property (nonatomic, retain) NSOrderedSet *arts;

@end
