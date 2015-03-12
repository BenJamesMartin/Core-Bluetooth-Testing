//
//  PeripheralViewController.h
//  Bluetooth Test
//
//  Created by Benjamin Martin on 2/14/15.
//  Copyright (c) 2015 Benjamin Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralViewController : UIViewController <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *characteristic;

@end
