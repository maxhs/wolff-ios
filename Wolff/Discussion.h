//
//  Discussion.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, Artist, Group, Presentation;

@interface Discussion : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSManagedObject *comments;
@property (nonatomic, retain) Art *art;
@property (nonatomic, retain) Artist *artist;
@property (nonatomic, retain) Presentation *presentation;
@property (nonatomic, retain) Group *table;
@property (nonatomic, retain) NSOrderedSet *notifications;

@end
