//
//  Notification+helper.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "Notification.h"

@interface Notification (helper)
- (void)populateFromDictionary:(NSDictionary*)dict;
@end
