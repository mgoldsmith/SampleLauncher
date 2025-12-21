//
//  SampleSlot.m
//  SampleLauncher
//

#import "SampleSlot.h"
#import "TransportClock.h"

@interface SampleSlot ()
@property (nonatomic, strong, readwrite) AVAudioPlayerNode *playerNode;
@property (nonatomic, strong) AVAudioPCMBuffer *buffer;
@property (nonatomic, copy, readwrite, nullable) NSString *sampleName;
@property (nonatomic, strong, nullable) AVAudioTime *scheduledStartTime; // Player time when buffer is scheduled to start
@end

@implementation SampleSlot

- (instancetype)init {
    self = [super init];
    if (self) {
        _playerNode = [[AVAudioPlayerNode alloc] init];
    }
    return self;
}

- (BOOL)loadSampleFromFile:(NSString *)filePath error:(NSError **)error {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];

    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:error];
    if (!audioFile) {
        return NO;
    }

    AVAudioFrameCount frameCount = (AVAudioFrameCount)audioFile.length;
    self.buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat
                                                 frameCapacity:frameCount];
    if (![audioFile readIntoBuffer:self.buffer error:error]) {
        return NO;
    }

    self.sampleName = [[fileURL lastPathComponent] stringByDeletingPathExtension];

    return YES;
}

- (void)play {
    if (!self.buffer) {
        return;
    }

    [self.playerNode stop];
    self.scheduledStartTime = nil; // Immediate playback, no scheduled start time
    [self.playerNode scheduleBuffer:self.buffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
    [self.playerNode play];
}

- (void)stop {
    [self.playerNode stop];
    self.scheduledStartTime = nil;
}

- (void)toggle {
    self.isPlaying ? [self stop] : [self play];
}

- (BOOL)isPlaying {
    return self.playerNode.isPlaying;
}

- (void)playAtNextBarBoundary {
    if (!self.buffer || !self.transportClock) {
        NSLog(@"playAtNextBarBoundary: buffer or transportClock is nil");
        return;
    }
    [self.playerNode stop];

    AVAudioTime *nextBar = [self.transportClock nextBarBoundaryTime];

    // Start the player node FIRST to establish its timeline
    [self.playerNode play];

    // Now get the player node's current time
    AVAudioTime *playerTime = [self.playerNode playerTimeForNodeTime:nextBar];

    // Store when the buffer is scheduled to start
    self.scheduledStartTime = playerTime;

    [self.playerNode scheduleBuffer:self.buffer
                             atTime:playerTime
                            options:AVAudioPlayerNodeBufferLoops
                  completionHandler:nil];
}

- (void)toggleQuantized {
    self.isPlaying ? [self stop] : [self playAtNextBarBoundary];
}

- (CGFloat)currentProgress {
    // Return 0 if not playing or no buffer loaded
    if (!self.isPlaying || !self.buffer || self.buffer.frameLength == 0) {
        return 0.0;
    }

    // Get the last time the player rendered audio
    AVAudioTime *lastRenderTime = self.playerNode.lastRenderTime;
    if (!lastRenderTime || !lastRenderTime.isSampleTimeValid) {
        return 0.0;
    }

    // Convert to player time to get the current sample position
    AVAudioTime *playerTime = [self.playerNode playerTimeForNodeTime:lastRenderTime];
    if (!playerTime || !playerTime.isSampleTimeValid) {
        return 0.0;
    }

    // If we have a scheduled start time, check if playback has actually started yet
    if (self.scheduledStartTime && self.scheduledStartTime.isSampleTimeValid) {
        // If current time is before scheduled start, don't show progress yet
        if (playerTime.sampleTime < self.scheduledStartTime.sampleTime) {
            return 0.0;
        }

        // Calculate position relative to when the buffer actually started
        AVAudioFramePosition samplesSinceStart = playerTime.sampleTime - self.scheduledStartTime.sampleTime;
        AVAudioFramePosition bufferLength = self.buffer.frameLength;

        // Use modulo to get position within current loop (handles looping)
        AVAudioFramePosition positionInLoop = samplesSinceStart % bufferLength;

        // Convert to 0.0-1.0 range
        CGFloat progress = (CGFloat)positionInLoop / (CGFloat)bufferLength;
        return progress;
    }

    // For immediate playback (no scheduled start time), calculate from beginning
    AVAudioFramePosition samplePosition = playerTime.sampleTime;
    AVAudioFramePosition bufferLength = self.buffer.frameLength;

    // Use modulo to get position within current loop (handles looping)
    AVAudioFramePosition positionInLoop = samplePosition % bufferLength;

    // Convert to 0.0-1.0 range
    CGFloat progress = (CGFloat)positionInLoop / (CGFloat)bufferLength;

    return progress;
}

@end
