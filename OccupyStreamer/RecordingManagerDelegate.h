//
//  RecordingManagerDelegate.h
//  OccupyStreamer
//
//  Created by Sam Shapiro on 12/1/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RecordingManager;

@protocol RecordingManagerDelegate <NSObject>
@required
- (void)RecordingManager:(RecordingManager *)aRecordingManager savedReelAtURL:(NSURL *)aReelURL;
@end
