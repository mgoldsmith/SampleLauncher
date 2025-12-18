//
//  AppDelegate.h
//  SampleLauncher
//
//  Created by Matthew Goldsmith on 12/16/25.
//

#import <Cocoa/Cocoa.h>

@class SampleBank;

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong, readonly) SampleBank *sampleBank;

@end

NS_ASSUME_NONNULL_END

