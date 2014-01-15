//
//  FaceDetectionViewController.m
//  StudentsCheckIn
//
//  Created by Mars Broshok on 04/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import "FaceDetectionViewController.h"
#import <AssertMacros.h>
#import "OpenCVData.h"
#import "opencv2/highgui/ios.h"
#import "CustomFaceRecognizer.h"


#define CAPTURE_FPS 30

//static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

@interface FaceDetectionViewController ()
{
    
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureStillImageOutput *stillImageOutput;
    AVCaptureVideoDataOutput *videoDataOutput;
    AVCaptureSession *currentSession;
    
    dispatch_queue_t videoDataOutputQueue;
    
    CIDetector *faceDetector;
    
    BOOL isUsingFrontFacingCamera;
    
    NSMutableDictionary *recognisedFaces;
    NSMutableDictionary *processing;
    
    CustomFaceRecognizer *faceRecognizer;
    
    int frameNum;

}

@end

@implementation FaceDetectionViewController
// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewWillDisappear:(BOOL)animated {
    [self teardownAVCapture];
    videoDataOutputQueue = nil;
    faceDetector = nil;
    recognisedFaces = nil;
    processing = nil;
    faceRecognizer = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    
    [self setupAVCapture];
    
    NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorTracking : @(YES) };
    
	faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    faceRecognizer = [[CustomFaceRecognizer alloc] initWithEigenFaceRecognizer];
    
    self.modelAvailable = [faceRecognizer trainModel];
    
    if (!self.modelAvailable) {
        self.labelText.text = @"Add people in the database first";
    }
    else
    {   self.labelText.text = @""; }
    
    recognisedFaces = @{}.mutableCopy;
    processing = @{}.mutableCopy;

}

- (void)viewDidLoad
{
    //[super viewDidLoad];
	// Do any additional setup after loading the view.
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self viewWillDisappear:NO];
    [self viewDidAppear:NO];
}


- (IBAction)switchCameraButtonPressed:(id)sender {
    AVCaptureDevicePosition desiredPosition;
	if (isUsingFrontFacingCamera)
		desiredPosition = AVCaptureDevicePositionBack;
	else
		desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[[previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
				[[previewLayer session] removeInput:oldInput];
			}
			[[previewLayer session] addInput:input];
			[[previewLayer session] commitConfiguration];
			break;
		}
	}
	isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

- (IBAction)startCameraButtonPressed:(UIButton *)sender {
    [self setupAVCapture];
    
    NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorTracking : @(YES) };
    
	faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    faceRecognizer = [[CustomFaceRecognizer alloc] initWithEigenFaceRecognizer];
    
    self.modelAvailable = [faceRecognizer trainModel];
    
    if (!self.modelAvailable) {
        self.labelText.text = @"Add people in the database first";
    }
    
    recognisedFaces = @{}.mutableCopy;
    processing = @{}.mutableCopy;
}

- (IBAction)stopCameraButtonPressed:(UIButton *)sender {
    [self teardownAVCapture];
}

- (IBAction)eraseAllButtonPressed:(UIButton *)sender {
    [faceRecognizer forgetAllDataForAllPersons];
}

#pragma mark - AV setup
- (void)setupAVCapture
{
	NSError *error = nil;
    currentSession = [[AVCaptureSession alloc] init];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	    [currentSession setSessionPreset:AVCaptureSessionPreset640x480];
	else
	    [currentSession setSessionPreset:AVCaptureSessionPresetPhoto];
	
    // Select a video device, make an input
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == AVCaptureDevicePositionFront) {
			device = d;
			break;
		}
	}
    
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	require( error == nil, bail );
	{
        isUsingFrontFacingCamera = YES;
        if ( [currentSession canAddInput:deviceInput] )
            [currentSession addInput:deviceInput];
        
        // Make a still image output
        stillImageOutput = [AVCaptureStillImageOutput new];
        
        if ( [currentSession canAddOutput:stillImageOutput] )
            [currentSession addOutput:stillImageOutput];
        
        // Make a video data output
        videoDataOutput = [AVCaptureVideoDataOutput new];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [videoDataOutput setVideoSettings:rgbOutputSettings];
        [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
        
        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        
        if ( [currentSession canAddOutput:videoDataOutput] )
            [currentSession addOutput:videoDataOutput];
        [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:currentSession];
        [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        CALayer *rootLayer = [self.faceView layer];//[previewView layer];
        [rootLayer setMasksToBounds:YES];
        [previewLayer setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:previewLayer];
        [currentSession startRunning];
        
        frameNum = 0;
    }
bail:
    {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                        message:[error localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:@"Dismiss"
                              otherButtonTitles:nil] show];
            
            [self teardownAVCapture];
        }
    }
}

// clean up capture setup
- (void)teardownAVCapture
{
    
    if([currentSession isRunning])[currentSession stopRunning];
    stillImageOutput = [currentSession.outputs objectAtIndex:0];
    videoDataOutput = [currentSession.outputs objectAtIndex:1];
    AVCaptureInput* input = [currentSession.inputs objectAtIndex:0];
    [currentSession removeOutput:stillImageOutput];
    [currentSession removeOutput:videoDataOutput];
    [currentSession removeInput:input];
    [previewLayer removeFromSuperlayer];
    previewLayer = nil;
    currentSession = nil;
    stillImageOutput = nil;
    videoDataOutput = nil;
    [self.faceView printSubviewsWithIndentation:0];
    [self.faceView deleteAllSubviewsWithLog];
    //[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
    //[previewLayer removeFromSuperlayer];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	// got an image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
	NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
    
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation];
	});
    
    if ([features count]) {
        NSLog(@"feature tracking id: %d", ((CIFaceFeature *)features[0]).trackingID);
        
        if (self.modelAvailable){
            for (CIFaceFeature *feature in features) {
                [self identifyFace:feature inImage:[self imageFromSampleBuffer:sampleBuffer]];
            }
        }
	}
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
    //if (!currentSession.running) return; //stupid solution in case if the video session is already stopped
    for (UIView *view in [self.faceView subviews]) {
        [view removeFromSuperview];
    }
    
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger featuresCount = [features count], currentFeature = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
	
	if ( featuresCount == 0 ) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [self.faceView frame].size; //[previewView frame].size;
	NSString *gravity = [previewLayer videoGravity];
	
	CGRect previewBox = [FaceDetectionViewController videoPreviewBoxForGravity:gravity
                                                                           frameSize:parentFrameSize
                                                                        apertureSize:clap.size];
	
	for ( CIFaceFeature *ff in features ) {
        NSLog(@"ff bounds: %@", NSStringFromCGRect(ff.bounds));
        NSLog(@"ff leftEyePosition: %@", NSStringFromCGPoint(ff.leftEyePosition));
        NSLog(@"ff rightEyePosition: %@", NSStringFromCGPoint(ff.rightEyePosition));
        NSLog(@"ff mouthPosition: %@", NSStringFromCGPoint(ff.mouthPosition));
        NSLog(@"ff tracking ID: %d", ff.trackingID );
        
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
        
        CGRect faceRect = ff.bounds;
        
        // flip preview width and height
        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;
        // scale coordinates so they fit in the preview box, which may be scaled
        CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
        CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
        faceRect.size.width *= widthScaleBy;
        faceRect.size.height *= heightScaleBy;
        faceRect.origin.x *= widthScaleBy;
        faceRect.origin.y *= heightScaleBy;
        
        if ( isUsingFrontFacingCamera )
            faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
        else
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
        
        NSString *name = recognisedFaces[[NSNumber numberWithInt:ff.trackingID]];
        
        if (([features count] > 1) && (ff.trackingID == 0)) {
            name = nil;
        }
        
        [self showFaceRect:faceRect withName:name];
        
		currentFeature++;
	}
	
	[CATransaction commit];
}

#pragma mark -
- (void)identifyFace:(CIFaceFeature *)feature inImage:(UIImage *)image
{
    if (!recognisedFaces[[NSNumber numberWithInt:feature.trackingID]]) {
        if (!processing[[NSNumber numberWithInt:feature.trackingID]]) {
            processing[[NSNumber numberWithInt:feature.trackingID]] = @"1";
            
            cv::Mat cvImage;
            UIImageToMat(image, cvImage, NO);
            
            [self parseFace:[OpenCVData CGRectToFace:feature.bounds]
                   forImage:cvImage
                      forId:feature.trackingID];
        }
    } else {
        NSLog(@"%d is %@", feature.trackingID, recognisedFaces[[NSNumber numberWithInt:feature.trackingID]]);
    }
}

- (void)parseFace:(const cv::Rect &)face forImage:(cv::Mat &)image forId:(int)trackingID
{
    NSDictionary *match = [faceRecognizer recognizeFace:face inImage:image];
    
    NSLog(@"match: %@", match);
    
    // Match found
    if ([match objectForKey:@"personID"] != [NSNumber numberWithInt:-1])
    {
        recognisedFaces[[NSNumber numberWithInt:trackingID]] = [match objectForKey:@"personName"];
        
    }
    
    [processing removeObjectForKey:[NSNumber numberWithInt:trackingID]];
}

//this comes from http://code.opencv.org/svn/gsoc2012/ios/trunk/HelloWorld_iOS/HelloWorld_iOS/VideoCameraController.m
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
	
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
												 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
	
    // Release the Quartz image
    CGImageRelease(quartzImage);
	
    return (image);
}

- (void)showFaceRect:(CGRect)rect withName:(NSString *)name
{
    UIView *view = [[UIView alloc] initWithFrame:rect];
    
    view.layer.borderWidth = 4.0f;
    
    view.layer.borderColor = (name) ? [UIColor greenColor].CGColor : [UIColor redColor].CGColor;
    
    if (name) {
        UILabel *nameLabel = [UILabel new];
        nameLabel.text = name;
        [nameLabel sizeToFit];
        nameLabel.textColor = [UIColor greenColor];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.center = CGPointMake(view.frame.size.width / 2, view.frame.size.height / 2);
        
        [view addSubview:nameLabel];
    }
    [self.faceView addSubview:view];
}
@end
