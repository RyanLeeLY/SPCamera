//
//  SPCameraRecordButton.m
//  fellow
//
//  Created by Yao Li on 2018/6/8.
//

#import "SPCameraRecordButton.h"
#import "SPCircleCounter.h"

@interface SPCameraRecordButton () <SPCircleCounterDelegate>
@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) SPCircleCounter *circleCounter;
@property (strong, nonatomic) UIView *mainView;
@end

@implementation SPCameraRecordButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _maxRecordTime = 30;
        [self addSubview:self.bgView];
        [self addSubview:self.circleCounter];
        [self addSubview:self.mainView];
        
        [self configView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recordButtonGesture:)];
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recordButtonGesture:)];
        [self addGestureRecognizer:tapGesture];
        [self addGestureRecognizer:longPressGesture];
    }
    return self;
}

- (void)dealloc {
    [self.circleCounter invalidate];
}

- (void)configView {
    [NSLayoutConstraint constraintWithItem:self.bgView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.bgView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.bgView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:90].active = YES;
    [NSLayoutConstraint constraintWithItem:self.bgView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:90].active = YES;

    [NSLayoutConstraint constraintWithItem:self.circleCounter attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.circleCounter attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.circleCounter attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:110].active = YES;
    [NSLayoutConstraint constraintWithItem:self.circleCounter attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:110].active = YES;
    
    [NSLayoutConstraint constraintWithItem:self.mainView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.mainView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.mainView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60].active = YES;
    [NSLayoutConstraint constraintWithItem:self.mainView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60].active = YES;
}

- (void)recordButtonGesture:(UIGestureRecognizer *)gesture {
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        if ([self.delegate respondsToSelector:@selector(recordButton:receiveTapGesture:)]) {
            [self.delegate recordButton:self receiveTapGesture:(UITapGestureRecognizer *)gesture];
        }
    } else if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            [self.circleCounter startWithSeconds:self.maxRecordTime];
            
            [UIView animateWithDuration:0.2 animations:^{
                self.circleCounter.alpha = 1;
                self.bgView.transform = CGAffineTransformMakeScale(11/9.f, 11/9.f);
                self.mainView.transform = CGAffineTransformMakeScale(11/9.f, 11/9.f);
            }];

        } else if (gesture.state == UIGestureRecognizerStateEnded
                   || gesture.state == UIGestureRecognizerStateCancelled) {
            [self.circleCounter stop];
            
            [self resetView];
        }
        
        if ([self.delegate respondsToSelector:@selector(recordButton:receiveLongPresssGesture:)]) {
            [self.delegate recordButton:self receiveLongPresssGesture:(UILongPressGestureRecognizer *)gesture];
        }
    }
}

- (void)resetView {
    [self.circleCounter reset];
    self.circleCounter.alpha = 0;
    self.bgView.transform = CGAffineTransformMakeScale(1, 1);
    self.mainView.transform = CGAffineTransformMakeScale(1, 1);
}

- (void)circleCounterTimeDidExpire:(SPCircleCounter *)circleCounter {
    
    [self.gestureRecognizers enumerateObjectsUsingBlock:^(__kindof UIGestureRecognizer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UILongPressGestureRecognizer class]]) {
            obj.enabled = NO;
            obj.enabled = YES;
        }
    }];
}

#pragma mark - getter
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)];
        _bgView.layer.cornerRadius = 45;
        _bgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4];
        _bgView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bgView;
}

- (SPCircleCounter *)circleCounter {
    if (!_circleCounter) {
        _circleCounter = [[SPCircleCounter alloc] initWithFrame:CGRectMake(0, 0, 110, 110)];
        [_circleCounter startWithSeconds:30];
        [_circleCounter reset];
        _circleCounter.delegate = self;
        _circleCounter.circleTimerWidth = 5;
        _circleCounter.circleBackgroundColor = [UIColor colorWithRed:1.f green:0xdc/255.f blue:0x01/255.f alpha:1];
        _circleCounter.circleColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        _circleCounter.alpha = 0;
        _circleCounter.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _circleCounter;
}

- (UIView *)mainView {
    if (!_mainView) {
        _mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _mainView.layer.cornerRadius = 30;
        _mainView.backgroundColor = [UIColor colorWithRed:1.f green:0xdc/255.f blue:0x01/255.f alpha:1];
        _mainView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _mainView;
}

@end
