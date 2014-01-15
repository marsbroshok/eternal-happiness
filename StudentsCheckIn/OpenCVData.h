//
//  OpenCVData.h
//  FaceRecognition
//
//  Created by Mars Broshok on 04/12/13.
//
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>

@interface OpenCVData : NSObject

+ (NSData *)serializeCvMat:(cv::Mat&)cvMat;
+ (cv::Mat)dataToMat:(NSData *)data width:(NSNumber *)width height:(NSNumber *)height;
+ (CGRect)faceToCGRect:(cv::Rect)face;
+ (cv::Rect)CGRectToFace:(CGRect)faceRect;
+ (UIImage *)UIImageFromMat:(cv::Mat)image;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image usingColorSpace:(int)outputSpace;
@end
