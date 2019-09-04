//
//  SPCameraRecordEncoder.h
//  TPFaceUSDK_Example
//
//  Created by Yao Li on 2018/6/6.
//  Copyright © 2018年 yao.li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  写入并编码视频的的类
 */
@interface SPCameraRecordEncoder : NSObject

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, strong) AVAssetWriter *writer;//媒体写入对象
/**
 *  SPCameraRecordEncoder遍历构造器的
 *
 *  @param path 媒体存发路径
 *  @param cy   视频分辨率的高
 *  @param cx   视频分辨率的宽
 *
 *  @return SPCameraRecordEncoder的实体
 */
+ (instancetype)encoderForPath:(NSString*)path Height:(NSInteger)cy width:(NSInteger)cx channels:(int)ch samples:(Float64)rate;

/**
 *  初始化方法
 *
 *  @param path 媒体存发路径
 *  @param cy   视频分辨率的高
 *  @param cx   视频分辨率的宽
 *
 *  @return SPCameraRecordEncoder的实体
 */
- (instancetype)initPath:(NSString*)path Height:(NSInteger)cy width:(NSInteger)cx channels:(int)ch samples:(Float64)rate;

/**
 *  完成视频录制时调用
 *
 *  @param handler 完成的回掉block
 */
- (void)finishWithCompletionHandler:(void (^)(void))handler;

/**
 *  通过这个方法写入数据
 *
 *  @param sampleBuffer 写入的数据
 *
 *  @return 写入是否成功
 */
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;

@end
