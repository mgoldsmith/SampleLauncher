//
//  SampleSlotView.m
//  SampleLauncher
//

#import "SampleSlotView.h"
#import "SampleSlot.h"

@interface SampleSlotView ()
@property (nonatomic, strong) NSTextField *noteLabel;
@property (nonatomic, strong) NSTextField *sampleLabel;
@end

@implementation SampleSlotView

- (instancetype)initWithFrame:(NSRect)frameRect noteName:(NSString *)noteName {
    self = [super initWithFrame:frameRect];
    if (self) {
        _noteName = [noteName copy];
        _isPlaying = NO;

        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.wantsLayer = YES;

    // Note name label (centered, larger)
    self.noteLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.noteLabel.stringValue = self.noteName;
    self.noteLabel.editable = NO;
    self.noteLabel.selectable = NO;
    self.noteLabel.bordered = NO;
    self.noteLabel.backgroundColor = [NSColor clearColor];
    self.noteLabel.font = [NSFont systemFontOfSize:18 weight:NSFontWeightSemibold];
    self.noteLabel.alignment = NSTextAlignmentCenter;
    self.noteLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.noteLabel];

    // Sample name label (below note name, smaller)
    self.sampleLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.sampleLabel.stringValue = @"";
    self.sampleLabel.editable = NO;
    self.sampleLabel.selectable = NO;
    self.sampleLabel.bordered = NO;
    self.sampleLabel.backgroundColor = [NSColor clearColor];
    self.sampleLabel.font = [NSFont systemFontOfSize:11];
    self.sampleLabel.alignment = NSTextAlignmentCenter;
    self.sampleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.sampleLabel];

    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.noteLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.noteLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-10],
        [self.noteLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor constant:-16],

        [self.sampleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.sampleLabel.topAnchor constraintEqualToAnchor:self.noteLabel.bottomAnchor constant:6],
        [self.sampleLabel.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor constant:-16],
    ]];

    [self updateAppearance];
}

- (void)setSampleName:(NSString *)sampleName {
    _sampleName = [sampleName copy];
    self.sampleLabel.stringValue = sampleName ?: @"";
}

- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    [self updateAppearance];
}

- (void)updateAppearance {
    if (self.isPlaying) {
        // Playing state - use system accent color
        self.layer.backgroundColor = [[NSColor controlAccentColor] CGColor];
        self.noteLabel.textColor = [NSColor whiteColor];
        self.sampleLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.9];
    } else {
        // Default state - light gray with subtle border
        self.layer.backgroundColor = [[NSColor controlBackgroundColor] CGColor];
        self.noteLabel.textColor = [NSColor labelColor];
        self.sampleLabel.textColor = [NSColor secondaryLabelColor];
    }

    // Rounded corners
    self.layer.cornerRadius = 8.0;

    // Subtle border
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [[NSColor separatorColor] CGColor];
}

- (void)layout {
    [super layout];
}

- (void)updateFromSampleSlot:(SampleSlot *)sampleSlot {
    self.sampleSlot = sampleSlot;
    self.sampleName = sampleSlot.sampleName;
    self.isPlaying = sampleSlot.isPlaying;
}

- (void)mouseDown:(NSEvent *)event {
    if (self.sampleSlot) {
        [self.sampleSlot toggleQuantized];
        // Update UI immediately for responsiveness
        self.isPlaying = self.sampleSlot.isPlaying;
    }
}

@end
