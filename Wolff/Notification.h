//
//  Notification.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Art, Artist, Discussion, Institution, User;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * notificationType;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * sent;
@property (nonatomic, retain) Art *art;
@property (nonatomic, retain) Institution *institution;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) Artist *artist;
@property (nonatomic, retain) Discussion *discussion;

@end
