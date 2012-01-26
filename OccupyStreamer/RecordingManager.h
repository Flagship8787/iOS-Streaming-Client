//
//  RecordingManager.h
//  OccupyStreamer
//
//  Created by Sam Shapiro on 11/26/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#import "RecordingManagerDelegate.h"

@interface RecordingManager : NSObject <AVCaptureFileOutputRecordingDelegate> {

    id <RecordingManagerDelegate> delegate;
    
    AVCaptureMovieFileOutput *captureOutput;
    NSURL *capDirURL;
    
    BOOL recording;
    
    NSTimer *reelTimer;
    
    NSInteger reelTime;
    NSInteger reelCount;
}

@property (nonatomic, assign) id <RecordingManagerDelegate> delegate;

@property (nonatomic, retain, readonly) AVCaptureMovieFileOutput *captureOutput;
@property (nonatomic, retain, readonly) NSURL *capDirURL;

@property (nonatomic, assign, readonly) BOOL recording;

@property (nonatomic, retain, readonly) NSTimer *reelTimer;

@property (nonatomic, assign, readonly) NSInteger reelTime;
@property (nonatomic, assign, readonly) NSInteger reelCount;

+ (NSURL *)NewCaptureDirURL:(NSError **)anError;

- (id)initWithAVCaptureSession:(AVCaptureSession *)aSession;

- (BOOL)startRecording;
- (void)stopRecording;

- (void)uploadReelAtURL:(NSURL *)reelURL;

- (NSURLRequest *)postRequestForReelData:(NSData *)reelData withFilename:(NSString *)fileName;

@end
