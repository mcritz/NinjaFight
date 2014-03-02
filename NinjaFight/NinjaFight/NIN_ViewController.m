 //
//  NIN_ViewController.m
//  NinjaFight
//
//  Created by Michael Critz on 3/1/14.
//  Copyright (c) 2014 Map of the Unexplored. All rights reserved.
//

#import "NIN_ViewController.h"
#import "NIN_BTManager.h"

@interface NIN_ViewController ()

@property bool isPlaying;
@property bool canSteal;
@property bool isStealing;
@property bool canAttack;
@property bool isDefending;
@property bool isInjured;

@property (nonatomic, strong)CLBeacon *beacon;
@property (nonatomic, strong)CMMotionManager *motionManager;

@end

@implementation NIN_ViewController

@synthesize locationManager = _locationManager;
@synthesize stealLongPressGestureRecognizer;

-(void)outputAccelertionData:(CMAcceleration)acceleration
{
    float xThreshold = .3;
    float yThreshold = .8;
    float zThreshold = .3;
    if (fabs(acceleration.x) < xThreshold
        && fabs(acceleration.y) > yThreshold
        && fabs(acceleration.z) < zThreshold) {
        [self defend];
    } else {
        [self clearActions];
    }
//    self.debugLabel.text = [NSString stringWithFormat:@"a: %f, %f, %f", acceleration.x, acceleration.y, acceleration.z];
}

-(void)outputRotationData:(CMRotationRate)rotation
{
    float xThreshold = .8;
    float yThreshold = .8;
    float zThreshold = .8;
    if (fabs(rotation.x) > xThreshold
        && fabs(rotation.y) > yThreshold
        && fabs(rotation.z) > zThreshold) {
        [self attack];
    }
}

- (void)attack {
    NSLog(@"Attacking!");
    if (self.isInjured ||
        !self.isPlaying) {
        return;
    } else {
        AudioServicesPlaySystemSound (attackSoundFileObject);
        self.gameStatusLabel.text = @"Attack!";
        self.canSteal = NO;
        NSDictionary *dict = @{@"command" : @(BluetoothCommandAttack)};
        [[NIN_BTManager instance] sendDictionaryToPeers:dict];
    }
}

- (void)clearActions {
    if (!self.isInjured) {
        self.gameStatusLabel.text = @"";
        [self.actionImage setImage:nil];
        [self.actionImage setHidden:YES];
        self.canAttack = YES;
        self.canSteal = YES;
        self.isDefending = NO;
        [self.actionImage.layer removeAllAnimations];
    }
}

- (void)defend {
    if (!self.isInjured
        && self.isPlaying) {
        self.gameStatusLabel.text = @"Defending!";
        [self.actionImage setImage:[UIImage imageNamed:@"defending"]];
        [self.actionImage setHidden:NO];
        self.canAttack = NO;
        self.isDefending = YES;
        self.canSteal = NO;
    }
}

- (void)attacked {
    NSLog(@"I have been attacked");
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    
    if (self.isDefending
        || self.isInjured) {
        return;
    } else {
        self.isInjured = YES;
        AudioServicesPlaySystemSound (hitSoundFileObject);
        self.gameStatusLabel.text = @"You have been attacked!";
        [self.actionImage setImage:[UIImage imageNamed:@"OUCH"]];
        [self.actionImage setHidden:NO];
        [self addSlowFadeToLayer:self.actionImage.layer];
        self.canAttack = NO;
    }
}

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
    CGAffineTransform labelRotation = CGAffineTransformMakeRotation(-.1);
    [self.beaconFoundLabel setTransform:labelRotation];
    [self.gameStatusLabel setTransform:labelRotation];
    [self.gameStatusLabel setText:@"Loading…"];

    // Networking
    [NIN_BTManager instance];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bluetoothDataReceived:)
                                                 name:@"bluetoothDataReceived"
                                               object:nil];
    // CoreMotion
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error){
        [self outputAccelertionData:accelerometerData.acceleration];
        if (error) {
            NSLog(@"CMAccError: \n%@", error);
        }
    }];
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData *gyroData, NSError *error){
        [self outputRotationData:gyroData.rotationRate];
        if (error) {
            NSLog(@"CMGyroError: \n%@", error);
        }
    }];

    // Audio
    self.attackSoundFileURLRef = [[NSBundle mainBundle] URLForResource: @"hiyaa!"
                                                withExtension: @"m4a"];
    self.hitSoundFileURLRef = [[NSBundle mainBundle] URLForResource: @"ouchsound_trimmed"
                                                         withExtension: @"m4a"];
    self.winSoundFileURLRef = [[NSBundle mainBundle] URLForResource: @"oh_maaaaai"
                                                      withExtension: @"m4a"];
    self.loseSoundFileURLRef = [[NSBundle mainBundle] URLForResource: @"great_shame"
                                                      withExtension: @"m4a"];
    AudioServicesCreateSystemSoundID (
                                  (__bridge CFURLRef)(self.attackSoundFileURLRef),
                                  &attackSoundFileObject
                              );
    AudioServicesCreateSystemSoundID (
                              (__bridge CFURLRef)(self.hitSoundFileURLRef),
                              &hitSoundFileObject
                              );
    AudioServicesCreateSystemSoundID (
                                      (__bridge CFURLRef)(self.winSoundFileURLRef),
                                      &winSoundFileObject
                                      );
    AudioServicesCreateSystemSoundID (
                                      (__bridge CFURLRef)(self.loseSoundFileURLRef),
                                      &loseSoundFileObject
                                      );

    
    // UI
//    [self.debugLabel setHidden:YES];

    [self.beaconFoundLabel setText:@"Starting up…"];
    [self.stealButton setHidden:YES];
    [self.playAgainButton setHidden:YES];
    [self.linesImage setHidden:YES];
    [self initRegion];
    self.stealLongPressGestureRecognizer.delegate = self;
    
    self.canAttack = YES;
    self.canSteal = YES;
    self.isInjured = NO;
}

- (void)bluetoothDataReceived:(NSNotification *)note {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSDictionary *dict = [note object];
        NSInteger command = [dict[@"command"] intValue];
        switch( command ) {
            case BluetoothCommandHandshake : {
                NSLog(@"BluetoothCommandHandshake");
                self.beaconFoundLabel.text = @"Another Ninja Approaches!";
                break;
            }
            case BluetoothCommandAttack :
            {
                NSLog(@"BluetoothCommandAttack");
                [self attacked];
                break;
            }
            case BluetoothCommandDefend : {
                NSLog(@"BluetoothCommandDefend");
                self.gameStatusLabel.text = @"Opponent is defending!";
                break;
            }
            case BluetoothCommandSteal : {
                NSLog(@"BluetoothCommandSteal");
                self.gameStatusLabel.text = @"Opponent is stealing!";
                break;
            }
            case BluetoothCommandWin : {
                NSLog(@"BluetoothCommandWin");
                [self loseGame];
                break;
            }
        }
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)initRegion {
    self.debugLabel.text = @"initRegion";
    self.isPlaying = YES;
    [self.beaconFoundLabel setText:@"No gems found…"];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    self.debugLabel.text = @"didEnterRegion";

    [self.gameStatusLabel setText:@""];
    [self.beaconFoundLabel setText:@"Find the gem!"];
    self.isPlaying = YES;
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    self.debugLabel.text = @"didExitRegion";
    
    self.isPlaying = NO;
    [self.beaconFoundLabel setText:@"No gems found"];
    [self.gameStatusLabel setText:@""];
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    if (!self.isPlaying) {
        return;
    }
//    if (!self.beacon) {
        self.beacon = [beacons lastObject];
//        for (CLBeacon *bcn in beacons) {
//            if ([bcn.major isEqualToNumber:@(1)] && [bcn.minor isEqualToNumber:@(4)]) {
//                self.beacon = bcn;
//                break;
//            }
//        }
//    }
    if (self.beacon.proximity == CLProximityUnknown) {
        self.debugLabel.text = @"CLProximityUnknown";
    } else if (self.beacon.proximity == CLProximityImmediate) {
        self.debugLabel.text = @"CLProximityImmediate";
        //        self.beaconFoundLabel.text = [NSString stringWithFormat: @"accuracy: %f", beacon.accuracy];
        if (self.isPlaying && !self.isStealing) {
            self.beaconFoundLabel.text = @"Steal the gem!";
            [self.gemImage setImage:[UIImage imageNamed:@"stealinggemrays1"]];
        }
    } else if (self.beacon.proximity == CLProximityNear) {
        self.debugLabel.text = @"CLProximityNear";
        if (self.isPlaying && !self.isStealing) {
            [self.beaconFoundLabel setText:@"Gem nearby!"];
        }
        [self.gemImage setImage:[UIImage imageNamed:@"2color"]];
    } else if (self.beacon.proximity == CLProximityFar) {
        self.debugLabel.text = @"CLProximityFar";
        self.isPlaying = YES;
        self.isStealing = NO; // TechDebt: user can hold a steal gesture, but this will fail
        self.beaconFoundLabel.text = @"Find the gem…";
        [self.gemImage setImage:[UIImage imageNamed:@"onecolor"]];
    }
}


// Game mechanics

- (IBAction)stealButtonPressed:(id)sender {
    [self winGame];
}

- (void)winGame {
    NSLog(@"winGame");
    self.isPlaying = NO;
    self.isStealing = NO;
    
    NSDictionary *dict = @{@"command" : @(BluetoothCommandWin)};
    [[NIN_BTManager instance] sendDictionaryToPeers:dict];
    
    AudioServicesPlaySystemSound (winSoundFileObject);
    [self.gemImage setImage:[UIImage imageNamed:@"blackninjawin"]];
    [self.linesImage setHidden:NO];
    [self.gameStatusLabel setText:@"YOU WIN!"];
    [self.beaconFoundLabel setText:@""];
    [self.playAgainButton setHidden:NO];
}

- (void)loseGame {
    NSLog(@"loseGame");
    [self.linesImage setHidden:YES];
    
    AudioServicesPlaySystemSound (loseSoundFileObject);
    [self.gemImage setImage:[UIImage imageNamed:@"blueninjayoulose"]];
    [self.gameStatusLabel setText:@"YOU LOSE!"];
    [self.beaconFoundLabel setText:@""];
    [self.playAgainButton setHidden:NO];
    self.isPlaying = NO;
}

- (IBAction)playAgainButtonPressed:(id)sender {
    self.isPlaying = YES;
    self.canAttack = YES;
    self.canSteal = YES;
    self.isInjured = NO;
    [self clearActions];
    
    [self.beaconFoundLabel setText:@"Find the gem!"];
    [self.gameStatusLabel setText:@""];
    [self.gemImage setImage:[UIImage imageNamed:@"empty"]];
    
    if (!self.isPlaying) {
//                [self.gemImage setImage:[UIImage imageNamed:@"empty"]];
//        [self.beaconFoundLabel setText:@"Move away from gem"];
    }
    [self.linesImage setHidden:YES];
    [self.linesImage.layer removeAllAnimations];
    
    [self.playAgainButton setHidden:YES];
    [self.stealButton setHidden:YES];
}

- (bool)playerCanSteal {
    return YES;
    if (!self.isPlaying
        || !self.beacon
        || self.isInjured
        || self.isDefending) {
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

- (void)addRotateAnimationForLayer:(CALayer *)layer{
    
    NSString *keyPath = @"transform.rotation";
    
    // Allocate a CAKeyFrameAnimation for the specified keyPath.
    CAKeyframeAnimation *translation = [CAKeyframeAnimation animationWithKeyPath:keyPath];
    
    // Set animation duration and repeat
    translation.duration = 3.5f;
    translation.repeatCount = HUGE_VAL;
    
    // Allocate array to hold the values to interpolate
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    // Add the start value
    // The animation starts at a y offset of 0.0
    [values addObject:[NSNumber numberWithFloat:0.0f]];
    
    // Add the end value
    // The animation finishes when the ball would contact the bottom of the screen
    // This point is calculated by finding the height of the applicationFrame
    // and subtracting the height of the ball.
    CGFloat height = [[UIScreen mainScreen] applicationFrame].size.height - layer.frame.size.height;
    [values addObject:[NSNumber numberWithFloat:height]];
    
    // Set the values that should be interpolated during the animation
    translation.values = values;
    
    [layer addAnimation:translation forKey:keyPath];
}


- (void)addSlowFadeToLayer:(CALayer *)layer {
    [CATransaction begin];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 1.5f;
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeBoth;
    animation.additive = NO;
    [CATransaction setCompletionBlock:^(void){
        self.isInjured = NO;
        [self clearActions];
    }];
    [layer addAnimation:animation forKey:@"opacityOUT"];
    [CATransaction commit];
}

- (IBAction)stealLongPress:(UILongPressGestureRecognizer *)sender {
    NSLog(@"stealLongPress");
    [self.linesImage setHidden:NO];
    [self addRotateAnimationForLayer:self.linesImage.layer];
    
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![self playerCanSteal]) {
        return;
    } else {
        NSDictionary *dict = @{@"command" : @(BluetoothCommandSteal)};
        [[NIN_BTManager instance] sendDictionaryToPeers:dict];
        self.isStealing = YES;
        [self.gemImage setImage:[UIImage imageNamed:@"stealinggemrays1"]];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.isStealing = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.isStealing = NO;
}

@end
