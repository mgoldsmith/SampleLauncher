//
//  SampleSlotView.h
//  SampleLauncher
//

#import <Cocoa/Cocoa.h>

@class SampleSlot;

NS_ASSUME_NONNULL_BEGIN

@interface SampleSlotView : NSView

@property (nonatomic, copy) NSString *noteName;
@property (nonatomic, copy, nullable) NSString *sampleName;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) CGFloat progress; // 0.0 to 1.0 for progress meter

- (instancetype)initWithFrame:(NSRect)frameRect noteName:(NSString *)noteName;
- (void)updateFromSampleSlot:(SampleSlot *)sampleSlot;

@end

NS_ASSUME_NONNULL_END
