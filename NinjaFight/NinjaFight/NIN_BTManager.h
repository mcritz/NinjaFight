//
//  NIN_BTManager.h
//  NinjaFight
//
//  Created by Michael Critz on 3/1/14.
//  Copyright (c) 2014 Map of the Unexplored. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef enum {
    BluetoothCommandHandshake=1,
    BluetoothCommandNegotiate,
    BluetoothCommandNegotiateConfirm,
    BluetoothCommandAttack,
    BluetoothCommandDefend,
    BluetoothCommandSteal,
    BluetoothCommandWin,
    BluetoothCommandDisconnect
} BluetoothCommand;

@interface NIN_BTManager : NSObject <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate>
{
    MCNearbyServiceBrowser *nearbyBrowser;
    MCNearbyServiceAdvertiser *nearbyAdvertiser;
    MCSession *session;
    NSString *peerId;
    NSDate *playerIndexTimestamp;
}

@property (nonatomic, readonly) NSString *peerName;
@property (nonatomic, readonly) NSInteger playerIndex;

+ (NIN_BTManager *)instance;
+ (BOOL)hasConnection;

- (void)sendDictionaryToPeers:(NSDictionary*)dict;



@end
