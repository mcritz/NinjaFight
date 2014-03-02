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
@property bool isStealing;
@property (nonatomic, strong)CLBeacon *beacon;

@end

@implementation NIN_ViewController

@synthesize locationManager = _locationManager;
@synthesize stealLongPressGestureRecognizer;

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
    self.view.backgroundColor = [UIColor colorWithRed: 0.725 green: 0.914 blue: 0.984 alpha: 1];

    [self.beaconFoundLabel setText:@"Starting up…"];
    [self.stealButton setHidden:YES];
    [self.playAgainButton setHidden:YES];
    [self.linesImage setHidden:YES];
    [self initRegion];
    self.stealLongPressGestureRecognizer.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)initRegion {
    self.debugLabel.text = @"initRegion";
    self.isPlaying = YES;
    [self.beaconFoundLabel setText:@"No gems found…"];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    self.debugLabel.text = @"didEnterRegion";

    [self.beaconFoundLabel setText:@"Find the gem!"];
    self.isPlaying = YES;
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    self.debugLabel.text = @"didExitRegion";
    
    self.isPlaying = NO;
    [self.beaconFoundLabel setText:@"No gems found"];
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if (!self.beacon) {
        for (CLBeacon *bcn in beacons) {
            if ([bcn.major isEqualToNumber:@(1)] && [bcn.minor isEqualToNumber:@(4)]) {
                self.beacon = bcn;
                break;
            }
        }
    }
    if (self.beacon.proximity == CLProximityUnknown) {
        self.debugLabel.text = @"CLProximityFar";
    } else if (self.beacon.proximity == CLProximityImmediate) {
        self.debugLabel.text = @"CLProximityImmediate";
        //        self.beaconFoundLabel.text = [NSString stringWithFormat: @"accuracy: %f", beacon.accuracy];
        if (self.isPlaying && !self.isStealing) {
            self.beaconFoundLabel.text = @"Steal the gem!";
            [self.gemImage setImage:[UIImage imageNamed:@"stealinggemrays1"]];
//            [self.stealButton setHidden:NO];
        }
    } else if (self.beacon.proximity == CLProximityNear) {
        self.debugLabel.text = @"CLProximityNear";
        if (self.isPlaying && !self.isStealing) {
            [self.beaconFoundLabel setText:@"Gem nearby!"];
//            [self.stealButton setHidden:NO];
        }
        [self.gemImage setImage:[UIImage imageNamed:@"stealgem"]];
    } else if (self.beacon.proximity == CLProximityFar) {
        self.debugLabel.text = @"CLProximityFar";
        self.isPlaying = YES;
        self.isStealing = NO; // TechDebt: user can hold a steal gesture, but this will fail
        self.beaconFoundLabel.text = @"Find the gem…";
        [self.gemImage setImage:[UIImage imageNamed:@"onecolor"]];
//        [self.stealButton setHidden:YES];
    }
}


// Game mechanics

- (IBAction)stealButtonPressed:(id)sender {
    [self winGame];
}

- (void)winGame {
    NSLog(@"winGame");
    [self.linesImage setHidden:NO];
    [self.beaconFoundLabel setText:@"YOU WIN!"];
    [self.stealButton setHidden:YES];
    [self.playAgainButton setHidden:NO];
    self.isPlaying = NO;
}

- (IBAction)playAgainButtonPressed:(id)sender {
    self.isPlaying = YES;
    if (!self.isPlaying) {
//        [self.gemImage setImage:[UIImage imageNamed:@"empty"]];
//        [self.beaconFoundLabel setText:@"Move away from gem"];
    }
    [self.linesImage setHidden:YES];
    [self.playAgainButton setHidden:YES];
    [self.stealButton setHidden:YES];
}

- (bool)playerCanSteal {
    return YES;
    if (!self.isPlaying) {
        return NO;
    }
    if (!self.beacon) {
        return NO;
    }
    switch (self.beacon.proximity) {
        case CLProximityUnknown:
            return YES;
            break;
        case CLProximityNear:
            return YES;
            break;
        case CLProximityFar:
            return NO;
            break;
        default:
            return NO;
            break;
    }
    return NO; // just 'cause
}


// UI Gestures

- (IBAction)stealLongPress:(UILongPressGestureRecognizer *)sender {
    NSLog(@"stealLongPress");
    
    if (![self playerCanSteal]) {
        return;
    }
    if ([sender state] == UIGestureRecognizerStateBegan && [self playerCanSteal]) {
        [self.debugLabel setText:@"stealLongPress began"];
        NSLog(@"stealLongPress began");

        [self winGame];
        
    } else if ([sender state] == UIGestureRecognizerStateCancelled) {
        self.debugLabel.text = @"stealLongPress ended";
        NSLog(@"stealLongPress ended");
        self.isStealing = NO;
    }
}

@end
