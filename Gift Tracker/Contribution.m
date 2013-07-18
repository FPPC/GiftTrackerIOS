//
//  Contribution.m
//  Gift Tracker
//
//  Created by Tam Do on 7/18/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "Contribution.h"

@implementation Contribution

@synthesize value, sid;

-(id) initWithSid:(NSUInteger)sourceId value:(float)gValue {
    self = [super init];
    self.value = gValue;
    self.sid = sourceId;
    return self;
}

@end
