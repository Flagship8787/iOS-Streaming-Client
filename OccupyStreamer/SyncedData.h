//
//  SyncedData.h
//  SigningView
//
//  Created by Sam Shapiro on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "SyncedDataDelegate.h"

@interface SyncedData : NSManagedObject {
    id <SyncedDataDelegate> delegate;
	
	NSMutableString *SyncResponseStr;
	
	NSString *FilePath;
	
	NSNumber *SyncState;
	NSDate *Synced;
}

@property (nonatomic, retain) id <SyncedDataDelegate> delegate;

@property (nonatomic, assign, readonly) NSMutableString *SyncResponseStr;

@property (nonatomic, retain) NSString *FilePath;

@property (nonatomic, retain) NSNumber *SyncState;
@property (nonatomic, retain) NSDate *Synced;

- (BOOL)SyncDataWithServer;
- (BOOL)SyncDataUsingRequest:(NSURLRequest *)urlRequest;

/******		Override-able functions for handling the transition of Sync state changes	***********/
- (void)handleServerResponse:(NSString *)qbResponseStr;

- (BOOL)handleValidationOfServerResponse:(NSString *)xmlResponseStr;
- (BOOL)handleSavingOfServerResponse:(NSString *)xmlResponseStr;
- (BOOL)handleParsingOfServerResponse:(NSString *)xmlResponseStr;

- (void)successSyncingQBData;
- (void)failureSyncingQBData:(NSError *)anError;

/******		Override-able functions for handling The actual Sync states	***********/
- (BOOL)validateServerResponse:(NSString *)xmlResponseStr;

- (BOOL)shouldSaveServerResponse:(NSString *)responseStr;
- (BOOL)saveServerResponseAsFile:(NSString *)xmlResponseStr;

- (BOOL)parseServerResponseString:(NSString *)xmlResponseStr;

@end
