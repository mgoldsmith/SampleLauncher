//
//  SampleBankView.m
//  SampleLauncher
//

#import "SampleBankView.h"
#import "SampleSlotView.h"
#import "SampleBank.h"
#import "SampleSlot.h"

// Grid configuration
static const NSUInteger kNumColumns = 4;
static const NSInteger kStartingMIDINote = 24; // C2

@interface SampleBankView ()

@property (nonatomic, strong) NSGridView *gridView;
@property (nonatomic, strong) NSArray<SampleSlotView *> *slotViews;
@property (nonatomic, assign) NSUInteger capacity;

@end

@implementation SampleBankView

- (instancetype)initWithFrame:(NSRect)frameRect {
    return [self initWithFrame:frameRect capacity:16];
}

- (instancetype)initWithFrame:(NSRect)frameRect capacity:(NSUInteger)capacity {
    self = [super initWithFrame:frameRect];
    if (self) {
        _capacity = capacity;
        [self setupGrid];

        // Observe when samples are loaded
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(samplesDidLoad:)
                                                     name:@"SamplesDidLoad"
                                                   object:nil];
    }
    return self;
}

- (void)setupGrid {
    // Calculate number of rows needed
    NSUInteger numRows = (self.capacity + kNumColumns - 1) / kNumColumns; // Ceiling division

    // Create grid view
    self.gridView = [NSGridView gridViewWithNumberOfColumns:kNumColumns rows:numRows];
    self.gridView.translatesAutoresizingMaskIntoConstraints = NO;
    self.gridView.rowSpacing = 8;
    self.gridView.columnSpacing = 8;
    [self addSubview:self.gridView];

    NSMutableArray<SampleSlotView *> *views = [NSMutableArray arrayWithCapacity:self.capacity];

    // Create sample slot views and add to grid
    for (NSUInteger slotIndex = 0; slotIndex < self.capacity; slotIndex++) {
        NSUInteger row = slotIndex / kNumColumns;
        NSUInteger col = slotIndex % kNumColumns;

        // Calculate MIDI note number
        NSInteger midiNote = kStartingMIDINote + slotIndex;
        NSString *noteName = [self noteNameForMIDINote:midiNote];

        // Create view with the correct initializer
        SampleSlotView *slotView = [[SampleSlotView alloc] initWithFrame:NSMakeRect(0, 0, 100, 80) noteName:noteName];
        slotView.translatesAutoresizingMaskIntoConstraints = NO;

        // Add explicit size constraints
        [slotView.widthAnchor constraintEqualToConstant:100].active = YES;
        [slotView.heightAnchor constraintEqualToConstant:80].active = YES;

        // Add to grid
        NSGridCell *cell = [self.gridView cellAtColumnIndex:col rowIndex:row];
        cell.contentView = slotView;

        [views addObject:slotView];
    }

    self.slotViews = [views copy];

    // Layout constraints for grid - fill the view
    [NSLayoutConstraint activateConstraints:@[
        [self.gridView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.gridView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.gridView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.gridView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

- (NSString *)noteNameForMIDINote:(NSInteger)midiNote {
    // MIDI note names
    NSArray<NSString *> *noteNames = @[@"C", @"C#", @"D", @"D#", @"E", @"F", @"F#", @"G", @"G#", @"A", @"A#", @"B"];

    NSInteger octave = (midiNote / 12);
    NSInteger noteIndex = midiNote % 12;

    return [NSString stringWithFormat:@"%@%ld", noteNames[noteIndex], (long)octave];
}

- (NSSize)intrinsicContentSize {
    // Calculate the size needed for the grid
    // Each cell is 100x80, with 8pt spacing between cells

    NSUInteger numRows = (self.capacity + kNumColumns - 1) / kNumColumns;

    CGFloat cellWidth = 100;
    CGFloat cellHeight = 80;
    CGFloat spacing = 8;

    CGFloat width = (cellWidth * kNumColumns) + (spacing * (kNumColumns - 1));
    CGFloat height = (cellHeight * numRows) + (spacing * (numRows - 1));

    return NSMakeSize(width, height);
}

- (void)updateFromSampleBank:(SampleBank *)sampleBank {
    // Log warning if capacities don't match
    if (sampleBank.capacity != self.capacity) {
        NSLog(@"Warning: SampleBank capacity (%lu) doesn't match SampleBankView capacity (%lu)",
              (unsigned long)sampleBank.capacity, (unsigned long)self.capacity);
    }

    // Update each slot view from corresponding sample slot
    NSUInteger slotsToUpdate = MIN(sampleBank.capacity, self.capacity);

    for (NSUInteger i = 0; i < slotsToUpdate; i++) {
        SampleSlot *slot = [sampleBank slotAtIndex:i];
        SampleSlotView *view = self.slotViews[i];

        if (slot && view) {
            [view updateFromSampleSlot:slot];
        }
    }
}

- (void)samplesDidLoad:(NSNotification *)notification {
    SampleBank *sampleBank = notification.object;
    [self updateFromSampleBank:sampleBank];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
