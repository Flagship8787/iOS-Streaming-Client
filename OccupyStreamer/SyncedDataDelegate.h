//
//  QBSyncDataDelegate.h
//  SigningView
//
//  Created by Sam Shapiro on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
	SyncedDataNeverSynced,
	SyncedDataSavedResponseData,
	SyncedDataStalledOnError,
	SyncedDataSyncedSuccessfully
}SyncedResourceState;

@protocol SyncedDataDelegate <NSObject>

@required
- (void)successSyncingResource:(id)syncData_ref;
- (void)failureSyncingResource:(id)syncData_ref withError:(NSError *)stallError;

@optional
- (void)SyncedData:(id)syncData_ref willSyncWithRequest:(NSURLRequest *)urlRequest_Ref;

- (void)SyncedDataWillValidateServerResponse:(id)syncData_ref;
- (void)SyncedDataDidValidateServerResponse:(id)syncData_ref;

- (void)SyncedDataWillSaveServerResponse:(id)syncData_ref;
- (void)SyncedDataDidSaveServerResponse:(id)syncData_ref;

- (void)SyncedDataWillParseServerResponse:(id)syncData_ref;
- (void)SyncedDataDidParseServerResponse:(id)syncData_ref;

@end
