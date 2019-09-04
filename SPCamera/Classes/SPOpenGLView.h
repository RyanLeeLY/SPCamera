//
//  SPOpenGLView.h
//  TPFaceUSDK_Example
//
//  Created by Yao Li on 2018/6/6.
//  Copyright © 2018年 yao.li. All rights reserved.
//

#import <CoreVideo/CoreVideo.h>

@interface SPOpenGLView : UIView

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer withLandmarks:(float *)landmarks count:(int)count;

@end
