//
//  SampleBank.h
//  SampleLauncher
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class SampleSlot;
@class TransportClock;

NS_ASSUME_NONNULL_BEGIN

@interface SampleBank : NSObject

@property (nonatomic, readonly) NSUInteger capacity;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, weak, nullable) TransportClock *transportClock;

- (instancetype)init;
- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;

- (nullable SampleSlot *)slotAtIndex:(NSUInteger)index;

- (void)attachToAudioEngine:(AVAudioEngine *)engine;
- (BOOL)loadSampleAtIndex:(NSUInteger)index fromFile:(NSString *)filePath error:(NSError **)error;
- (void)stopAllSlots;

@end

NS_ASSUME_NONNULL_END
