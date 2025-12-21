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
    [self.playerNode scheduleBuffer:self.buffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
    [self.playerNode play];
}

- (void)stop {
    [self.playerNode stop];
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

    if (!nextBar) {
        NSLog(@"playAtNextBarBoundary: nextBar is nil!");
        return;
    }

    // Start the player node FIRST to establish its timeline
    [self.playerNode play];

    // Now get the player node's current time
    AVAudioTime *playerTime = [self.playerNode playerTimeForNodeTime:nextBar];

    if (playerTime) {
        [self.playerNode scheduleBuffer:self.buffer
                                 atTime:playerTime
                                options:AVAudioPlayerNodeBufferLoops
                      completionHandler:nil];
    } else {
        [self.playerNode scheduleBuffer:self.buffer
                                 atTime:nextBar
                                options:AVAudioPlayerNodeBufferLoops
                      completionHandler:nil];
    }
}

- (void)toggleQuantized {
    self.isPlaying ? [self stop] : [self playAtNextBarBoundary];
}

@end
