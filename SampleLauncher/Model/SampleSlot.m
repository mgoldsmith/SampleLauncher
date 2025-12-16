//
//  SampleSlot.m
//  SampleLauncher
//

#import "SampleSlot.h"

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
    [self.playerNode scheduleBuffer:self.buffer completionHandler:nil];
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

@end
