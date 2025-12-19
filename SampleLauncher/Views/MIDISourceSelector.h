//
//  MIDISourceSelector.h
//  SampleLauncher
//
//  Manages MIDI source selection UI
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MIDISourceSelector : NSObject

@property (nonatomic, strong, readonly) NSPopUpButton *popupButton;

- (instancetype)init;
- (void)refreshSources;

@end

NS_ASSUME_NONNULL_END
