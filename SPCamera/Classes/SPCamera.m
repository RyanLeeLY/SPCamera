//
//  SPCamera.m
//  TPFaceUSDK_Example
//
//  Created by Yao Li on 2018/6/6.
//  Copyright © 2018年 yao.li. All rights reserved.
//

#import "SPCamera.h"
#import <UIKit/UIKit.h>
#import "SPCameraRecordEncoder.h"
#import <CoreMotion/CoreMotion.h>

static NSString * const kCapturingStillImage = @"capturingStillImage";

typedef enum : NSUInteger {
    CommonMode,
    PhotoWillTakeMode,
    PhotoTakeMode,
    VideoRecordMode,
    VideoRecordEndMode,
} RunMode;


@interface SPCamera()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    BOOL hasStarted;
    int _channels;//音频通道
    Float64 _samplerate;//音频采样率
    float _frameWidth;
    float _frameHeight;
}
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureSession *photoCaputureSession;

@property (strong, nonatomic) AVCaptureDeviceInput       *backCameraInput;//后置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput       *frontCameraInput;//前置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput       *audioMicInput;

@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (strong, nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic ,strong) AVCaptureStillImageOutput *photoOutput;

@property (strong, nonatomic) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) AVCaptureConnection *audioConnection;
@property (strong, nonatomic) AVCaptureDevice *camera;

@property (assign, nonatomic) CMFormatDescriptionRef audioFormat; //采集格式
@property (assign, nonatomic) AVCaptureDevicePosition cameraPosition;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (assign, atomic) UIImageOrientation imageOrientation;

@property (assign, atomic) RunMode runMode;

@property (strong, nonatomic) SPCameraRecordEncoder *recordEncoder;//录制编码
@property (copy, atomic) NSString *videoPath; //录制编码

@property (strong, atomic) UIImage  *lastImage;
@end

@implementation SPCamera

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition captureFormat:(int)captureFormat {
    if (self = [self init]) {
        self.cameraPosition = cameraPosition;
        self.captureFormat = captureFormat;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = .5;
        _cameraPosition = AVCaptureDevicePositionFront;
        _captureFormat = kCVPixelFormatType_32BGRA;
        _sessionPreset = AVCaptureSessionPresetHigh;
    }
    return self;
}

- (void)dealloc {

}

- (void)startCapture {
    if (![self.captureSession isRunning] && !hasStarted) {
        hasStarted = YES;
        if (self.motionManager.isDeviceMotionAvailable) {
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            queue.name = @"com.SPCamera.captureQueue";
            [self.motionManager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                double x = motion.gravity.x;
                double y = motion.gravity.y;
                if (x < 0) {
                    if (fabs(x) > fabs(y)) {
                        self.imageOrientation = UIImageOrientationLeft;
                    } else {
                        self.imageOrientation = UIImageOrientationUp;
                    }
                } else {
                    if (fabs(x) > fabs(y)) {
                        self.imageOrientation = UIImageOrientationRight;
                    } else {
                        self.imageOrientation = UIImageOrientationUp;
                    }
                }
            }];
        }
        [self.captureSession startRunning];
    }
}

- (void)stopCapture {
    hasStarted = NO;
    if ([self.captureSession isRunning]) {
        [self.motionManager stopDeviceMotionUpdates];
        [self.captureSession stopRunning];
    }
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = self.sessionPreset;
        
        AVCaptureDeviceInput *deviceInput = self.isFrontCamera ? self.frontCameraInput:self.backCameraInput;
        
        if ([_captureSession canAddInput:deviceInput]) {
            self.camera = deviceInput.device;
            [_captureSession addInput:deviceInput];
        }
        
        if ([_captureSession canAddInput:self.audioMicInput]) {
            [_captureSession addInput:self.audioMicInput];
        }
        
        if ([_captureSession canAddOutput:self.videoOutput]) {
            [_captureSession addOutput:self.videoOutput];
        }
        
        if ([_captureSession canAddOutput:self.audioOutput]) {
            [_captureSession addOutput:self.audioOutput];
        }
        
        if ([_captureSession canAddOutput:self.photoOutput]) {
            [_captureSession addOutput:self.photoOutput];
        }
        
        [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        if (self.videoConnection.supportsVideoMirroring && self.isFrontCamera) {
            self.videoConnection.videoMirrored = YES;
        }
        
        if (!_audioConnection) {
            _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
        }
        
        [_captureSession beginConfiguration]; // the session to which the receiver's AVCaptureDeviceInput is added.
        if ( [deviceInput.device lockForConfiguration:NULL] ) {
            [deviceInput.device setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
            [deviceInput.device unlockForConfiguration];
        }
        [_captureSession commitConfiguration];
    }
    return _captureSession;
}

- (AVCaptureSession *)photoCaputureSession {
    if (!_photoCaputureSession) {
        _photoCaputureSession = [[AVCaptureSession alloc] init];
        _photoCaputureSession.sessionPreset = AVCaptureSessionPresetPhoto;

        if ([_photoCaputureSession canAddOutput:self.photoOutput]) {
            [_photoCaputureSession addOutput:self.photoOutput];
        }
    }
    return _photoCaputureSession;
}

//后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (!_backCameraInput) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"Back camera init error");
        }
    }
    return _backCameraInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput {
    if (!_frontCameraInput) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        if (error) {
            NSLog(@"Front camera init error");
        }
    }
    return _frontCameraInput;
}

//麦克风输入
- (AVCaptureDeviceInput *)audioMicInput {
    if (_audioMicInput ==nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            
        }
    }
    return _audioMicInput;
}

//返回前置摄像头
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

//返回后置摄像头
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

//切换前后置摄像头
- (void)changeCameraInputDeviceIsFront:(BOOL)isFront {
    if (isFront) {
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.backCameraInput];
        if ([self.captureSession canAddInput:self.frontCameraInput]) {
            self.camera = self.frontCameraInput.device;
            [self.captureSession addInput:self.frontCameraInput];
        }
        self.cameraPosition = AVCaptureDevicePositionFront;
    }else {
        [self.captureSession stopRunning];
        [self.captureSession removeInput:self.frontCameraInput];
        if ([self.captureSession canAddInput:self.backCameraInput]) {
            self.camera = self.backCameraInput.device;
            [self.captureSession addInput:self.backCameraInput];
        }
        self.cameraPosition = AVCaptureDevicePositionBack;
    }
    
    AVCaptureDeviceInput *deviceInput = isFront ? self.frontCameraInput:self.backCameraInput;
    
    [self.captureSession beginConfiguration]; // the session to which the receiver's AVCaptureDeviceInput is added.
    if ( [deviceInput.device lockForConfiguration:NULL] ) {
        [deviceInput.device setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
        [deviceInput.device unlockForConfiguration];
    }
    [self.captureSession commitConfiguration];
    
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    if (self.videoConnection.supportsVideoMirroring) {
        self.videoConnection.videoMirrored = isFront;
    }
    [self.captureSession startRunning];
}

//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)camera {
    if (!_camera) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        [devices enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull device, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([device position] == self.cameraPosition) {
                self->_camera = device;
            }
        }];
    }
    return _camera;
}

- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        //输出
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setAlwaysDiscardsLateVideoFrames:YES];
        [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_captureFormat] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _videoOutput;
}

- (AVCaptureAudioDataOutput *)audioOutput {
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

- (AVCaptureStillImageOutput *)photoOutput {
    if (!_photoOutput) {
        _photoOutput = [[AVCaptureStillImageOutput alloc] init];
        [_photoOutput setOutputSettings:@{
                                          AVVideoCodecKey: AVVideoCodecJPEG,
                                          }];
    }
    return _photoOutput;
}

//录制的队列
- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_queue_create("com.SPCamera.captureQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

//视频连接
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.automaticallyAdjustsVideoMirroring =  NO;
    
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection {
    if (!_audioConnection) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

//设置采集格式
- (void)setCaptureFormat:(int)captureFormat {
    if (_captureFormat == captureFormat) {
        return;
    }
    
    _captureFormat = captureFormat;
    
    if (((NSNumber *)[[_videoOutput videoSettings] objectForKey:(id)kCVPixelBufferPixelFormatTypeKey]).intValue != captureFormat) {
        
        [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_captureFormat] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    }
}

//设置音频格式
- (void)setAudioFormat:(CMFormatDescriptionRef)audioFormat {
    const AudioStreamBasicDescription * const asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormat);
    _samplerate = asbd->mSampleRate;
    _channels = asbd->mChannelsPerFrame;
}

- (AVCaptureFlashMode)flashMode {
    if (!self.camera.hasFlash
        || !self.camera.isFlashAvailable) {
        return AVCaptureFlashModeOff;
    }
    
    return self.camera.flashMode;
}

- (BOOL)setFlashMode:(AVCaptureFlashMode)flashMode {
    if (!self.camera.hasFlash
        || !self.camera.isFlashAvailable
        || ![self.camera isFlashModeSupported:flashMode]) {
        return NO;
    }
    
    NSError *error = nil;
    if (![self.camera lockForConfiguration:&error]) {
        NSLog(@"SPCamera: Failed to set flash mode: %@", [error localizedDescription]);
        return NO;
    }
    
    self.camera.flashMode = flashMode;
    [self.camera unlockForConfiguration];
    return YES;
}

- (AVCaptureTorchMode)torchMode {
    if (!self.camera.hasTorch
        || !self.camera.isTorchAvailable) {
        return AVCaptureTorchModeOff;
    }
    
    return self.camera.torchMode;
}

- (BOOL)setTorchMode:(AVCaptureTorchMode)torchMode {
    if (!self.camera.hasTorch
        || !self.camera.isTorchAvailable
        || ![self.camera isTorchModeSupported:torchMode]) {
        return NO;
    }
    
    NSError *error = nil;
    if (![self.camera lockForConfiguration:&error]) {
        NSLog(@"SPCamera: Failed to set torch mode: %@", [error localizedDescription]);
        return NO;
    }
    
    self.camera.torchMode = torchMode;
    [self.camera unlockForConfiguration];
    return YES;
}

- (CGPoint)focusPoint {
    if (!self.camera.focusPointOfInterestSupported) {
        return CGPointMake(0.5, 0.5);
    }
    
    return self.camera.focusPointOfInterest;
}

- (BOOL)setFocusPoint:(CGPoint)focusPoint {
    if (!self.camera.focusPointOfInterestSupported) {
        return NO;
    }
    
    NSError *error = nil;
    if (![self.camera lockForConfiguration:&error]) {
        NSLog(@"SPCamera: Failed to set focus point: %@", [error localizedDescription]);
        return NO;
    }
    
    self.camera.focusPointOfInterest = focusPoint;
    self.camera.focusMode = AVCaptureFocusModeAutoFocus;
    [self.camera unlockForConfiguration];
    return YES;
}

- (CGPoint)exposurePoint {
    if (!self.camera.exposurePointOfInterestSupported) {
        return CGPointMake(0.5, 0.5);
    }
    
    return self.camera.exposurePointOfInterest;
}

- (BOOL)setExposurePoint:(CGPoint)exposurePoint {
    if (!self.camera.exposurePointOfInterestSupported) {
        return NO;
    }
    
    NSError *error = nil;
    if (![self.camera lockForConfiguration:&error]) {
        NSLog(@"SPCamera: Failed to set exposure point: %@", [error localizedDescription]);
        return NO;
    }
    self.camera.exposureMode = AVCaptureExposureModeLocked;
    self.camera.exposurePointOfInterest = exposurePoint;
    self.camera.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    
    [self.camera unlockForConfiguration];
    return YES;
}

- (BOOL)isFrontCamera {
    return self.cameraPosition == AVCaptureDevicePositionFront;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    @synchronized (self) {
        __weak typeof(self) _self = self;
        
        //    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        //    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDescription);
        
        BOOL isVideo = YES;
        if (self.videoOutput != captureOutput) {
            isVideo = NO;
        }
        if (isVideo) {
            if ([self.delegate respondsToSelector:@selector(camera:didOutputVideoSampleBuffer:)]) {
                [self.delegate camera:self didOutputVideoSampleBuffer:sampleBuffer];
            }
        }
        
        switch (self.runMode) {
            case CommonMode:
                
                break;
            case PhotoWillTakeMode: {
                if (!self.photoOutput.capturingStillImage) {
                    break;
                }
                CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                self.lastImage = [self imageFromPixelBuffer:buffer];
                break;
            }
            case PhotoTakeMode: {
                if (!isVideo) {
                    break;
                }
                self.runMode = CommonMode;
                if ([self.delegate respondsToSelector:@selector(camera:didOutputVideoFramePhotoImage:)]) {
                    if (!self.lastImage) {
                        CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                        self.lastImage = [self imageFromPixelBuffer:buffer];
                    }
                    UIImage *image = [self rotationImage:self.lastImage orientation:self.imageOrientation];
                    [self.delegate camera:self didOutputVideoFramePhotoImage:image];
                }
                break;
            }
                
            case VideoRecordMode: {
                if (self.recordEncoder == nil) {
                    if (!self.videoPath) {
                        NSDate *currentDate = [NSDate date];//获取当前时间，日期
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"YYYYMMddhhmmssSS"];
                        NSString *dateString = [dateFormatter stringFromDate:currentDate];
                        self.videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", dateString]];
                    }
                    
                    if (!isVideo
                        && _frameWidth != 0
                        && _frameHeight != 0) {
                        CMFormatDescriptionRef audioFormat = CMSampleBufferGetFormatDescription(sampleBuffer);
                        [self setAudioFormat:audioFormat];
                        self.recordEncoder = [SPCameraRecordEncoder encoderForPath:self.videoPath Height:_frameHeight width:_frameWidth channels:_channels samples:_samplerate];
                    } else {
                        CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                        _frameWidth = CVPixelBufferGetWidth(buffer);
                        _frameHeight = CVPixelBufferGetHeight(buffer);
                        break;
                    }
                }
                CFRetain(sampleBuffer);
                // 进行数据编码
                [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
                CFRelease(sampleBuffer);
                break;
            }
                
            case VideoRecordEndMode: {
                self.runMode = CommonMode;
                
                if (self.recordEncoder.writer.status == AVAssetWriterStatusUnknown) {
                    self.recordEncoder = nil;
                } else {
                    [self.recordEncoder finishWithCompletionHandler:^{
                        __strong typeof(_self) self = _self;
                        NSString *path = self.recordEncoder.path;
                        self.recordEncoder = nil;
                        if ([self.delegate respondsToSelector:@selector(camera:didVideoStopOutputInFilePath:)]) {
                            [self.delegate camera:self didVideoStopOutputInFilePath:path];
                        }
                    }];
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)takePhoto {
    __weak typeof(self) _self = self;
    [self _takePhotoWithImageOutPut:self.photoOutput completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        __strong typeof(_self) self = _self;
        if ([self.delegate respondsToSelector:@selector(camera:didOutputPhotoImage:)]) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            [self.delegate camera:self didOutputPhotoImage:[UIImage imageWithData:imageData]];
        }
    }];
}

- (void)takeVideoPhoto {
    self.lastImage = nil;
    self.runMode = PhotoWillTakeMode;
    __weak typeof(self) _self = self;
    [self _takePhotoWithImageOutPut:self.photoOutput completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        __strong typeof(_self) self = _self;
        self.runMode = PhotoTakeMode;
    }];
}

- (void)_takePhotoWithImageOutPut:(AVCaptureStillImageOutput *)output completionHandler:(void (^)(CMSampleBufferRef _Nullable imageDataSampleBuffer, NSError * _Nullable error))handler {
    AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
    if (!connection) {
        self.runMode = CommonMode;
        NSLog(@"TakePhoto can not get capture connection");
        return;
    }
    if (connection.supportsVideoOrientation) {
        if (self.imageOrientation == UIImageOrientationRight) {
            [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        } else if (self.imageOrientation == UIImageOrientationLeft) {
            [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        } else if (self.imageOrientation == UIImageOrientationUp) {
            [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
    }
    if (connection.supportsVideoMirroring && self.isFrontCamera) {
        [connection setVideoMirrored:self.videoConnection.videoMirrored];
    }
    [self.photoOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
}

//开始录像
- (void)startRecordForFilePath:(NSString *)filePath {
    self.videoPath = filePath;
    self.runMode = VideoRecordMode;
}

//停止录像
- (void)stopRecord {
    self.runMode = VideoRecordEndMode;
}

#pragma mark - Utility
- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    
    CVPixelBufferLockBaseAddress(pixelBufferRef, 0);
    
    CGFloat SW = [UIScreen mainScreen].bounds.size.width;
    CGFloat SH = [UIScreen mainScreen].bounds.size.height;
    
    float width = CVPixelBufferGetWidth(pixelBufferRef);
    float height = CVPixelBufferGetHeight(pixelBufferRef);
    
    float dw = width / SW;
    float dh = height / SH;
    
    float cropW = width;
    float cropH = height;
    
    if (dw > dh) {
        cropW = SW * dh;
    } else {
        cropH = SH * dw;
    }
    
    CGFloat cropX = (width - cropW) * 0.5;
    CGFloat cropY = (height - cropH) * 0.5;
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBufferRef];
    
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(cropX, cropY,
                                                 cropW,
                                                 cropH)];
    
    UIImage *image = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    CVPixelBufferUnlockBaseAddress(pixelBufferRef, 0);
    return image;
}

- (UIImage *)rotationImage:(UIImage *)image orientation:(UIImageOrientation)orientation {
    if (orientation == UIImageOrientationUp) {
        return image;
    }
    CGSize size = image.size;
    UIGraphicsBeginImageContext(CGSizeMake(size.height, size.width));
    UIImage *newImage = [UIImage imageWithCGImage:[image CGImage] scale:1.0 orientation:orientation];
    [newImage drawInRect:CGRectMake(0,0,size.height ,size.width)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end

