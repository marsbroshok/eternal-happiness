//
//  CreateFaceViewController.h
//  StudentsCheckIn
//
//  Created by Mars Broshok on 04/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceDetector.h"
#import "CustomFaceRecognizer.h"
#import <opencv2/highgui/cap_ios.h>

@interface CreateFaceViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong) NSDictionary *person;
@end
