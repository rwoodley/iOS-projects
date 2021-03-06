//
//  SecondViewController.m
//  FaceSpace
//
//  Created by Woodley, Bob on 4/25/13.
//  Copyright (c) 2013 Woodley, Bob. All rights reserved. test
//
#import "ViewController.h"
#import "SecondViewController.h"
#import "WebViewController.h"
@implementation SecondViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewWillDisappear:(BOOL)animated
{
    /*
    int currentVCIndex = [self.navigationController.viewControllers indexOfObject:self.navigationController.topViewController];
    ViewController *parent = (ViewController *)[self.navigationController.viewControllers objectAtIndex:currentVCIndex];
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        NSLog(@"SecondView controller was popped");
        [parent startCamera];
    }
     */
}
- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // see: http://stackoverflow.com/questions/9826920/uinavigationcontroller-force-rotate
    //set statusbar to the desired rotation position
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    //present/dismiss viewcontroller in order to activate rotating.
    UIViewController *mVC = [[UIViewController alloc] init];
    [self presentViewController:mVC animated:NO completion:NULL];
    [self dismissViewControllerAnimated:NO completion:NULL];
    
    // the face image is a square... resize the image view.
    double newHeight = _FaceImageView.frame.size.width;
    _FaceImageView.frame = CGRectMake(
                                  _FaceImageView.frame.origin.x,
                                  _FaceImageView.frame.origin.y, _FaceImageView.frame.size.width, newHeight);
    NSLog(@"image h*w = %f,%f", _FaceImageView.frame.size.height, _FaceImageView.frame.size.width);
    self.FaceImageView.image = self.FaceImage;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    // ----
//    [self readyToNavigateAwayFromTab];
    // ----
    
    NSLog(@"***prepareForSegue: %@", segue.identifier);
    WebViewController *webVC = [segue destinationViewController];
    //webVC.FaceImage = self.FaceImage_Histogram;
    webVC.FaceImage = self.FaceImage;
}
- (IBAction)ComputeAntiFaceButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Agree Terms"
                          message:@"By clicking 'I agree' you consent to upload this photo to Facefield.org which will use it for art projects such as this one. By submitting a photograph, you (and any other individual depicted in the photograph) consent to such usage. All uploads are anonymous - we only upload your image and do not collect other identifying information."
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"I agree", nil
                          ];
    [alert show];
}
#define CANCEL 0
#define OK 1
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if( buttonIndex ==  OK) {
        // segue.to.webview
        [self performSegueWithIdentifier:@"segue.to.webview" sender:self];
    }
    NSLog(@"ButtonIndex = %d", buttonIndex);

}
/*
- (IBAction)userTappedSubmitFace:(id)sender {
    NSLog(@"Tapped me.");
    [self showCarouselWebPage];
}
- (void) showCarouselWebPage {
    //NSLog(@"THe URL is %@", theURL);
    WebViewController *webVC =
    [self.storyboard instantiateViewControllerWithIdentifier:@"webViewController"];
    webVC.FaceImage = self.FaceImage_Histogram;
    [self.navigationController pushViewController:webVC animated:YES];
}
 */

@end
