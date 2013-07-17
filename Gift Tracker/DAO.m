//
//  DAO.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "DAO.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Source.h"
#import "Utility.h"
#import "giftAppDelegate.h"


@interface DAO()
-(Source *)processResult:(FMResultSet *)results;
-(void) sortSources:(NSMutableArray *)sources;
-(void) doubleCheckLimit:(NSMutableArray *) sources;
@end

@implementation DAO

const double LIMIT = 440.0;
const double LOBBY_LIMIT = 10.0;


-(id)init {
    self = [super init];
    giftAppDelegate * appDelegate = (giftAppDelegate *)[[UIApplication sharedApplication] delegate];
    //setup the db
    self.db = [FMDatabase databaseWithPath:[Utility getDatabasePath:appDelegate.databaseName]];
    [self.db open];
    return self;
}

-(void)dealloc {
    // Yes, even in ARC we can do dealloc, this is solely just to close the db.
    // no releasing needed (it's automatic)
    // no super call needed (automatic too). In fact if you call super here, compiler will stop you
    
    [self.db close];
}

-(void)sortSources:(NSMutableArray *)sources {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"limitLeft" ascending:YES];
    [sources sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    sortDescriptor = nil;
}

- (NSMutableArray *)getAllSources {
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    //query
    NSString * query = @"SELECT * FROM source;";
    //run
    FMResultSet *results = [self.db executeQuery:query];
    while ([results next]) {
        [sources addObject:[self processResult:results]];
    }
    [self sortSources:sources];
    return sources;
}

- (void) doubleCheckLimit:(NSMutableArray *)sources {
    for(Source *s in sources) {
        s.limitLeft = [self limitLeft:s];
    }
}

- (Source *) processResult:(FMResultSet * )results {
    Source *s = [[Source alloc] init];
    s.idno = [results intForColumn:@"sid"];
    //convention over configuration, @property name should be the same as column name, except the id (which is a reserved word)
    s.name = [results stringForColumn:@"name"];
    s.addr1 = [results stringForColumn:@"addr1"];
    s.addr2 = [results stringForColumn:@"addr2"];
    s.city = [results stringForColumn:@"city"];
    s.state = [results stringForColumn:@"state"];
    s.zip= [results stringForColumn:@"zip"];
    s.business = [results stringForColumn:@"business"];
    s.lobby = ([results intForColumn:@"lobby"] != 0);
    s.email = [results stringForColumn:@"email"];
    s.phone = [results stringForColumn:@"phone"];
    s.limitLeft = [self limitLeft:s];
    return s;
}

-(NSMutableArray *)filterSources:(NSString *)searchString {
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    if ((searchString == nil) || ([searchString length] == 0)){
        return [self getAllSources];
    }
    //query
    NSString * query = @"SELECT s.* FROM source s JOIN source_index i ON i.docid = s.sid WHERE i.content match ?";
    FMResultSet *results = [self.db executeQuery:query withArgumentsInArray:[NSArray arrayWithObject:[searchString stringByAppendingString:@"*"]]];
    while ([results next]) {
        [sources addObject:[self processResult:results]];
    }
    [self sortSources:sources];
    return sources;
}

-(double)limitLeft:(Source *)source {
    double output = (source.lobby)?LOBBY_LIMIT:LIMIT;
    NSString * query = @"SELECT SUM(value) FROM giving WHERE sid = ?";
    
    FMResultSet *result = [self.db executeQuery:query withArgumentsInArray:[NSArray arrayWithObject:[NSNumber numberWithInteger:source.idno]]];
    
    if ([result next]) {
        output -= [result doubleForColumnIndex:0];
    }
    return output;
}

- (BOOL) insertSource:(Source *)s {
    NSString * query = @"INSERT INTO source (name,addr1,addr2,city,state,zip,business,lobby,email,phone) values (?,?,?,?,?,?,?,?,?,?)";
    BOOL success = [self.db executeUpdate:query, s.name, s.addr1, s.addr2, s.city, s.state, s.zip,
                    s.business, [NSNumber numberWithBool:s.lobby], s.email, s.phone];
    if (success) {
        NSString * content = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", s.name, s.addr1, s.addr2,
                              s.city, s.state, s.zip, s.business, s.lobby?@"lobbyist":@"", s.email, s.phone];
        NSString * index_query = @"INSERT INTO source_index (docid,content) values (?, ?)";
        
        // WARNING: THIS IS INTENDED FOR SINGLE THREADED APP ONLY, NOT THREAD-SAFE
        NSNumber * idno = [NSNumber numberWithInteger:[self.db lastInsertRowId]];
        BOOL index_success = [self.db executeUpdate:index_query, idno, content];
        success = success && index_success;
    }
    return success;
}

-(BOOL) updateSource:(Source *)old newSource:(Source *)newSource {
    
    // Why getting idno directly work?
    // SourceDetailVC (view controller) get info from the sources arrays in SourceVC
    // SourceVC get its array from getAllSources and filterSource in DAO class
    // getAllSource and filterSource build their object with processResult, which give the object its database sid
    // under the property idno;
    // therefore the old Source know its own database id.
    
    NSInteger sid = old.idno;
    
    NSString * query = @"UPDATE source SET name=?, addr1=?, addr2=?, city=?, state=?, zip=?, business=?, lobby=?, email=?, phone=? \
            WHERE sid = ?";
    
    BOOL success = [self.db executeUpdate:query, newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state, newSource.zip,
                    newSource.business, [NSNumber numberWithBool:newSource.lobby], newSource.email, newSource.phone, [NSNumber numberWithInteger:sid]];
    
    if (success) {
        query = @"UPDATE source_index SET content = ? WHERE docid = ?";
        NSString * content = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state,
                              newSource.zip, newSource.business, newSource.lobby?@"lobbyist":@"", newSource.email, newSource.phone];
        
        BOOL index_success = [self.db executeUpdate:query, content, [NSNumber numberWithInteger:sid]];
        success = success && index_success;
    }
    return success;
}

@end