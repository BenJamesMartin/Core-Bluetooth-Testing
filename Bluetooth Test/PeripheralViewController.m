//
//  PeripheralViewController.m
//  Bluetooth Test
//
//  Created by Benjamin Martin on 2/14/15.
//  Copyright (c) 2015 Benjamin Martin. All rights reserved.
//

#define TRANSFER_SERVICE_UUID           @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FAEB13D4"

#import "PeripheralViewController.h"

@interface PeripheralViewController ()

@end

@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"this should never happen");
}

#pragma mark - CBPeripheralManagerDelegate

// How is this different from a central manager changing state?
// - centralManager will just check state powered on and then start scanning for peripherals.
// - peripheralManager will check state and also build service/characteristic profile
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Powered on");
    }
    
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    
    service.characteristics = @[self.characteristic];
    
    [self.peripheralManager addService:service];
}

// A central subscribed to one of our services’ characteristics
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    
}

//A central unsubscribed from one of our services characteristics but did not disconnect
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    
}

//Send next chunk of data to subscribed central
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
