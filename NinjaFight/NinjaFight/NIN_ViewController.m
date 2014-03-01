//
//  NIN_ViewController.m
//  NinjaFight
//
//  Created by Michael Critz on 3/1/14.
//  Copyright (c) 2014 Map of the Unexplored. All rights reserved.
//

#import "NIN_ViewController.h"

@interface NIN_ViewController ()

@end

@implementation NIN_ViewController

@synthesize locationManager = _locationManager;

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (CLBeaconRegion *)beaconRegion {
    if (!_beaconRegion) {
        // TODO: not shitty hardcoded beacon
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"8AEFB031-6C32-486F-825B-E26FA193487D"];
        _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"com.MapOfTheUnexplored.NinjaFight"];
    }
    return _beaconRegion;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.stealButton setHidden:NO];
    [self.playAgainButton setHidden:YES];
    [self initRegion];
    self.stealLongPressGestureRecognizer.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)initRegion {
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    [self.beaconFoundLabel setText:@"Scanning"];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self.beaconFoundLabel setText:@"Gem nearby!"];
    [self.stealButton setHidden:NO];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.beaconFoundLabel setText:@"Left region"];
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

- (IBAction)stealButtonPressed:(id)sender {
    [self winGame];
}


- (void)winGame {
    NSLog(@"winGame");
    [self.beaconFoundLabel setText:@"YOU WIN!"];
    [self.stealButton setHidden:YES];
    [self.playAgainButton setHidden:NO];
}

- (IBAction)playAgainButtonPressed:(id)sender {
    [self.beaconFoundLabel setText:@"Scanning"];
    [self.playAgainButton setHidden:YES];
    [self.stealButton setHidden:YES];
}

- (IBAction)stealLongPress:(id)sender {
    NSLog(@"stealLongPress");
    if([sender state] ==  UIGestureRecognizerStateBegan) {
        [self winGame];
    }
}
@end
