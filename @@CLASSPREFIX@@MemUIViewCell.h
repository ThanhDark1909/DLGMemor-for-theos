//  Created by Nguyen Thanh Dat on 29/8/22.
//  Copyright © 2022 Nguyen Thanh Dat. All rights reserved.
//

#import <UIKit/UIKit.h>

#define @@CLASSPREFIX@@MemUIViewCellID      @"@@CLASSPREFIX@@MemUIViewCell"
#define @@CLASSPREFIX@@MemUIViewCellHeight  32

@protocol @@CLASSPREFIX@@MemUIViewCellDelegate <NSObject>

- (void)@@CLASSPREFIX@@MemUIViewCellModify:(NSString *)address value:(NSString *)value;
- (void)@@CLASSPREFIX@@MemUIViewCellViewMemory:(NSString *)address;

@end

@interface @@CLASSPREFIX@@MemUIViewCell : UITableViewCell

@property (nonatomic, weak) id<@@CLASSPREFIX@@MemUIViewCellDelegate> delegate;
@property (nonatomic, weak) id<UITextFieldDelegate> textFieldDelegate;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *value;
@property (nonatomic) BOOL modifying;

@end
