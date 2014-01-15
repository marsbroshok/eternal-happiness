//
//  FaceDetectionViewController.h
//  StudentsCheckIn
//
//  Created by Mars Broshok on 04/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIView+printSubviews.h"

@interface FaceDetectionViewController : UIViewController <UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) IBOutlet UIView *faceView;
@property (strong, nonatomic) IBOutlet UILabel *labelText;
@property (nonatomic) BOOL modelAvailable;
- (IBAction)switchCameraButtonPressed:(id)sender;
- (IBAction)startCameraButtonPressed:(UIButton *)sender;
- (IBAction)stopCameraButtonPressed:(UIButton *)sender;
- (IBAction)eraseAllButtonPressed:(UIButton *)sender;

@end
