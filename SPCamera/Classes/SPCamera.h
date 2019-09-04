//
//  SPCamera.h
//  TPFaceUSDK_Example
//
//  Created by Yao Li on 2018/6/6.
//  Copyright © 2018年 yao.li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class SPCamera;

@protocol SPCameraDelegate <NSObject>
@optional
- (void)camera:(SPCamera *)camera didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)camera:(SPCamera *)camera didOutputVideoFramePhotoImage:(UIImage *)image;

- (void)camera:(SPCamera *)camera didVideoStopOutputInFilePath:(NSString *)filePath;
- (void)camera:(SPCamera *)camera didOutputPhotoImage:(UIImage *)image;
@end

@interface SPCamera : NSObject
@property (assign, nonatomic) id<SPCameraDelegate> delegate;
@property (assign, nonatomic, readonly) BOOL isFrontCamera;
@property (nonatomic, readonly) AVCaptureFlashMode flashMode;
@property (nonatomic, readonly) AVCaptureTorchMode torchMode;
@property (nonatomic, readonly) CGPoint focusPoint;
@property (nonatomic, readonly) CGPoint exposurePoint;
@property (assign, nonatomic) int captureFormat; //采集格式
@property (copy, nonatomic) NSString *sessionPreset; //采集格式
@property (copy, nonatomic) dispatch_queue_t captureQueue;//录制的队列

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition captureFormat:(int)captureFormat;

- (void)startCapture;

- (void)stopCapture;

/**
 采集单张照片
 */
- (void)takePhoto;

/**
 直接采集视频预览下的截图照片
 */
- (void)takeVideoPhoto;

- (void)startRecordForFilePath:(NSString *)filePath;

- (void)stopRecord;

- (void)changeCameraInputDeviceIsFront:(BOOL)isFront;
- (BOOL)setFlashMode:(AVCaptureFlashMode)flashMode;
- (BOOL)setTorchMode:(AVCaptureTorchMode)torchMode;
- (BOOL)setFocusPoint:(CGPoint)focusPoint;
- (BOOL)setExposurePoint:(CGPoint)exposurePoint;
@end
