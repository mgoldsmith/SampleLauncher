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
@property (nonatomic) double samplesPerBeat;
@property (nonatomic) double samplesPerBar;
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
    self.sampleRate = 48000.0; // Assume 48khz stock samples for purposes of this coding challenge
    self.samplesPerBeat = (60.0 / self.bpm) * self.sampleRate;
    self.samplesPerBar = self.samplesPerBeat * self.beatsPerBar;

    if (!now) {
        NSLog(@"WARNING: TransportClock started but lastRenderTime is nil!");
    }
}

- (AVAudioTime *)nextBarBoundaryTime {
    // Calculate current bar position (as floating point)
    double currentBarPosition = [self currentBarPosition];
    
    // Round up to next bar
    AVAudioFramePosition nextBarSample = (AVAudioFramePosition)(ceil(currentBarPosition) * self.samplesPerBar);

    // Convert to absolute sample time
    AVAudioFramePosition absoluteNextBar = self.startTime.sampleTime + nextBarSample;

    return [AVAudioTime timeWithSampleTime:absoluteNextBar atRate:self.sampleRate];
}

- (double)currentBarPosition {
    AVAudioTime *now = [self.engine.outputNode lastRenderTime];
    if (!now) {
        NSLog(@"WARNING: lastRenderTime is nil!");
    }

    // Calculate elapsed samples since start
    AVAudioFramePosition elapsedSamples = now.sampleTime - self.startTime.sampleTime;

    // Return current position in bars
    return (double)elapsedSamples / self.samplesPerBar;
}

@end
