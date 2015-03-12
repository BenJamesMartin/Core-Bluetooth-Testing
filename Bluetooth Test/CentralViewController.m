//
//  ViewController.m
//  Bluetooth Test
//
//  Created by Benjamin Martin on 2/14/15.
//  Copyright (c) 2015 Benjamin Martin. All rights reserved.
//

// Generated from uuidgen in terminal
// Apple recommends creating your own UUID for your own profile of services-characteristics
// http://stackoverflow.com/questions/23126501/what-the-custom-uuid-mean-for-ble-in-ios-sample
#define TRANSFER_SERVICE_UUID           @"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
#define TRANSFER_CHARACTERISTIC_UUID    @"08590F7E-DB05-467E-8757-72F6FAEB13D4"

#define NOTIFY_MTU      20

#import "CentralViewController.h"

@interface CentralViewController ()

@end

@implementation CentralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    self.done = NO;
    
    self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 250, 100, 30)];
    self.doneButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.doneButton.layer.borderWidth = 2.0;
    self.doneButton.layer.cornerRadius = 15.0;
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.doneButton.titleLabel.font = [UIFont fontWithName:@"Avenir" size:16.0];
    [self.doneButton addTarget:self action:@selector(doStuff) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
}

- (void)doStuff
{
    self.done = YES;
}
    
#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    
    NSLog(@"Central manager powered on");
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

// What does the advertisement data contain? One of the peripheral’s services?
// No, it just states whether peripheral can be connected to, its available service UUIDs, and data channel
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"what peripheral %@", peripheral);
//    NSLog(@"Advertisement data %@ and RSSI %@", advertisementData, RSSI);
    self.discoveredPeripheral = peripheral;
    self.discoveredPeripheral.delegate = self;
    self.peripheralInfo.text = [NSString stringWithFormat:@"%@", RSSI];
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Could not connect to peripheral: \n%@", error);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    [self.data setLength:0];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"didDiscoverCharacteristicsForService");
    
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }

    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
            
            // If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            NSLog(@"\n\n subscribing to characteristic %@ \n\n", characteristic);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
 didModifyServices:(NSArray *)invalidatedServices
{
    NSLog(@"didModifyServices");
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"gonna start transferring data");
    
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        
        // We have, so show the data,
        [self.peripheralInfo setText:[[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
        
//        // Cancel our subscription to the characteristic
//        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
//        
//        // and disconnect from the peripehral
//        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    
    // Otherwise, just add the data on to what we already have
    [self.data appendData:characteristic.value];
    
    // Log it
    NSLog(@"Received: %@", stringFromData);
}

/* The peripheral letting us know whether our subscribe/unsubscribe happened or not */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateNotificationStateForCharacteristic");
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }

}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.peripheralInfo.text = @"Disconnected Peripheral";
    NSLog(@"Peripheral Disconnected");
    self.discoveredPeripheral = nil;
    
    // We're disconnected, so start scanning again
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!self.discoveredPeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}

#pragma mark - CBPeripheralManagerDelegate

// How is this different from a central manager changing state?
// - centralManager will just check state powered on and then start scanning for peripherals.
// - peripheralManager will check state and also build service/characteristic profile
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState");
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Powered on");
    }
    
    self.characteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
    
    service.characteristics = @[self.characteristic];
    
    [self.peripheralManager addService:service];
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
}

// A central subscribed to one of our services’ characteristics
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"didSubscribeToCharacteristic");
    
    // Get the data
    self.dataToSend = [@"hey thereasdfsafjsadlkfjdklsfadjlk" dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
//    if (self.done) {
        [self sendData];
//    }
}

// A central unsubscribed from one of our services characteristics but did not disconnect
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"didUnsubscribeFromCharacteristic");
}

// Send next chunk of data to subscribed central
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
    [self sendData];
}

/** Sends the next amount of data to the connected central
 */
- (void)sendData
{
    NSLog(@"sending data");
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    if (sendingEOM) {
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            // It did, so mark it as sent
            sendingEOM = NO;
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    // Is there any left to send?
    if (self.sendDataIndex >= self.dataToSend.length) {
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;
    while (didSend) {
        
        // Make the next chunk
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        NSLog(@"what chunk %@", [NSString stringWithFormat:@"%@", self.data]);
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.characteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
