//
//  FaceDetector.h
//  FaceRecognition
//
//  Created by Mars Broshok on 04/12/13.
//
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>

@interface FaceDetector : NSObject
{
    cv::CascadeClassifier _faceCascade;
}

- (std::vector<cv::Rect>)facesFromImage:(cv::Mat&)image;

@end
