//
//  SPCircleCounter.m
//  fellow
//
//  Created by Yao Li on 2018/6/8.
//


#import "SPCircleCounter.h"

#define TPF_SECONDS_ADJUSTMENT 1000
#define TPF_TIMER_INTERVAL .015 // ~60 FPS

@interface SPCircleCounter()

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *lastStartTime;

@property (assign, nonatomic) NSTimeInterval totalTime;

@property (assign, nonatomic) NSTimeInterval completedTimeUpToLastStop;

@property (strong, nonatomic) CADisplayLink *displayLink;

@end

@implementation SPCircleCounter

#pragma mark - Public methods

- (void)baseInit {
    self.backgroundColor = [UIColor clearColor];
    
    self.circleColor = TPF_CIRCLE_COLOR_DEFAULT;
    self.circleBackgroundColor = TPF_CIRCLE_BACKGROUND_COLOR_DEFAULT;
    self.circleFillColor = TPF_CIRCLE_FILL_COLOR_DEFAULT;
    self.circleTimerWidth = TPF_CIRCLE_TIMER_WIDTH;
    
    [self setupTimerLabel];
    self.timerLabelHidden = YES;
    self.hidesTimerLabelWhenFinished = YES;
    
    self.completedTimeUpToLastStop = 0;
    _elapsedTime = 0;
}

- (void)dealloc {

}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self baseInit];
    }
    
    return self;
}

- (void)startWithSeconds:(NSInteger)seconds {
    
    [SPCircleCounter validateInputTime:seconds];
    
    self.totalTime = seconds;
    self.displayLink.paused = NO;
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:TPF_TIMER_INTERVAL
//                                                  target:self
//                                                selector:@selector(timerFired)
//                                                userInfo:nil
//                                                 repeats:YES];
    
    _isRunning = YES;
    _didStart = YES;
    _didFinish = NO;
    
    self.lastStartTime = [NSDate dateWithTimeIntervalSinceNow:0];
    self.completedTimeUpToLastStop = 0;
    _elapsedTime = 0;
    
    _timerLabel.hidden = self.timerLabelHidden;
    
    [self.timer fire];
}

- (void)updateElapsedTime:(NSTimeInterval)value {
    if (_isRunning) {
        return;
    }
    
    _elapsedTime = value;
    self.completedTimeUpToLastStop = value;
    
    // Check if timer has expired.
    if (self.elapsedTime > self.totalTime) {
        [self timerCompleted];
    }
    
    _timerLabel.text = [NSString stringWithFormat:@"%li", (long)ceil(_totalTime - _elapsedTime)];
    
    [self setNeedsDisplay];
}

- (void)timerFired {
    if (!_isRunning) {
        return;
    }
    
    _elapsedTime = (self.completedTimeUpToLastStop +
                    [[NSDate date] timeIntervalSinceDate:self.lastStartTime]);
    
    // Check if timer has expired.
    if (self.elapsedTime > self.totalTime) {
        [self timerCompleted];
    }
    
    _timerLabel.text = [NSString stringWithFormat:@"%li", (long)ceil(_totalTime - _elapsedTime)];
    
    [self setNeedsDisplay];
}

- (void)resume {
    _isRunning = YES;
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    self.lastStartTime = now;
    [self.timer setFireDate:now];
}

- (void)stop {
    _isRunning = NO;
    
    self.completedTimeUpToLastStop += [[NSDate date] timeIntervalSinceDate:self.lastStartTime];
    _elapsedTime = self.completedTimeUpToLastStop;
    
//    [self.timer setFireDate:[NSDate distantFuture]];
    self.displayLink.paused = YES;
}

- (void)reset {
//    [self.timer invalidate];
//    self.timer = nil;
    self.displayLink.paused = YES;

    _elapsedTime = 0;
    _isRunning = NO;
    _didStart = NO;
    _didFinish = NO;
}

- (void)invalidate {
    self.displayLink.paused = YES;
    [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink = nil;
}

- (void)setTimerLabelHidden:(BOOL)timerLabelHidden {
    _timerLabelHidden = timerLabelHidden;
    
    [_timerLabel setHidden:timerLabelHidden];
}

#pragma mark - Private methods

+ (void)validateInputTime:(NSInteger)time {
    if (time < 1) {
        [NSException raise:@"TPFInvalidTime"
                    format:@"inputted timer length, %li, must be a positive integer", (long)time];
    }
}

- (void)setupTimerLabel {
    _timerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _timerLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_timerLabel];
    
    _timerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(_timerLabel);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_timerLabel]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_timerLabel]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
}

- (void)timerCompleted {
    [self.timer invalidate];
    
    _isRunning = NO;
    _didFinish = YES;
    
    _elapsedTime = self.totalTime;
    
    _timerLabel.hidden = self.hidesTimerLabelWhenFinished;
    
    if ([self.delegate respondsToSelector:@selector(circleCounterTimeDidExpire:)]) {
        [self.delegate circleCounterTimeDidExpire:self];
    }
}

- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerFired)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        if (@available(iOS 10.0, *)) {
            _displayLink.preferredFramesPerSecond = 60;
        } else {
            _displayLink.frameInterval = 2;
        }
        _displayLink.paused = YES;
    }
    return _displayLink;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat radius = CGRectGetWidth(rect)/2.0f - self.circleTimerWidth/2.0f;
    CGFloat angleOffset = M_PI_2;
    CGFloat startAngle = (((CGFloat)self.elapsedTime) / (CGFloat)self.totalTime)*M_PI*2;
    if (!self.isRunning && !self.didStart && !self.didFinish) {
        startAngle = 0;
    }
    
    CGContextSetLineWidth(context, self.circleTimerWidth);
    CGContextBeginPath(context);
    CGContextAddArc(context,
                    CGRectGetMidX(rect), CGRectGetMidY(rect),
                    radius,
                    0,
                    2*M_PI,
                    0);
    CGContextSetFillColorWithColor(context, [self.circleFillColor CGColor]);
    CGContextFillPath(context);
    
    CGContextSetLineWidth(context, self.circleTimerWidth);
    CGContextBeginPath(context);
    CGContextAddArc(context,
                    CGRectGetMidX(rect), CGRectGetMidY(rect),
                    radius,
                    -angleOffset,
                    startAngle - angleOffset,
                    0);
    CGContextSetStrokeColorWithColor(context, [self.circleBackgroundColor CGColor]);
    CGContextStrokePath(context);
    
//    CGContextBeginPath(context);
    CGContextAddArc(context,
                    CGRectGetMidX(rect), CGRectGetMidY(rect),
                    radius,
                    startAngle - angleOffset,
                    2*M_PI - angleOffset,
                    0);
    CGContextSetStrokeColorWithColor(context, [self.circleColor CGColor]);
    CGContextStrokePath(context);
}

@end
