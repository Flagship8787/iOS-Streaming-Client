//
//  CaptureViewController.h
//  OccupyStreamer
//
//  Created by Sam Shapiro on 11/26/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "RecordingManagerDelegate.h"

@class RecordingManager;
@class UploadManager;

@interface CaptureViewController : UIViewController <RecordingManagerDelegate> {
    UIButton *recordButt;
    AVCaptureSession *captureSession;
    
    RecordingManager *recordingManager;
    UploadManager *uploadManager;
}

@property (nonatomic, retain, readonly) IBOutlet UIButton *recordButt;

@property (nonatomic, retain, readonly) AVCaptureSession *captureSession;

@property (nonatomic, retain, readonly) RecordingManager *recordingManager;
@property (nonatomic, retain, readonly) UploadManager *uploadManager;

- (void)initializeCaptureSession;

- (void)startRecording;
- (void)stopRecording;

@end
