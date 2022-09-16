//  Created by Nguyen Thanh Dat on 29/8/22.
//  Copyright © 2022 Nguyen Thanh Dat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class @@CLASSPREFIX@@MemUIView;

typedef enum : NSUInteger {
    @@CLASSPREFIX@@MemValueTypeUnsignedByte,
    @@CLASSPREFIX@@MemValueTypeSignedByte,
    @@CLASSPREFIX@@MemValueTypeUnsignedShort,
    @@CLASSPREFIX@@MemValueTypeSignedShort,
    @@CLASSPREFIX@@MemValueTypeUnsignedInt,
    @@CLASSPREFIX@@MemValueTypeSignedInt,
    @@CLASSPREFIX@@MemValueTypeUnsignedLong,
    @@CLASSPREFIX@@MemValueTypeSignedLong,
    @@CLASSPREFIX@@MemValueTypeFloat,
    @@CLASSPREFIX@@MemValueTypeDouble,
} @@CLASSPREFIX@@MemValueType;

typedef enum : NSUInteger {
    @@CLASSPREFIX@@MemComparisonLT, // <
    @@CLASSPREFIX@@MemComparisonLE, // <=
    @@CLASSPREFIX@@MemComparisonEQ, // =
    @@CLASSPREFIX@@MemComparisonGE, // >=
    @@CLASSPREFIX@@MemComparisonGT, // >
} @@CLASSPREFIX@@MemComparison;

@protocol @@CLASSPREFIX@@MemUIViewDelegate <NSObject>

@optional
- (void)@@CLASSPREFIX@@MemUILaunched:(@@CLASSPREFIX@@MemUIView *)view;
- (void)@@CLASSPREFIX@@MemUISearchValue:(NSString *)value type:(@@CLASSPREFIX@@MemValueType)type comparison:(@@CLASSPREFIX@@MemComparison)comparison;
- (void)@@CLASSPREFIX@@MemUIModifyValue:(NSString *)value address:(NSString *)address type:(@@CLASSPREFIX@@MemValueType)type;
- (void)@@CLASSPREFIX@@MemUIRefresh;
- (void)@@CLASSPREFIX@@MemUIReset;
- (NSString *)@@CLASSPREFIX@@MemUIMemory:(NSString *)address size:(NSString *)size;

@end
