//
//  SampleBank.m
//  SampleLauncher
//

#import "SampleBank.h"
#import "SampleSlot.h"

@interface SampleBank ()
@property (nonatomic, strong) NSMutableArray<SampleSlot *> *slots;
@property (nonatomic, readwrite) NSUInteger capacity;
@end

@implementation SampleBank

- (instancetype)init {
    return [self initWithCapacity:16];
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        _capacity = capacity;
        _slots = [NSMutableArray arrayWithCapacity:capacity];

        for (NSUInteger i = 0; i < capacity; i++) {
            [_slots addObject:[[SampleSlot alloc] init]];
        }
    }
    return self;
}

- (nullable SampleSlot *)slotAtIndex:(NSUInteger)index {
    if (index >= self.capacity) {
        return nil;
    }
    return self.slots[index];
}

- (NSUInteger)count {
    NSUInteger loadedCount = 0;
    for (SampleSlot *slot in self.slots) {
        if (slot.sampleName != nil) {
            loadedCount++;
        }
    }
    return loadedCount;
}

@end
