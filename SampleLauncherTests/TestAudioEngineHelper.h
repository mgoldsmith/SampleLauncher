//
//  TestAudioEngineHelper.h
//  SampleLauncherTests
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestAudioEngineHelper : NSObject

/**
 * Creates and configures an AVAudioEngine in manual rendering mode for testing.
 *
 * Configuration:
 * - Sample rate: 48kHz
 * - Channels: Stereo (2)
 * - Maximum frame count: 4096
 * - Manual rendering mode: Offline (no hardware I/O)
 *
 * The engine is started and ready to use. Assert will fail if engine fails to start.
 *
 * @param testCase The XCTestCase to use for assertions
 * @return A started AVAudioEngine configured for offline testing
 */
+ (AVAudioEngine *)createTestEngineWithTestCase:(XCTestCase *)testCase;

@end

NS_ASSUME_NONNULL_END
