//
//  InitialViewController.h
//  Bluetooth Test
//
//  Created by Benjamin Martin on 3/11/15.
//  Copyright (c) 2015 Benjamin Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface InitialViewController : UIViewController <CBPeripheralManagerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *characteristic;

@end
