//
//  NIN_ViewController.h
//  NinjaFight
//
//  Created by Michael Critz on 3/1/14.
//  Copyright (c) 2014 Map of the Unexplored. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface NIN_ViewController : UIViewController <CLLocationManagerDelegate>

// UI
@property (weak, nonatomic) IBOutlet UILabel *proximityUUIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *beaconFoundLabel;
@property (weak, nonatomic) IBOutlet UIButton *stealButton;
- (IBAction)stealButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *playAgainButton;
- (IBAction)playAgainButtonPressed:(id)sender;

// CL
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end
