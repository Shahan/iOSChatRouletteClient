//
//  MainViewController.h
//  Chat Roulette
//
//  Copyright © 2016 Maxim Usmanov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>

//Hardcoded path to server. I know, it's bad, in other time I'll put it in Settings bundle :)
const static NSString * kServerURL = @"http://m4x13.herokuapp.com/roulette.json";

@interface MainViewController : UIViewController <OTSessionDelegate, OTPublisherDelegate>

//views containing video streams
@property (strong, nonatomic) IBOutlet UIView *partnerVideoView; 
@property (strong, nonatomic) IBOutlet UIView *fromCameraVideoView;

//spinning "loading" wheels appears when there is no video stream
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheelTop;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheelBottom;

@end
