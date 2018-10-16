/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVBattery.h"


@implementation CDVBattery

@synthesize state, level, callbackId, isPlugged;


- (void)updateBatteryStatus:(NSNotification*)notification
{
    // get up to date battery info
    self.getBattery = [self getBatteryInfo];

    if (self.callbackId) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:self.getBattery];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }
}


/* Get the current battery status and level.  Status will be unknown and level will be -1.0 if
 * monitoring is turned off.
 */
- (void)getBatteryStatus:(CDVInvokedUrlCommand*)command
{
    // save callback id
    self.callbackId = command.callbackId;

    // register for battery changes
    if ([UIDevice currentDevice].batteryMonitoringEnabled == NO) {
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBatteryStatus:)
                                                     name:UIDeviceBatteryStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBatteryStatus:)
                                                     name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    }

    // get up to date battery info
    self.getBattery = [self getBatteryInfo];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: self.getBattery];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (NSMutableDictionary *)getBatteryInfo
{
    UIDevice* currentDevice = [UIDevice currentDevice];
    UIDeviceBatteryState currentState = [currentDevice batteryState];


    isPlugged = TRUE; //UIDeviceBatteryStateUnknown or UIDeviceBatteryStateUnplugged
    if (currentState == UIDeviceBatteryStateUnplugged) {
        isPlugged = FALSE;
    }

    float currentLevel = [currentDevice batteryLevel];

    if ((currentLevel != self.level) || (currentState != self.state)) {
        self.level = currentLevel;
        self.state = currentState;
    }

    // W3C spec says level must be null if it is unknown
    NSObject* w3cLevel = [NSNumber numberWithFloat:1.0];
    if (currentLevel == -1.0) {
        w3cLevel = [NSNumber numberWithInteger:0];
    } else {
        w3cLevel = [NSNumber numberWithFloat:currentLevel];
    }


    NSMutableDictionary* batteryData = [NSMutableDictionary dictionaryWithCapacity:2];
    [batteryData setObject:[NSNumber numberWithBool:isPlugged] forKey:@"charging"];
    [batteryData setObject:w3cLevel forKey:@"level"];

    return batteryData;
}

@end
