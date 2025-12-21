//
//  SampleSlot.h
//  SampleLauncher
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TransportClock;

@interface SampleSlot : NSObject

@property (nonatomic, strong, readonly) AVAudioPlayerNode *playerNode;
@property (nonatomic, copy, readonly, nullable) NSString *sampleName;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, weak) TransportClock *transportClock;

- (instancetype)init;

- (BOOL)loadSampleFromFile:(NSString *)filePath error:(NSError **)error;

- (void)play;
- (void)stop;
- (void)toggle;

// Quantized playback methods
- (void)playAtNextBarBoundary;
- (void)toggleQuantized;

@end

NS_ASSUME_NONNULL_END
