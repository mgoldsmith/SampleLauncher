//
//  SampleSlotView.m
//  SampleLauncher
//

#import "SampleSlotView.h"
#import "SampleSlot.h"

@interface SampleSlotView ()
@property (nonatomic, strong) NSTextField *noteLabel;
@property (nonatomic, strong) NSTextField *sampleLabel;
@property (nonatomic, strong) CALayer *progressLayer;
@end

@implementation SampleSlotView

- (instancetype)initWithFrame:(NSRect)frameRect noteName:(NSString *)noteName {
    self = [super initWithFrame:frameRect];
    if (self) {
        _noteName = [noteName copy];
        _isPlaying = NO;
        _progress = 0.0;

        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.wantsLayer = YES;

    // Progress layer (behind everything)
    self.progressLayer = [CALayer layer];
    self.progressLayer.frame = CGRectMake(0, 0, 0, self.bounds.size.height);
    [self.layer addSublayer:self.progressLayer];

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

- (void)setProgress:(CGFloat)progress {
    _progress = MAX(0.0, MIN(1.0, progress));
    [self updateProgressLayer];
}

- (void)updateAppearance {
    if (self.isPlaying) {
        // Playing state - use system accent color
        self.layer.backgroundColor = [[NSColor controlAccentColor] CGColor];
        self.noteLabel.textColor = [NSColor whiteColor];
        self.sampleLabel.textColor = [NSColor colorWithWhite:1.0 alpha:0.9];
        self.progressLayer.backgroundColor = [[NSColor colorWithWhite:1.0 alpha:0.2] CGColor];
    } else {
        // Default state - light gray with subtle border
        self.layer.backgroundColor = [[NSColor controlBackgroundColor] CGColor];
        self.noteLabel.textColor = [NSColor labelColor];
        self.sampleLabel.textColor = [NSColor secondaryLabelColor];
        self.progressLayer.backgroundColor = [[NSColor clearColor] CGColor];
    }

    // Rounded corners
    self.layer.cornerRadius = 8.0;

    // Subtle border
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [[NSColor separatorColor] CGColor];

    [self updateProgressLayer];
}

- (void)updateProgressLayer {
    CGFloat width = self.bounds.size.width * self.progress;
    self.progressLayer.frame = CGRectMake(0, 0, width, self.bounds.size.height);
    self.progressLayer.cornerRadius = self.layer.cornerRadius;
}

- (void)layout {
    [super layout];
    [self updateProgressLayer];
}

- (void)updateFromSampleSlot:(SampleSlot *)sampleSlot {
    self.sampleSlot = sampleSlot;
    self.sampleName = sampleSlot.sampleName;
    self.isPlaying = sampleSlot.isPlaying;
}

- (void)mouseDown:(NSEvent *)event {
    if (self.sampleSlot) {
        [self.sampleSlot toggle];
        // Update UI immediately for responsiveness
        self.isPlaying = self.sampleSlot.isPlaying;
    }
}

@end
