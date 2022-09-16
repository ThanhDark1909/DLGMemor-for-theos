//  Created by Nguyen Thanh Dat on 29/8/22.
//  Copyright © 2022 Nguyen Thanh Dat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "@@CLASSPREFIX@@MemUIViewDelegate.h"
#include "search_result_def.h"

#define @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_SIZE 64

#define @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MIN_ALPHA 0.5f
#define @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MAX_ALPHA 0.8f

@interface @@CLASSPREFIX@@MemUIView : UIView

@property (nonatomic) id<@@CLASSPREFIX@@MemUIViewDelegate> delegate;
@property (nonatomic) UIWindow *window;
@property (nonatomic, readonly) BOOL shouldNotBeDragged;
@property (nonatomic, readonly) BOOL expanded;

@property (nonatomic) NSInteger chainCount;
@property (nonatomic) search_result_chain_t chain;

+ (instancetype)instance;
- (void)doExpand;
- (void)doCollapse;

@end
