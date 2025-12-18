//
//  SampleBankView.h
//  SampleLauncher
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleBankView : NSView

- (instancetype)initWithFrame:(NSRect)frameRect;
- (instancetype)initWithFrame:(NSRect)frameRect capacity:(NSUInteger)capacity;

@end

NS_ASSUME_NONNULL_END
