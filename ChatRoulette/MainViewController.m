//
//  MainViewController.m
//  Chat Roulette
//
//  Copyright © 2016 Maxim Usmanov. All rights reserved.
//

#import "MainViewController.h"

//constants for UI
#define TOP_BAR_WRAPPER_HEIGHT 20.0f
#define SUB_VIEWS_WRAPPER_HEIGHT 20.0f
#define SPINNING_WHEEL_SIZE 30.0f

@interface MainViewController () <OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate>
{
    //OpenTok variables
    OTSession *_session;        //session
    OTPublisher *_publisher;    //our video stream
    OTSubscriber *_subscriber;  //partner's video stream
}
@end

@implementation MainViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //load view logic
    [self customizeView];
    
    //run model logic
    [self findNewSessionAndDo:^(void){
            //allocate it only once
            [self setupPublisher];
    }];
    
    // application background/foreground monitoring for publish/subscribe video toggling
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(enteringBackgroundMode:)
     name:UIApplicationWillResignActiveNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(leavingBackgroundMode:)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
}

#pragma mark - OpenTok Session

- (void)sessionDidConnect:(OTSession *)session
{
    NSLog(@"sessionDidConnect");
    
    //Forces the application to not let the iPhone go to sleep.
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // now publish
    OTError *error;
    [_session publish:_publisher error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
    [self.spinningWheelBottom stopAnimating];
}

- (void)sessionDidDisconnect:(OTSession *)session
{
    NSLog(@"sessionDidDisconnect");
    
    _subscriber = nil;
    _publisher = nil;
    
    //Allows the iPhone to go to sleep if there is not touch activity.
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)session:(OTSession *)session streamDestroyed:(OTStream *)stream
{
    
    NSLog(@"streamDestroyed");
    
    [_subscriber.view removeFromSuperview];
    _subscriber.subscribeToVideo = NO;
    _subscriber.subscribeToAudio = NO;
    
    [self findNewSessionAndDo:^(void){
        //actually do nothing
    }];
}

- (void)createSubscriber:(OTStream *)stream
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground &&
        [[UIApplication sharedApplication] applicationState] != UIApplicationStateInactive)
    {
        // create subscriber
        OTSubscriber *subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        // subscribe now
        OTError *error = nil;
        [_session subscribe:subscriber error:&error];
        if (error) {
            [self showAlert:[error localizedDescription]];
        }
    }
}

- (void)subscriberDidConnectToStream:(OTSubscriberKit *)subscriber
{
    // create subscriber
    _subscriber = (OTSubscriber *)subscriber;
    
    //put him on the screen
    [_subscriber.view setFrame:[self.partnerVideoView bounds]];
    [self.partnerVideoView addSubview:_subscriber.view];
    
}
- (void)subscriberDidDisconnectFromStream:(OTSubscriberKit *)subscriber
{
    //TODO: learn why this method never be called
    [self findNewSessionAndDo:^(void){
        //actually do nothing
    }];
}
- (void)session:(OTSession *)mySession streamCreated:(OTStream *)stream
{
    // create remote subscriber
    [self createSubscriber:stream];
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error
{
    //handle error and show alert
    [self showAlert:[NSString stringWithFormat:@"There was an error connecting to session %@", error.localizedDescription]];
}

- (void)publisher:(OTPublisher *)publisher didFailWithError:(OTError *)error
{
    //handle error and show alert
    [self showAlert:[NSString stringWithFormat: @"There was an error publishing."]];
}

- (void)subscriber:(OTSubscriber *)subscriber didFailWithError:(OTError *)error
{
    //that means somebody knowns our session id, so it was removed on the server, we have to create another one
    [self findNewSessionAndDo:^(void){
        //actually do nothing
    }];
}

#pragma mark - Helper Methods

- (void)showAlert:(NSString *)string
{
    // show alertview on main UI
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from video session"
                                                        message:string
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)enteringBackgroundMode:(NSNotification*)notification
{
    _publisher.publishVideo = NO;
    _subscriber.subscribeToVideo = NO;
}

- (void)leavingBackgroundMode:(NSNotification*)notification
{
    _publisher.publishVideo = YES;
    _subscriber.subscribeToVideo = YES;
}

#pragma mark - View Helper Methods

- (void) putSpinningWheel:(UIActivityIndicatorView*)wheel atCenterOfView:(UIView *)view
{
    [wheel setFrame:CGRectMake([view frame].size.width/2.0 - SPINNING_WHEEL_SIZE/2.0f,  //center by x of view
                               [view frame].size.height/2.0 - SPINNING_WHEEL_SIZE/2.0f, //center by y of view
                               SPINNING_WHEEL_SIZE,    //width
                               SPINNING_WHEEL_SIZE)];  //height
}

-(void) customizeView
{
    //get size of screen
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    //put partner's video view and it's Spinning Wheel
    [self.partnerVideoView setFrame:CGRectMake(0, TOP_BAR_WRAPPER_HEIGHT, screenWidth, screenHeight / 2.0 - SUB_VIEWS_WRAPPER_HEIGHT)];
    [self putSpinningWheel:self.spinningWheelTop atCenterOfView:self.partnerVideoView];
    [self.spinningWheelTop startAnimating];
    
    //put view with our camera's video and it's Spinning Wheel
    [self.fromCameraVideoView setFrame:CGRectMake(0, screenHeight / 2.0 + SUB_VIEWS_WRAPPER_HEIGHT, screenWidth, screenHeight / 2.0 - SUB_VIEWS_WRAPPER_HEIGHT)];
    [self putSpinningWheel:self.spinningWheelBottom atCenterOfView:self.fromCameraVideoView];
    [self.spinningWheelBottom startAnimating];
}


#pragma mark - Model Helper Methods

- (void)setupSessionWithApiKey:(NSString *)apiKey andSessionId:(NSString *)sessionId andToken:(NSString *)token
{
    if (_session)
    {
        _session = nil;
    }
    
    //alloc new session
    _session = [[OTSession alloc] initWithApiKey:apiKey
                                       sessionId:sessionId
                                        delegate:self];
    //open connection
    [_session connectWithToken:token error:nil];
}

- (void)setupPublisher
{
    //create publisher (video from user's camera)
    _publisher = [[OTPublisher alloc] initWithDelegate:self];
    
    //put it on the screen
    [_publisher.view setFrame:[self.fromCameraVideoView frame]];
    [self.view addSubview:_publisher.view];
}

-(void) findNewSessionAndDo:(void (^)())handler
{
    //here we go to the server and take data about the session we should connect to
    NSString *roomInfoUrl = [[NSString alloc] initWithFormat:@"%@", kServerURL];
    NSURL *url = [NSURL URLWithString:roomInfoUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
                           {
                               if (error)
                               {
                                   NSLog(@"Error,%@, url : %@", [error localizedDescription], roomInfoUrl);
                               }
                               else
                               {
                                   //parse JSON data and setup session
                                   NSDictionary *roomInfo = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                                   
                                   [self setupSessionWithApiKey:[roomInfo objectForKey:@"apiKey"]
                                                   andSessionId:[roomInfo objectForKey:@"sid"]
                                                       andToken:[roomInfo objectForKey:@"token"]];
                                   handler();
                               }
                           }];
}
@end
