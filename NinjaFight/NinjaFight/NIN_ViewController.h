//
//  NIN_ViewController.h
//  NinjaFight
//
//  Created by Michael Critz on 3/1/14.
//  Copyright (c) 2014 Map of the Unexplored. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@interface NIN_ViewController : UIViewController <CLLocationManagerDelegate, UIGestureRecognizerDelegate>

// UI
@property (weak, nonatomic) IBOutlet UILabel *proximityUUIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *beaconFoundLabel;
@property (weak, nonatomic) IBOutlet UIButton *stealButton;
- (IBAction)stealButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *playAgainButton;
- (IBAction)playAgainButtonPressed:(id)sender;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *stealLongPressGestureRecognizer;
- (IBAction)stealLongPress:(UILongPressGestureRecognizer *)sender;
@property (weak, nonatomic) IBOutlet UIImageView *gemImage;
@property (weak, nonatomic) IBOutlet UIImageView *linesImage;
@property (weak, nonatomic) IBOutlet UILabel *debugLabel;

// CL
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end
