//
//  NIN_BTManager.m
//  NinjaFight
//
//  Created by Michael Critz on 3/1/14.
//  Copyright (c) 2014 Map of the Unexplored. All rights reserved.
//

#import "NIN_BTManager.h"
#define kBTAppID @"ninjafight"

static NIN_BTManager *sharedInstance = nil;

@implementation NIN_BTManager

+ (NIN_BTManager *)instance
{
    if( sharedInstance == nil )
        sharedInstance = [NIN_BTManager new];
    return sharedInstance;
}


- (id)init {
    self = [super init];
    // get user device name
    MCPeerID *myId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    // setup browser
    nearbyBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:myId serviceType:kBTAppID];
    nearbyBrowser.delegate = self;
    [nearbyBrowser startBrowsingForPeers];
    
    // advertise a game
    nearbyAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:myId discoveryInfo:nil serviceType:kBTAppID];
    nearbyAdvertiser.delegate = self;
    [nearbyAdvertiser startAdvertisingPeer];
    session = [[MCSession alloc] initWithPeer:myId];
    session.delegate = self;
    
    return self;
}

// start to recieve a resource
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {}

// recieve a byte stream
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {}

// finish recieving a resource
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {}

// Confirm connection
+ (BOOL)hasConnection {
    return (sharedInstance != nil && sharedInstance.peerName != nil);
}

- (void)sendDictionaryToPeers:(NSDictionary *)dict {
    NSError *error = nil;
    NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:dict];
    [session sendData:encodedData toPeers:session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    NSLog(@"sent: \n%@", dict);
    if (error) {
        NSLog(@"Failed to send data to peers. :'(");
    }
}

#pragma mark - Browser delegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    [browser invitePeer:peerID toSession:session withContext:nil timeout:0];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSError *error;
    NSLog(@"Peer lost. Errors suck: %@", error);
}

#pragma mark - Advertiser delegate

-(void) advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    invitationHandler( YES, session );
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    if (state == MCSessionStateConnected) {
        NSDictionary *handshake = @{
                                     @"command" : @(BluetoothCommandHandshake),
                                     @"peerName" : [[UIDevice currentDevice] name]
                                    };
        [self sendDictionaryToPeers:handshake];
    } else if (state == MCSessionStateNotConnected) {
        NSLog(@"No connection");
        NSDictionary *dict = @{ @"command" : @(BluetoothCommandDisconnect),
                               @"status" : @"disconnected" };
        [[NSNotificationCenter defaultCenter] postNotificationName:@"bluetoothDataReceived" object:dict];

    }
}

#pragma mark - session delegate

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    NSLog(@"Recieved: \n%@", dict);
    
    NSInteger command = [dict[@"command"] intValue];
    switch (command) {
        case BluetoothCommandHandshake : {
            _peerName = [dict objectForKey:@"peerName"];
            
            // Negotiate a host
            // rock… paper… scissors…
            playerIndexTimestamp = [NSDate date];
            NSDictionary *negotiation = @{@"command" : @(BluetoothCommandNegotiate),
                                          @"playerIndex" : @0,
                                          @"timeStamp" : playerIndexTimestamp
                                          };
            
            [self sendDictionaryToPeers:negotiation];
            break;
        }
        case BluetoothCommandNegotiate : {
            NSDate *otherTimestamp = [dict objectForKey:@"timestamp"];
            NSInteger otherPlayer = [[dict objectForKey:@"playerIndex"] intValue];
            if ([otherTimestamp compare:playerIndexTimestamp] == NSOrderedAscending) {
                // They win the coin toss
                _playerIndex = 1 - otherPlayer;
                NSDictionary *confirmation = @{
                                               @"command" : [NSNumber numberWithInt:BluetoothCommandNegotiateConfirm],
                                               @"playerName" : @(_playerIndex)
                                              };
                [self sendDictionaryToPeers:confirmation];
                // Maybe: some type of warning…
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Another ninja approaches…" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                });
            }
            break;
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"bluetoothDataReceived" object:dict];
}

@end
