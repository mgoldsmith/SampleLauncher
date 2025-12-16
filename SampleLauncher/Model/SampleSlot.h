//
//  SampleSlot.h
//  SampleLauncher
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleSlot : NSObject

@property (nonatomic, strong, readonly) AVAudioPlayerNode *playerNode;
@property (nonatomic, copy, readonly, nullable) NSString *sampleName;
@property (nonatomic, readonly) BOOL isPlaying;

- (instancetype)init;

- (BOOL)loadSampleFromFile:(NSString *)filePath error:(NSError **)error;

- (void)play;
- (void)stop;
- (void)toggle;

@end

NS_ASSUME_NONNULL_END
