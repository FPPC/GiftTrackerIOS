//
//  Gift.h
//  Gift Tracker
//
//  Created by Tam Do on 7/17/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Contribution;
@interface Gift : NSObject


@property (assign, nonatomic) NSUInteger idno;
@property (strong, nonatomic) NSString * description;
@property (strong, nonatomic) NSDate * date;
@property (strong, nonatomic) NSMutableArray * contributions;

-(Contribution *)findContributionFromSourceId:(NSUInteger)sid;

@end
