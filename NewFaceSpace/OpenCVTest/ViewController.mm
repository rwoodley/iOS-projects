//
//  ViewController.m
//  FaceSpace
//
//  Created by Woodley, Bob on 4/22/13.
//  Copyright (c) 2013 Woodley, Bob. All rights reserved.
//

#import "ViewController.h"
#import "SecondViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize segmentedControl;
@synthesize flashSegmentedControl;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // get orientation right:

    // see: http://stackoverflow.com/questions/9826920/uinavigationcontroller-force-rotate
    //set statusbar to the desired rotation position
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    //present/dismiss viewcontroller in order to activate rotating.
    UIViewController *mVC = [[UIViewController alloc] init];
    [self presentViewController:mVC animated:NO completion:NULL];
    [self dismissViewControllerAnimated:NO completion:NULL];
    
    self.videoCamera = [[MyCvVideoCamera alloc] initWithParentView:_imageView];
	self.videoCamera.defaultFPS = 15;
	//self.videoCamera.grayscaleMode = YES;
	self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
	self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
	self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.delegate = self;

    // This has to be done before video camera is started because then MyCvVideoCamera->layoutPreview defeats resize somehow.
    // adjust aspect ratio of UIImage so that there is no distortion of the image.
    // aspect ratio of UIImage * aspect ratio of the video should = 1.
    double newHeight = _imageView.frame.size.width * (352.0/288.0);
    _imageView.frame = CGRectMake(
                                  _imageView.frame.origin.x,
                                  _imageView.frame.origin.y, _imageView.frame.size.width, newHeight);
    NSLog(@"image h*w = %f,%f", _imageView.frame.size.height, _imageView.frame.size.width);

    cameraFrontFacing = true;
    [flashSegmentedControl setEnabled:NO forSegmentAtIndex:0];
    [flashSegmentedControl setEnabled:NO forSegmentAtIndex:1];
    [self startCamera];
	lbpCascade = [self loadCascade:@"lbpcascade_frontalface"];
	alt2Cascade = [self loadCascade:@"haarcascade_frontalface_alt2"];
	myCascade = [self loadCascade:@"constrained_frontalface"];

    _LBPImageView.image = [UIImage imageNamed:@"1.png"];
    _ALTImageView.image = [UIImage imageNamed:@"2.png"];
    _MYImageView.image = [UIImage imageNamed:@"3.png"];
    NSString *sound; NSURL *soundURL;
    sound = [[NSBundle mainBundle] pathForResource:@"Bottle" ofType:@"aiff"];
    soundURL = [NSURL fileURLWithPath:sound];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &_sound1);
    sound = [[NSBundle mainBundle] pathForResource:@"Bottle" ofType:@"aiff"];
    soundURL = [NSURL fileURLWithPath:sound];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &_sound2);
    sound = [[NSBundle mainBundle] pathForResource:@"Tink" ofType:@"aiff"];
    soundURL = [NSURL fileURLWithPath:sound];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundURL, &_sound3);
    _playedSound1 = false;
    _playedSound2 = false;
    _playedSound3 = false;

    self.navigationItem.rightBarButtonItem = nil;
}
- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

#ifdef __cplusplus
- (cv::CascadeClassifier*)loadCascade:(NSString*)filename;
{
	NSString *real_path = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
	cv::CascadeClassifier* mycascade = new cv::CascadeClassifier();
	
	if (real_path != nil && !mycascade->load([real_path UTF8String])) {
		NSLog(@"Unable to load cascade file %@.xml", filename);
	} else {
		NSLog(@"Loaded cascade file %@.xml", filename);
	}
	return mycascade;
}
- (void)manageTorch:(bool) turnOnTorch;
{
    if (turnOnTorch && torchIsOn) return;
    if (!turnOnTorch && !torchIsOn) return; // yes, i could use an XOR here.
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (turnOnTorch) {
            [device setTorchMode:AVCaptureTorchModeOn];
            torchIsOn = true;
            NSLog(@"Turning Torch on");
        }
        else {
            [device setTorchMode:AVCaptureTorchModeOff];
            torchIsOn = false;
            NSLog(@"Turning Torch off");
        }
        [device unlockForConfiguration];
    }

}
- (void)processImage:(cv::Mat&)image;
{
    NSTimeInterval timeInterval = [_cameraStartRequestTime timeIntervalSinceNow];
    if (fabs(timeInterval)*1000 < 2000) {   // a nice pause before we go straight back to submit screen.
        dispatch_async(dispatch_get_main_queue(), ^{
            _LBPImageView.image = [UIImage imageNamed:@"1.png"];
            _ALTImageView.image = [UIImage imageNamed:@"2.png"];
            _MYImageView.image = [UIImage imageNamed:@"3.png"];
        });

        //NSLog(@"TimeInterval =  %f", timeInterval);
        return;
    }
    cv::Mat cleanImage;         // won't be drawing boxes on this image.
    cleanImage = image.clone();
    
    int votes = 0;
    int nFaces = 0;
    nFaces = [self detectFace: image cleanImage:cleanImage withCascade: lbpCascade showIn:_LBPImageView defaultPng:@"1.png"];
    if (nFaces > 0) {
        votes++;
        if (!_playedSound1) {
            AudioServicesPlaySystemSound(_sound1);
            _playedSound1 = true;
        }
    }
    else
        _playedSound1 = false;
    
    nFaces = [self detectFace: image cleanImage:cleanImage withCascade: alt2Cascade showIn:_ALTImageView defaultPng:@"2.png"];
    if (nFaces > 0) {
        votes++;
        if (!_playedSound2) {
            AudioServicesPlaySystemSound(_sound2);
            _playedSound2 = true;
        }
    }
    else
        _playedSound2 = false;

    if (flashSegmentedControl.selectedSegmentIndex == 0 && votes == 2)
        [self manageTorch:true];

    if (flashSegmentedControl.selectedSegmentIndex == 1)
        [self manageTorch:false];
    
    nFaces = [self detectFace: image cleanImage:cleanImage withCascade: myCascade showIn:_MYImageView defaultPng:@"3.png"];

    if (nFaces > 0) {
        votes++;
        AudioServicesPlaySystemSound(_sound3);
    }
    if (votes > 2) {

        [self manageTorch:false];
        self.FinalFaceImage = self.TempFaceImage;
        self.FinalFaceImage_Histogram = self.TempFaceImage_Histogram;
        dispatch_async(dispatch_get_main_queue(), ^{
            /*
            SecondViewController *sVC =
            [self.storyboard instantiateViewControllerWithIdentifier:@"secondViewController"];
            [self.navigationController pushViewController:sVC animated:YES];
            */
            [self performSegueWithIdentifier:@"gotFaceSegue" sender:self];
        });
        
    }
    cleanImage.release();
}
-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation  {
    [self.videoCamera updateOrientation];
}
-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.videoCamera updateOrientation];
}
//- (void)processImage:(cv::Mat&)image;

- (int)detectFace:(cv::Mat&)image
       cleanImage:(cv::Mat&)cleanImage
      withCascade:(cv::CascadeClassifier *)cascade
           showIn:(UIImageView *)imageView
       defaultPng:(NSString *)defaultPng
{
    @autoreleasepool {
        float haar_scale = 1.15;
        int haar_minNeighbors = 3;
        int haar_flags = 0 | CV_HAAR_SCALE_IMAGE | CV_HAAR_DO_CANNY_PRUNING;
        int minSize = 60;
        cv::Size haar_minSize = cvSize(minSize, minSize);
        std::vector<cv::Rect> faces;

        //NSDate *start = [NSDate date];
        cascade->detectMultiScale(image, faces, haar_scale,
                                     haar_minNeighbors, haar_flags, haar_minSize );
        //NSTimeInterval timeInterval = [start timeIntervalSinceNow];
        if (faces.size() == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                imageView.image = [UIImage imageNamed:defaultPng];
            });
        }
        // draw faces
        for( int i = 0; i < faces.size(); i++ ) {
            
            cv::Rect* r = &faces[i];
            cv::rectangle(image,                // draw on 'dirty' image
                          cvPoint( r->x, r->y ),
                          cvPoint( r->x + r->width, r->y + r->height),
                          CV_RGB(0,0,255));
            
            if (i == 0) {
                bool avoidCrash = (
                                   0 <= r->x && 0 <= r->width &&
                                   r->x + r->width <= image.cols &&
                                   0 <= r->y && 0 <= r->height &&
                                   r->y + r->height <= image.rows);
                if (!avoidCrash) return 0;
                cv::Mat subImg = cleanImage(*r);    // grab face from clean image
                cv::Mat subImg_Grey;
                cv::Mat subImg_Histogram;
                cv::cvtColor(subImg, subImg_Grey, CV_RGB2GRAY);
                cv::equalizeHist(subImg_Grey, subImg_Histogram);

                IplImage temp = subImg_Grey;
                self.TempFaceImage = [self UIImageFromIplImage:&temp];
                IplImage temph = subImg_Histogram;
                self.TempFaceImage_Histogram = [self UIImageFromIplImage:&temph];
                subImg.release();
                subImg_Grey.release();
                subImg_Histogram.release();
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = self.TempFaceImage;
                });
            }
            
        }
        return faces.size();
    }
}

- (UIImage *)UIImageFromIplImage:(IplImage *)image {
	
	//CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}
#endif
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)segmentedControl:(id)sender {
}
- (IBAction)flashSegmentedControlValueChanged:(id)sender {
    if (flashSegmentedControl.selectedSegmentIndex == 0) {
        NSLog(@"Clicked 0.");
    }
    if (flashSegmentedControl.selectedSegmentIndex == 1) {
        NSLog(@"Clicked 1.");
    }
}

- (IBAction)sgmentedControlIndexChanged:(id)sender {
    if (segmentedControl.selectedSegmentIndex == 0) {
        if (!cameraFrontFacing) {
            [self.videoCamera switchCameras];
            [flashSegmentedControl setEnabled:NO forSegmentAtIndex:0];
            [flashSegmentedControl setEnabled:NO forSegmentAtIndex:1];
        }
        cameraFrontFacing = true;
    }
    if (segmentedControl.selectedSegmentIndex == 1) {
        if (cameraFrontFacing) {
            [self.videoCamera switchCameras];
            [flashSegmentedControl setEnabled:YES forSegmentAtIndex:0];
            [flashSegmentedControl setEnabled:YES forSegmentAtIndex:1];
            flashSegmentedControl.selectedSegmentIndex = 1;     // default to flash off.
            torchIsOn = false;
        }
        cameraFrontFacing = false;
    }
}


- (void)startCamera {
    _cameraStartRequestTime = [NSDate date];
    [self.videoCamera start];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [self.videoCamera stop];
    NSLog(@"prepareForSegue: %@", segue.identifier);
    SecondViewController *sv = [segue destinationViewController];
    sv.FaceImage = self.FinalFaceImage;
    sv.FaceImage_Histogram = self.FinalFaceImage_Histogram;
}
- (IBAction) unwindToMain:(UIStoryboardSegue *) sender {
    NSLog(@"Unwind seque called");
    [self.videoCamera start];
}


@end