//
//  TransportClock.h
//  SampleLauncher
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TransportClock : NSObject

@property (nonatomic, readonly) double bpm;
@property (nonatomic, readonly) NSInteger beatsPerBar;
@property (nonatomic, readonly) double sampleRate;

- (instancetype)initWithAudioEngine:(AVAudioEngine *)engine
                                bpm:(double)bpm
                       beatsPerBar:(NSInteger)beatsPerBar;

- (void)start;

// Returns AVAudioTime for the next bar boundary
- (AVAudioTime *)nextBarBoundaryTime;

// Returns current position in bars (for debugging/UI)
- (double)currentBarPosition;

@end

NS_ASSUME_NONNULL_END
