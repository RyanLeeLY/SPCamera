//
//  SPCameraRecordButton.h
//  fellow
//
//  Created by Yao Li on 2018/6/8.
//

#import <UIKit/UIKit.h>

@class SPCameraRecordButton;

@protocol SPCameraRecordButtonDelegate <NSObject>
- (void)recordButton:(SPCameraRecordButton *)button receiveTapGesture:(UITapGestureRecognizer *)gesture;
- (void)recordButton:(SPCameraRecordButton *)button receiveLongPresssGesture:(UILongPressGestureRecognizer *)gesture;
@end

@interface SPCameraRecordButton : UIButton
@property (assign, nonatomic) NSInteger maxRecordTime;
@property (weak, nonatomic) id<SPCameraRecordButtonDelegate> delegate;
@end
