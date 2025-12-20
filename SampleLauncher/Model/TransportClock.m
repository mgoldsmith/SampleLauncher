//
//  TransportClock.m
//  SampleLauncher
//

#import "TransportClock.h"

@interface TransportClock ()
@property (nonatomic, weak) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioTime *startTime;
@property (nonatomic, readwrite) double bpm;
@property (nonatomic, readwrite) NSInteger beatsPerBar;
@property (nonatomic, readwrite) double sampleRate;
@end

@implementation TransportClock

- (instancetype)initWithAudioEngine:(AVAudioEngine *)engine
                                bpm:(double)bpm
                       beatsPerBar:(NSInteger)beatsPerBar {
    self = [super init];
    if (self) {
        _engine = engine;
        _bpm = bpm;
        _beatsPerBar = beatsPerBar;
    }
    return self;
}

- (void)start {
    // Capture current audio time as anchor point
    AVAudioTime *now = [self.engine.outputNode lastRenderTime];
    self.startTime = now;
    self.sampleRate = now.sampleRate;

    if (now) {
        NSLog(@"TransportClock started:");
        NSLog(@"  startTime.sampleTime: %lld", self.startTime.sampleTime);
        NSLog(@"  sampleRate: %.0f Hz", self.sampleRate);
        NSLog(@"  BPM: %.1f", self.bpm);
    } else {
        NSLog(@"WARNING: TransportClock started but lastRenderTime is nil!");
    }
}

- (AVAudioTime *)nextBarBoundaryTime {
    AVAudioTime *now = [self.engine.outputNode lastRenderTime];

    if (!now) {
        NSLog(@"WARNING: lastRenderTime is nil!");
        return nil;
    }

    // Calculate samples per bar
    double samplesPerBeat = (60.0 / self.bpm) * self.sampleRate;
    double samplesPerBar = samplesPerBeat * self.beatsPerBar;

    // Calculate elapsed samples since start
    AVAudioFramePosition elapsedSamples = now.sampleTime - self.startTime.sampleTime;

    // Calculate current bar position (as floating point)
    double currentBarPosition = (double)elapsedSamples / samplesPerBar;

    // Round up to next bar
    AVAudioFramePosition nextBarSample = (AVAudioFramePosition)(ceil(currentBarPosition) * samplesPerBar);

    // Convert to absolute sample time
    AVAudioFramePosition absoluteNextBar = self.startTime.sampleTime + nextBarSample;

    NSLog(@"TransportClock DEBUG:");
    NSLog(@"  now.sampleTime: %lld", now.sampleTime);
    NSLog(@"  startTime.sampleTime: %lld", self.startTime.sampleTime);
    NSLog(@"  elapsedSamples: %lld", elapsedSamples);
    NSLog(@"  samplesPerBar: %.2f", samplesPerBar);
    NSLog(@"  currentBarPosition: %.4f bars", currentBarPosition);
    NSLog(@"  nextBarSample (relative): %lld", nextBarSample);
    NSLog(@"  absoluteNextBar: %lld", absoluteNextBar);
    NSLog(@"  samples until next bar: %lld", absoluteNextBar - now.sampleTime);

    return [AVAudioTime timeWithSampleTime:absoluteNextBar atRate:self.sampleRate];
}

- (double)currentBarPosition {
    AVAudioTime *now = [self.engine.outputNode lastRenderTime];

    // Calculate samples per bar
    double samplesPerBeat = (60.0 / self.bpm) * self.sampleRate;
    double samplesPerBar = samplesPerBeat * self.beatsPerBar;

    // Calculate elapsed samples since start
    AVAudioFramePosition elapsedSamples = now.sampleTime - self.startTime.sampleTime;

    // Return current position in bars
    return (double)elapsedSamples / samplesPerBar;
}

@end
