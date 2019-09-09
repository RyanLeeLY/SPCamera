# SPCamera

[![Platform](https://img.shields.io/cocoapods/p/SPCamera.svg?style=flat)](https://cocoapods.org/pods/SPCamera)
[![Version](https://img.shields.io/cocoapods/v/SPCamera.svg?style=flat)](https://cocoapods.org/pods/SPCamera)
[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/RyanLeeLY/SPCamera/blob/master/LICENSE)
[![Gmail](https://img.shields.io/badge/Gmail-@liyaoxjtu2013-red.svg?style=flat)](mail://liyaoxjtu2013@gmail.com)

![screenshot](https://raw.githubusercontent.com/RyanLeeLY/SPCamera/master/Pics/pic0.PNG)

## Use Quickly

### Setup Camera & Preview View

```objective-c
_camera = [[SPCamera alloc] initWithCameraPosition:AVCaptureDevicePositionBack
                                         captureFormat:kCVPixelFormatType_32BGRA];
_camera.delegate = self;

_previewView = [[SPOpenGLView alloc] initWithFrame:[UIScreen mainScreen].bounds];
[self.view addSubview:_previewView];
```

### Implement Delegate

```objective-c
#pragma mark - SPCameraDelegate
- (void)camera:(SPCamera *)camera didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //  processing photo
    [self.previewView displayPixelBuffer:pixelBuffer];
}
```

### Start Capturing

```objective-c
[self.camera startCapture];
```

### Take Picture

```objective-c
[self.camera takePhoto];
```

### Take Video

```objective-c
[self.camera startRecordForFilePath:path];
// then [self.camera stopRecord];
```

## More Usage

See more usage in the Example/SPViewController. To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

SPCamera is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SPCamera'
```

## License

SPCamera is available under the MIT license. See the [LICENSE](https://github.com/RyanLeeLY/SPCamera/blob/master/LICENSE) file for more info.
