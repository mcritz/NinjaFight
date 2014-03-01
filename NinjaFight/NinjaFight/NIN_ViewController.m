 //
//  NIN_ViewController.m
//  NinjaFight
//
//  Created by Michael Critz on 3/1/14.
//  Copyright (c) 2014 Map of the Unexplored. All rights reserved.
//

#import "NIN_ViewController.h"

@interface NIN_ViewController ()

@property bool isPlaying;

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
    [self.stealButton setHidden:YES];
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
    [self.beaconFoundLabel setText:@"Starting up…"];
    self.isPlaying = YES;
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    self.isPlaying = YES;
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.beaconFoundLabel setText:@"You have entered the land of ghosts and wind"];
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    CLBeacon *beacon = [[CLBeacon alloc] init];
    beacon = [beacons lastObject];
    
    self.proximityUUIDLabel.text = beacon.proximityUUID.UUIDString;
    if (beacon.proximity == CLProximityUnknown) {
        // TechDebt: maybe something?
    } else if (beacon.proximity == CLProximityImmediate && self.isPlaying) {
//        self.beaconFoundLabel.text = [NSString stringWithFormat: @"accuracy: %f", beacon.accuracy];
        self.beaconFoundLabel.text = @"Gem very close!";
        [self.stealButton setHidden:NO];
    } else if (beacon.proximity == CLProximityNear && self.isPlaying) {
        [self.beaconFoundLabel setText:@"Gem nearby!"];
        [self.stealButton setHidden:NO];
    } else if (beacon.proximity == CLProximityFar) {
        self.isPlaying = YES;
        self.beaconFoundLabel.text = @"Find the gem…";
        [self.stealButton setHidden:YES];
    }
}


// Game mechanics

- (IBAction)stealButtonPressed:(id)sender {
    [self winGame];
}

- (void)winGame {
    NSLog(@"winGame");
    [self.beaconFoundLabel setText:@"YOU WIN!"];
    [self.stealButton setHidden:YES];
    [self.playAgainButton setHidden:NO];
    self.isPlaying = NO;
}

- (IBAction)playAgainButtonPressed:(id)sender {
    if (!self.isPlaying) {
        [self.beaconFoundLabel setText:@"Move away from gem"];
    }
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
