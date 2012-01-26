//
//  UploadManager.h
//  OccupyStreamer
//
//  Created by Sam Shapiro on 12/1/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UploadManager : NSObject{
    BOOL uploading;
    
    NSURL *reelURL;
    NSMutableString *connResponse;
}

@property (nonatomic, assign, readonly) BOOL uploading;

@property (nonatomic, retain, readonly) NSURL *reelURL;
@property (nonatomic, retain, readonly) NSMutableString *connResponse;

- (id)initUploadManager;

- (BOOL)uploadReelToServer:(NSURL *)aReelURL;
- (NSURLRequest *)postRequestForReel;

- (void)finishedUploadingReel;

@end
