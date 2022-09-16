//  Created by Nguyen Thanh Dat on 29/8/22.
//  Copyright © 2022 Nguyen Thanh Dat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIWindow+@@CLASSPREFIX@@MemUI.h"
#import "@@CLASSPREFIX@@MemUIViewDelegate.h"

@interface @@CLASSPREFIX@@MemUI : NSObject

+ (void)add@@CLASSPREFIX@@MemUIView:(id<@@CLASSPREFIX@@MemUIViewDelegate>)delegate;
+ (void)add@@CLASSPREFIX@@MemUIViewToWindow:(UIWindow *)window withDelegate:(id<@@CLASSPREFIX@@MemUIViewDelegate>)delegate;
+ (void)remove@@CLASSPREFIX@@MemUIView;

@end
