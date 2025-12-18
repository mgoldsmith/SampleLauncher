//
//  SampleBankView.h
//  SampleLauncher
//

#import <Cocoa/Cocoa.h>

@class SampleBank;

NS_ASSUME_NONNULL_BEGIN

@interface SampleBankView : NSView

- (instancetype)initWithFrame:(NSRect)frameRect;
- (instancetype)initWithFrame:(NSRect)frameRect capacity:(NSUInteger)capacity;

- (void)updateFromSampleBank:(SampleBank *)sampleBank;

@end

NS_ASSUME_NONNULL_END
