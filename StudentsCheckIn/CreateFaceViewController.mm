//
//  CreateFaceViewController.m
//  StudentsCheckIn
//
//  Created by Mars Broshok on 04/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import "CreateFaceViewController.h"
#import "opencv2/highgui/ios.h"
#import "OpenCVData.h"


@interface CreateFaceViewController ()

@property (strong, nonatomic) NSString *pressedButtonLabel;
- (IBAction)saveButtonPressed:(UIButton *)sender;
- (IBAction)cancelButtonPressed:(UIButton *)sender;
- (IBAction)addFaceButtonPressed:(UIButton *)sender;
@property (strong, nonatomic) UIButton *pressedButton;
@property (strong, nonatomic) IBOutlet UIImageView *faceView;
@property (nonatomic) NSMutableArray *capturedImages;
@property (nonatomic) UIImagePickerController *facePicker;
@property (strong, nonatomic) IBOutlet UITextField *personName;

@end

@implementation CreateFaceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.capturedImages = [[NSMutableArray alloc] init];
    NSLog(@"Person id: %@", self.person);
    if (self.person != nil)
    {
        self.personName.text = [self.person objectForKey:@"name"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveButtonPressed:(UIButton *)sender {
    FaceDetector *faceDetector = [[FaceDetector alloc] init];
    CustomFaceRecognizer *faceRecognizer = [[CustomFaceRecognizer alloc]initWithEigenFaceRecognizer];
    //create new person and get its ID
    int id = [faceRecognizer newPersonWithName:self.personName.text];
    cv::Mat cvImage;
    for (UIImage *image in self.capturedImages)
    {
        
        UIImageToMat(image, cvImage, NO);
        cvImage = cvImage.t();
        
        const std::vector<cv::Rect> faces = [faceDetector facesFromImage:cvImage];
        if (faces.size()!=0)
        {
            cv::Rect face = faces.at(0); //we take first face in current image
            [faceRecognizer learnFace:face ofPersonID:id fromImage:cvImage];
        }
        
    }

    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addFaceButtonPressed:(UIButton *)sender {
    self.pressedButton = sender;
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeImage, nil];
    imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    imagePicker.delegate = self;
    self.facePicker = imagePicker;
    [self presentViewController:self.facePicker animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage * image = [info objectForKey:UIImagePickerControllerOriginalImage];
    //NSInteger i = [self.pressedButton.titleLabel.text integerValue];
    //UIImageView *imageUnderPressedButton = (UIImageView *)[self.view viewWithTag:i];
    //[self.pressedButton setBackgroundImage:image forState:UIControlStateNormal];
    [self.capturedImages addObject:image];
    //[self.pressedButton setContentMode:UIViewContentModeScaleAspectFit];
    [self.pressedButton setImage:image forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.facePicker = nil;
}
@end
