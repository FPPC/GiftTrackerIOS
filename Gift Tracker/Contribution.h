//
//  Contribution.h
//  Gift Tracker
//
//  Created by Tam Do on 7/18/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contribution : NSObject

@property (assign, nonatomic) NSUInteger sid;
@property (assign, nonatomic) float value;

-(id)initWithSid:(NSUInteger)sid value:(float)value;

@end
