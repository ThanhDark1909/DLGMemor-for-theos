//  Created by Nguyen Thanh Dat on 29/8/22.
//  Copyright © 2022 Nguyen Thanh Dat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class @@CLASSPREFIX@@MemUIView;

@interface UIWindow (@@CLASSPREFIX@@MemUI)

- (BOOL)dragging;
- (void)setDragging:(BOOL)dragging;
- (CGPoint)startPosition;
- (void)setStartPosition:(CGPoint)pt;
- (@@CLASSPREFIX@@MemUIView *)@@CLASSPREFIX@@MemUIView;
- (void)set@@CLASSPREFIX@@MemUIView:(@@CLASSPREFIX@@MemUIView *)view;
- (void)handleGesture:(UIPanGestureRecognizer *)sender;
- (void)handleTTTapGesture:(UIPanGestureRecognizer *)sender;

@end
