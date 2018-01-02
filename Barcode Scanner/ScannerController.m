//
//  ViewController.m
//  Barcode Scanner
//
//  Created by Rudolph, Aaron on 4/10/17.
//  Copyright © 2017 Aaron Rudolph. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ScannerController.h"
#import "BarcodePreview.h"

@interface ScannerController () <AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_input;
    AVCaptureMetadataOutput *_output;
    AVCaptureVideoPreviewLayer *_prevLayer;
    
    IBOutlet UIView *cameraView;
    
    BarcodePreview * bclayer;
}
@end

@implementation ScannerController

NSString * value;
NSString * detectionString = nil;

BOOL scanning_disabled = false;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (_input) {
        [_session addInput:_input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_session addOutput:_output];
    
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _prevLayer.frame = cameraView.bounds;
    
    [cameraView.layer addSublayer:_prevLayer];
    
    bclayer = [[BarcodePreview alloc] init];
    bclayer.frame = cameraView.bounds;
    [cameraView.layer addSublayer:bclayer];
    
    [self viewDidLayoutSubviews];
    
    [bclayer setNeedsDisplay];
    
    [_session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [bclayer setBarcodePolyline:nil];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
    [bclayer setBarcodePolyline:nil];
    for (AVMetadataObject *metadata in metadataObjects)
    {
        if([metadata isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
        {
            for (NSString *type in barCodeTypes)
            {
                [bclayer setBarcodePolyline:[(AVMetadataMachineReadableCodeObject *)[captureOutput transformedMetadataObjectForMetadataObject:metadata connection:connection] corners]];
                
                if ([metadata.type isEqualToString:type] && !scanning_disabled)
                {
                    scanning_disabled = true;
                    detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                    
                    bool canOpen = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:detectionString]];
                    UIAlertController * options = [UIAlertController alertControllerWithTitle:@"Data" message:detectionString preferredStyle:UIAlertControllerStyleActionSheet];
                    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
                                                    {
                                                        scanning_disabled = false;
                                                    }];
                    
                    if(canOpen == false)
                    {
                        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"Copy to Clipboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                                         {
                                                             UIPasteboard *clipboard = [UIPasteboard generalPasteboard];
                                                             [clipboard setString:detectionString];
                                                             scanning_disabled = false;
                                                         }];
                        [options addAction:defaultAction];
                        [options addAction:cancelAction];
                    }
                    else
                    {
                        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle:@"Open" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                                         {
                                                             [[UIApplication sharedApplication] openURL:[NSURL URLWithString:detectionString] options:@{} completionHandler:nil];
                                                             scanning_disabled = false;
                                                         }];
                        UIAlertAction * alternateAction = [UIAlertAction actionWithTitle:@"Copy to Clipboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                                           {
                                                               UIPasteboard *clipboard = [UIPasteboard generalPasteboard];
                                                               [clipboard setString:detectionString];
                                                               scanning_disabled = false;
                                                           }];
                        [options addAction:defaultAction];
                        [options addAction:alternateAction];
                        [options addAction:cancelAction];
                    }
                    [self presentViewController:options animated:YES completion:nil];
                    break;
                }
            }
        }
    }
}

@end
