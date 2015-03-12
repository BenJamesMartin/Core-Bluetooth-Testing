//
//  ViewController.h
//  Bluetooth Test
//
//  Created by Benjamin Martin on 2/14/15.
//  Copyright (c) 2015 Benjamin Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *characteristic;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSData *dataToSend;
@property (nonatomic, readwrite) NSInteger sendDataIndex;

@property (strong, nonatomic) IBOutlet UILabel *peripheralInfo;
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) UIButton *doneButton;
@property (assign, nonatomic) BOOL done;

@end

