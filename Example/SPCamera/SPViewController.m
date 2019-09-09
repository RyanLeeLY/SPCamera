//
//  SPViewController.m
//  SPCamera
//
//  Created by yao.li on 09/04/2019.
//  Copyright (c) 2019 yao.li. All rights reserved.
//

#import "SPViewController.h"
#import <SPCamera/SPCamera.h>
#import <SPCamera/SPOpenGLView.h>
#import "SPCameraRecordButton.h"

typedef NS_ENUM(NSUInteger, SPViewControllerFlashMode) {
    SPViewControllerFlashModeOff = 0,
    SPViewControllerFlashModeOn,
    SPViewControllerFlashModeAuto,
};

@interface SPViewController () <SPCameraDelegate, SPCameraRecordButtonDelegate>

@property (strong, nonatomic) SPCamera *camera;
@property (strong, nonatomic) SPOpenGLView *previewView;

@property (strong, nonatomic) SPCameraRecordButton *recordButton;
@property (strong, nonatomic) UIButton *switchCameraButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIImageView *miniView;

@property (assign, nonatomic) SPViewControllerFlashMode flashMode;

@end

@implementation SPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.previewView];
    [self.view addSubview:self.recordButton];
    [self.view addSubview:self.switchCameraButton];
    [self.view addSubview:self.flashButton];
    [self.view addSubview:self.miniView];
    [self _setupConstraints];
    [self customCamera];
    
    [self.camera startCapture];
    [self.switchCameraButton addTarget:self action:@selector(touchupFromSwitchCameraButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.flashButton addTarget:self action:@selector(touchupFromFlashButton:) forControlEvents:UIControlEventTouchUpInside];

    self.recordButton.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_setupConstraints {
    [NSLayoutConstraint constraintWithItem:self.recordButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.recordButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-40].active = YES;
    [NSLayoutConstraint constraintWithItem:self.recordButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:110].active = YES;
    [NSLayoutConstraint constraintWithItem:self.recordButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:110].active = YES;
}

- (void)customCamera {
    _camera = [[SPCamera alloc] initWithCameraPosition:AVCaptureDevicePositionBack
                                         captureFormat:kCVPixelFormatType_32BGRA];
    _camera.delegate = self;
}

- (void)touchupFromSwitchCameraButton:(UIButton *)sender {
    [self.camera changeCameraInputDeviceIsFront:!self.camera.isFrontCamera];
}

- (void)touchupFromFlashButton:(UIButton *)sender {
    self.flashMode += 1;
    if (self.flashMode >= 3) {
        self.flashMode = SPViewControllerFlashModeOff;
    }
    switch (self.flashMode) {
        case SPViewControllerFlashModeOff: {
            [self.flashButton setTitle:@"Flash/Off" forState:UIControlStateNormal];
            break;
        }
        case SPViewControllerFlashModeOn: {
            [self.flashButton setTitle:@"Flash/On" forState:UIControlStateNormal];
            break;
        }
        case SPViewControllerFlashModeAuto: {
            [self.flashButton setTitle:@"Flash/Auto" forState:UIControlStateNormal];
            break;
        }
    }
}

#pragma mark - SPCameraRecordButtonDelegate

- (void)recordButton:(SPCameraRecordButton *)button receiveTapGesture:(UITapGestureRecognizer *)gesture {
    switch (self.flashMode) {
        case SPViewControllerFlashModeOff: {
            [self.camera setFlashMode:AVCaptureFlashModeOff];
            break;
        }
        case SPViewControllerFlashModeOn: {
            [self.camera setFlashMode:AVCaptureFlashModeOn];
            break;
        }
        case SPViewControllerFlashModeAuto: {
            [self.camera setFlashMode:AVCaptureFlashModeAuto];
            break;
        }
    }
    [self.camera takePhoto];
}

- (void)recordButton:(SPCameraRecordButton *)button receiveLongPresssGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.miniView.image = nil;
        switch (self.flashMode) {
            case SPViewControllerFlashModeOff: {
                [self.camera setTorchMode:AVCaptureTorchModeOff];
                break;
            }
            case SPViewControllerFlashModeOn: {
                [self.camera setTorchMode:AVCaptureTorchModeOn];
                break;
            }
            case SPViewControllerFlashModeAuto: {
                [self.camera setTorchMode:AVCaptureTorchModeAuto];
                break;
            }
        }
        NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSDate *currentDate = [NSDate date];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYYMMddhhmmssSS"];
        NSString *dateString = [dateFormatter stringFromDate:currentDate];
        NSString *path = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", dateString]];
        [self.camera startRecordForFilePath:path];
    } else if (gesture.state == UIGestureRecognizerStateEnded
               || gesture.state == UIGestureRecognizerStateCancelled) {
        [self.camera setTorchMode:AVCaptureTorchModeOff];
        [self.camera stopRecord];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"SPCamera" message:@"The video has been save on Document Directory" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:nil];
            });
        }];
    }
}

#pragma mark - SPCameraDelegate
- (void)camera:(SPCamera *)camera didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
      CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //  processing photo
    [self.previewView displayPixelBuffer:pixelBuffer];
}

- (void)camera:(SPCamera *)camera didVideoStopOutputInFilePath:(NSString *)filePath {
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    NSString *outputPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"av1.mp4"];
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            
        }
    }];
}

- (void)camera:(SPCamera *)camera didOutputPhotoImage:(UIImage *)image {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.miniView.image = image;
    });
}

- (void)camera:(SPCamera *)camera didOutputVideoFramePhotoImage:(UIImage *)image {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.miniView.image = image;
    });
}

#pragma mark - getter

- (SPOpenGLView *)previewView {
    if (!_previewView) {
        _previewView = [[SPOpenGLView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _previewView;
}

- (UIImageView *)miniView {
    if (!_miniView) {
        _miniView = [[UIImageView alloc] initWithFrame:CGRectMake(150, 0, 90, 160)];
        _miniView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _miniView;
}

- (SPCameraRecordButton *)recordButton {
    if (!_recordButton) {
        _recordButton = [[SPCameraRecordButton alloc] initWithFrame:CGRectZero];
        _recordButton.maxRecordTime = 30;
        _recordButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _recordButton;
}

- (UIButton *)switchCameraButton {
    if (!_switchCameraButton) {
        _switchCameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _switchCameraButton.frame = CGRectMake(0, 0, 100, 100);
        [_switchCameraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_switchCameraButton setTitle:@"Switch" forState:UIControlStateNormal];
    }
    return _switchCameraButton;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _flashButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - 100, 0, 100, 100);
        [_flashButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_flashButton setTitle:@"Flash/Off" forState:UIControlStateNormal];
    }
    return _flashButton;
}

@end
