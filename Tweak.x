//
//  Tweak.x
//  @@CLASSPREFIX@@Memor
//
//  Created by Nguyen Thanh Dat on 29/8/22.
//  Copyright © 2022 Nguyen Thanh Dat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <@@CLASSPREFIX@@MemUIViewDelegate.h>
#import "@@CLASSPREFIX@@MemUI.h"
#import "@@CLASSPREFIX@@MemUIView.h"
#import "@@CLASSPREFIX@@MemUIViewCell.h"
#import "@@CLASSPREFIX@@MemEntry.h"
#import "@@CLASSPREFIX@@Mem.h"
#include "mem.h"
#import "UIWindow+@@CLASSPREFIX@@MemUI.h"
#import <objc/runtime.h>


@implementation @@CLASSPREFIX@@MemUI

+ (void)add@@CLASSPREFIX@@MemUIView:(id<@@CLASSPREFIX@@MemUIViewDelegate>)delegate {
    UIApplication *application = [UIApplication sharedApplication];
    if (application) {
        [@@CLASSPREFIX@@MemUI add@@CLASSPREFIX@@MemUIViewToWindow:application.keyWindow withDelegate:delegate];
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [@@CLASSPREFIX@@MemUI add@@CLASSPREFIX@@MemUIView:delegate];
    });
}

+ (void)add@@CLASSPREFIX@@MemUIViewToWindow:(UIWindow *)window withDelegate:(id<@@CLASSPREFIX@@MemUIViewDelegate>)delegate{
    CGRect frame = CGRectMake(0, 100, @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_SIZE, @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_SIZE);
    @@CLASSPREFIX@@MemUIView *view = [@@CLASSPREFIX@@MemUIView instance];
    view.delegate = delegate;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.autoresizingMask = UIViewAutoresizingNone;
    view.frame = frame;
    view.alpha = 0.5f;
    [window addSubview:view];
    [window set@@CLASSPREFIX@@MemUIView:view];
    
    NSArray *gestures = view.gestureRecognizers;
    if (gestures == nil || gestures.count == 0) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:window action:@selector(handleGesture:)];
        [view addGestureRecognizer:pan];
        
        UITapGestureRecognizer *tttap = [[UITapGestureRecognizer alloc] initWithTarget:window action:@selector(handleTTTapGesture:)];
        tttap.numberOfTapsRequired = 3;
        tttap.numberOfTouchesRequired = 3;
        [window addGestureRecognizer:tttap];
    }
    
    if ([delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUILaunched:)]) {
        [delegate @@CLASSPREFIX@@MemUILaunched:view];
    }
}

+ (void)remove@@CLASSPREFIX@@MemUIView {
    @@CLASSPREFIX@@MemUIView *view = [@@CLASSPREFIX@@MemUIView instance];
    if (view.expanded) [view doCollapse];
    NSArray *gestures = view.gestureRecognizers;
    for (UIGestureRecognizer *gesture in gestures) {
        [view removeGestureRecognizer:gesture];
    }
    [view removeFromSuperview];
}

@end

#define MaxResultCount  500

@interface @@CLASSPREFIX@@MemUIView () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, @@CLASSPREFIX@@MemUIViewCellDelegate> {
    search_result_t *chainArray;
}

@property (nonatomic) UIButton *btnConsole;
@property (nonatomic) UITapGestureRecognizer *tapGesture;

@property (nonatomic) CGRect rcCollapsedFrame;
@property (nonatomic) CGRect rcExpandedFrame;

@property (nonatomic) UIView *vContent;
@property (nonatomic) UILabel *lblType;
@property (nonatomic) UIView *vSearch;
@property (nonatomic) UITextField *tfValue;
@property (nonatomic) UIButton *btnSearch;

@property (nonatomic) UIView *vOption;
@property (nonatomic) UISegmentedControl *scComparison;
@property (nonatomic) UISegmentedControl *scUValueType;
@property (nonatomic) UISegmentedControl *scSValueType;

@property (nonatomic) UIView *vResult;
@property (nonatomic) UILabel *lblResult;
@property (nonatomic) UITableView *tvResult;

@property (nonatomic) UIView *vMore;
@property (nonatomic) UIButton *btnReset;
@property (nonatomic) UIButton *btnMemory;
@property (nonatomic) UIButton *btnRefresh;

@property (nonatomic) UIView *vMemoryContent;
@property (nonatomic) UIView *vMemory;
@property (nonatomic) UITextField *tfMemorySize;
@property (nonatomic) UITextField *tfMemory;
@property (nonatomic) UIButton *btnSearchMemory;

@property (nonatomic) UITextView *tvMemory;
@property (nonatomic) UIButton *btnBackFromMemory;

@property (nonatomic, weak) UIView *vShowingContent;

@property (nonatomic) NSLayoutConstraint *lcUValueTypeTopMargin;

@property (nonatomic) BOOL isUnsignedValueType;
@property (nonatomic) NSInteger selectedValueTypeIndex;
@property (nonatomic) NSInteger selectedComparisonIndex;
@property (nonatomic, weak) UITextField *tfFocused;

@end

@implementation @@CLASSPREFIX@@MemUIView

+ (instancetype)instance
{
    static @@CLASSPREFIX@@MemUIView *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[@@CLASSPREFIX@@MemUIView alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initVars];
        [self initViews];
    }
    return self;
}

- (void)initVars {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.rcExpandedFrame = screenBounds;
    self.rcCollapsedFrame = CGRectMake(0, 0, @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_SIZE, @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_SIZE);
    
    _shouldNotBeDragged = NO;
    _expanded = NO;
    self.isUnsignedValueType = NO;
    self.selectedValueTypeIndex = 2;
    self.selectedComparisonIndex = 2;
}

- (void)initViews {
    self.backgroundColor = [UIColor blackColor];
    self.clipsToBounds = YES;
    self.frame = self.rcCollapsedFrame;
    self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2;
    [self initConsoleButton];
    [self initContents];
    [self initMemoryContents];
    self.vShowingContent = self.vContent;
}

- (void)initConsoleButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"@@LOGO@@" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self addSubview:button];
    NSDictionary *views = NSDictionaryOfVariableBindings(button);
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button]|"
                                                          options:0
                                                          metrics:nil
                                                            views:views];
    [self addConstraints:cv];
    [button addTarget:self action:@selector(onConsoleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.btnConsole = button;
}

- (void)doExpand {
    [self expand];
}

- (void)doCollapse {
    [self collapse];
    self.btnConsole.hidden = NO;
    [self.tfValue resignFirstResponder];
}

#pragma mark - Init Content View
- (void)initContents {
    [self initContentView];
    [self initSearchView];
    [self initOptionView];
    [self initResultView];
    [self initMoreView];
    self.vContent.hidden = YES;
}

- (void)initContentView {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self addSubview:v];
    
    NSDictionary *views = @{@"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:cv];
    
    self.vContent = v;
}

#pragma mark - Init Search View
- (void)initSearchView {
    [self initSearchViewContainer];
    [self initSearchValueType];
    [self initSearchButton];
    [self initSearchValueInput];
}

- (void)initSearchViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vContent addSubview:v];
    
    NSDictionary *views = @{@"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self.vContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[v(32)]" options:0 metrics:nil views:views];
    [self.vContent addConstraints:cv];
    
    self.vSearch = v;
}

- (void)initSearchValueType {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.textColor = [UIColor whiteColor];
    lbl.text = @"Thoát";
    [self.vSearch addSubview:lbl];
    
    NSDictionary *views = @{@"lbl":lbl};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[lbl(64)]" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbl]|" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:cv];
    
    self.lblType = lbl;
}

- (void)initSearchButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Tìm" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onSearchTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vSearch addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(64)]|" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:cv];
    
    self.btnSearch = btn;
}

- (void)initSearchValueInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.delegate = self;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.backgroundColor = [UIColor whiteColor];
    tf.textColor = [UIColor blackColor];
    tf.placeholder = @"@@YOURNAME@@";
    tf.returnKeyType = UIReturnKeySearch;
    tf.keyboardType = UIKeyboardTypeDefault;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.spellCheckingType = UITextSpellCheckingTypeNo;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.enabled = YES;
    [self.vSearch addSubview:tf];
    
    NSDictionary *views = @{@"lbl":self.lblType, @"btn":self.btnSearch, @"input":tf};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[lbl]-2-[input][btn]" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[input]|" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:cv];
    
    self.tfValue = tf;
}

#pragma mark - Init Option View
- (void)initOptionView {
    [self initOptionViewContainer];
    [self initComparisonSegmentedControl];
    [self initUValueTypeSegmentedControl];
    [self initSValueTypeSegmentedControl];
}

- (void)initOptionViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vContent addSubview:v];
    
    NSDictionary *views = @{@"vv":self.vSearch, @"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[vv]-8-[v]" options:0 metrics:nil views:views];
    [self.vContent addConstraints:cv];
    
    self.vOption = v;
}

- (void)initComparisonSegmentedControl {
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"<", @"<=", @"=", @">=", @">"]];
    sc.translatesAutoresizingMaskIntoConstraints = NO;
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    sc.selectedSegmentIndex = 2;
    [sc addTarget:self action:@selector(onComparisonChanged:) forControlEvents:UIControlEventValueChanged];
    [self.vOption addSubview:sc];
    
    NSDictionary *views = @{@"sc":sc};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sc]" options:0 metrics:nil views:views];
    [self.vOption addConstraints:cv];
    
    self.scComparison = sc;
}

- (void)initUValueTypeSegmentedControl {
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"UByte", @"UShort", @"UInt", @"ULong", @"Float"]];
    sc.translatesAutoresizingMaskIntoConstraints = NO;
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    sc.selectedSegmentIndex = -1;
    sc.selected = NO;
    [sc addTarget:self action:@selector(onValueTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.vOption addSubview:sc];
    
    NSDictionary *views = @{@"cmp":self.scComparison, @"sc":sc};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[cmp]-8-[sc]" options:0 metrics:nil views:views];
    [self.vOption addConstraints:cv];
    self.lcUValueTypeTopMargin = [cv firstObject];
    self.scUValueType = sc;
}

- (void)initSValueTypeSegmentedControl {
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"SByte", @"SShort", @"SInt", @"SLong", @"Double"]];
    sc.translatesAutoresizingMaskIntoConstraints = NO;
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    sc.selectedSegmentIndex = 2;
    sc.selected = YES;
    [sc addTarget:self action:@selector(onValueTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.vOption addSubview:sc];
    
    NSDictionary *views = @{@"usc":self.scUValueType, @"sc":sc};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[usc][sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:cv];
    
    self.scSValueType = sc;
}

#pragma mark - Init Result View
- (void)initResultView {
    [self initResultViewContainer];
    [self initResultLabel];
    [self initResultTableView];
}

- (void)initResultViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vContent addSubview:v];
    
    NSDictionary *views = @{@"vv":self.vOption, @"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self.vContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[vv]-8-[v]" options:0 metrics:nil views:views];
    [self.vContent addConstraints:cv];
    
    self.vResult = v;
}

- (void)initResultLabel {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentLeft;
    lbl.textColor = [UIColor whiteColor];
    lbl.text = @"Tìm";
    [self.vResult addSubview:lbl];
    
    NSDictionary *views = @{@"lbl":lbl};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[lbl]|" options:0 metrics:nil views:views];
    [self.vResult addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbl]" options:0 metrics:nil views:views];
    [self.vResult addConstraints:cv];
    
    self.lblResult = lbl;
}

- (void)initResultTableView {
    UITableView *tv = [[UITableView alloc] init];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.delegate = self;
    tv.dataSource = self;
    tv.backgroundColor = [UIColor clearColor];
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    tv.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self.vResult addSubview:tv];
    
    NSDictionary *views = @{@"lbl":self.lblResult, @"tv":tv};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tv]|" options:0 metrics:nil views:views];
    [self.vResult addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[lbl]-8-[tv]|" options:0 metrics:nil views:views];
    [self.vResult addConstraints:cv];
    
    [tv registerClass:[@@CLASSPREFIX@@MemUIViewCell class] forCellReuseIdentifier:@@CLASSPREFIX@@MemUIViewCellID];
    self.tvResult = tv;
}

#pragma mark - Init More View
- (void)initMoreView {
    [self initMoreViewContainer];
    [self initResetButton];
    [self initRefreshButton];
    [self initMemoryButton];
}

- (void)initMoreViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vContent addSubview:v];
    
    NSDictionary *views = @{@"vv":self.vResult, @"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self.vContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[vv]-8-[v(32)]|" options:0 metrics:nil views:views];
    [self.vContent addConstraints:cv];
    
    self.vMore = v;
}

- (void)initResetButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Cài lại" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onResetTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMore addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[btn(64)]" options:0 metrics:nil views:views];
    [self.vMore addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:cv];
    
    self.btnReset = btn;
}

- (void)initRefreshButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Làm Mới" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onRefreshTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMore addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(64)]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:cv];
    
    self.btnRefresh = btn;
}

- (void)initMemoryButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Bộ Nhớ" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onMemoryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMore addSubview:btn];
    
    NSDictionary *views = @{@"reset":self.btnReset, @"btn":btn, @"refresh":self.btnRefresh};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[reset][btn][refresh]" options:0 metrics:nil views:views];
    [self.vMore addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:cv];
    
    self.btnMemory = btn;
}

#pragma mark - Init Memory Content View
- (void)initMemoryContents {
    [self initMemoryContentView];
    [self initMemoryView];
    self.vMemoryContent.hidden = YES;
}

- (void)initMemoryContentView {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self addSubview:v];
    
    NSDictionary *views = @{@"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:cv];
    
    self.vMemoryContent = v;
}

#pragma mark - Init Memory View
- (void)initMemoryView {
    [self initMemoryViewContainer];
    [self initMemorySearchButton];
    [self initMemorySizeInput];
    [self initMemoryInput];
    [self initMemoryTextView];
    [self initBackFromMemoryButton];
}

- (void)initMemoryViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vMemoryContent addSubview:v];
    
    NSDictionary *views = @{@"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[v(32)]" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:cv];
    
    self.vMemory = v;
}

- (void)initMemorySearchButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Tìm" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onSearchMemoryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMemory addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(64)]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:cv];
    
    self.btnSearchMemory = btn;
}

- (void)initMemorySizeInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.delegate = self;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.backgroundColor = [UIColor whiteColor];
    tf.textColor = [UIColor blackColor];
    tf.text = @"1024";
    tf.placeholder = @"Size";
    tf.returnKeyType = UIReturnKeyNext;
    tf.keyboardType = UIKeyboardTypeDefault;
    tf.clearButtonMode = UITextFieldViewModeNever;
    tf.spellCheckingType = UITextSpellCheckingTypeNo;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.enabled = YES;
    [self.vMemory addSubview:tf];
    
    NSDictionary *views = @{@"tf":tf};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tf(64)]" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tf]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:cv];
    
    self.tfMemorySize = tf;
}

- (void)initMemoryInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.delegate = self;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.backgroundColor = [UIColor whiteColor];
    tf.textColor = [UIColor blackColor];
    tf.text = @"0";
    tf.placeholder = @"Nhập địa chỉ";
    tf.returnKeyType = UIReturnKeySearch;
    tf.keyboardType = UIKeyboardTypeDefault;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.spellCheckingType = UITextSpellCheckingTypeNo;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.enabled = YES;
    [self.vMemory addSubview:tf];
    
    NSDictionary *views = @{@"sz":self.tfMemorySize, @"tf":tf, @"btn":self.btnSearchMemory};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[sz]-8-[tf][btn]" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tf]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:cv];
    
    self.tfMemory = tf;
}

- (void)initMemoryTextView {
    UITextView *tv = [[UITextView alloc] init];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.font = [UIFont fontWithName:@"Courier New" size:12];
    tv.backgroundColor = [UIColor clearColor];
    tv.textColor = [UIColor whiteColor];
    tv.textAlignment = NSTextAlignmentCenter;
    tv.editable = NO;
    tv.selectable = YES;
    [self.vMemoryContent addSubview:tv];
    
    NSDictionary *views = @{@"v":self.vMemory, @"tv":tv};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tv]|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[v]-8-[tv]" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:cv];
    
    self.tvMemory = tv;
}

- (void)initBackFromMemoryButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Trở lại" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onBackFromMemoryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMemoryContent addSubview:btn];
    
    NSDictionary *views = @{@"tv":self.tvMemory, @"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[btn]|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[tv][btn(32)]|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:cv];
    
    self.btnBackFromMemory = btn;
}

#pragma mark - Setter / Getter
- (void)setChainCount:(NSInteger)chainCount {
    _chainCount = chainCount;
    self.lblResult.text = [NSString stringWithFormat:@"Kết quả   %lld.", (long long)chainCount];
    if (chainCount > 0) {
        self.lcUValueTypeTopMargin.constant = -CGRectGetHeight(self.scUValueType.frame) * 2;
        self.scUValueType.hidden = YES;
        self.scSValueType.hidden = YES;
    } else {
        self.lcUValueTypeTopMargin.constant = 8;
        self.scUValueType.hidden = NO;
        self.scSValueType.hidden = NO;
    }
}

- (void)setChain:(search_result_chain_t)chain {
    _chain = chain;
    if (chainArray) {
        free(chainArray);
        chainArray = NULL;
    }
    
    if (self.chainCount > 0 && self.chainCount <= MaxResultCount) {
        chainArray = malloc(sizeof(search_result_t) * self.chainCount);
        search_result_chain_t c = chain;
        int i = 0;
        while (i < self.chainCount) {
            if (c->result) chainArray[i++] = c->result;
            c = c->next;
            if (c == NULL) break;
        }
        if (i < self.chainCount) self.chainCount = i;
    }
    [self.tvResult reloadData];
}

#pragma mark - Gesture
- (void)addGesture {
    if (self.tapGesture != nil) return;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap];
    
    self.tapGesture = tap;
}

- (void)removeGesture {
    if (self.tapGesture == nil) { return; }
    
    [self removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

#pragma mark - Events
- (void)onSearchTapped:(id)sender {
    [self.tfValue resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUISearchValue:type:comparison:)]) {
        NSString *value = self.tfValue.text;
        if (value.length == 0) return;
        @@CLASSPREFIX@@MemValueType type = [self currentValueType];
        @@CLASSPREFIX@@MemComparison comparison = [self currentComparison];
        switch (self.selectedComparisonIndex) {
            case 0: comparison = @@CLASSPREFIX@@MemComparisonLT; break;
            case 1: comparison = @@CLASSPREFIX@@MemComparisonLE; break;
            case 2: comparison = @@CLASSPREFIX@@MemComparisonEQ; break;
            case 3: comparison = @@CLASSPREFIX@@MemComparisonGE; break;
            case 4: comparison = @@CLASSPREFIX@@MemComparisonGT; break;
        }
        [self.delegate @@CLASSPREFIX@@MemUISearchValue:value type:type comparison:comparison];
    }
}

- (void)onResetTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUIReset)]) {
        [self.delegate @@CLASSPREFIX@@MemUIReset];
    }
}

- (void)onRefreshTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUIRefresh)]) {
        [self.delegate @@CLASSPREFIX@@MemUIRefresh];
    }
}

- (void)onMemoryTapped:(id)sender {
    if (self.tvMemory.text.length == 0) {
        [self showMemory:self.tfMemory.text];
    } else {
        [self showMemory];
    }
}

- (void)onComparisonChanged:(id)sender {
    self.selectedComparisonIndex = self.scComparison.selectedSegmentIndex;
}

- (void)onValueTypeChanged:(id)sender {
    BOOL isUnsigned = (sender == self.scUValueType);
    UISegmentedControl *sc = isUnsigned ? self.scUValueType : self.scSValueType;
    UISegmentedControl *sc2 = isUnsigned ? self.scSValueType : self.scUValueType;
    sc.selected = YES;
    sc2.selected = NO;
    sc2.selectedSegmentIndex = -1;
    self.isUnsignedValueType = isUnsigned;
    self.selectedValueTypeIndex = sc.selectedSegmentIndex;
    self.lblType.text = [self stringFromValueType:[self currentValueType]];
}

- (void)onSearchMemoryTapped:(id)sender {
    [self.tfMemory resignFirstResponder];
    [self.tfMemorySize resignFirstResponder];
    NSString *address = self.tfMemory.text;
    NSString *size = self.tfMemorySize.text;
    if (address.length == 0) return;
    if ([self.delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUIMemory:size:)]) {
        NSString *memory = [self.delegate @@CLASSPREFIX@@MemUIMemory:address size:size];
        self.tvMemory.text = memory;
    }
}

- (void)onBackFromMemoryTapped:(id)sender {
    self.vMemoryContent.hidden = YES;
    self.vContent.hidden = NO;
    self.vShowingContent = self.vContent;
    self.tvMemory.text = @"";
}

- (void)showMemory {
    self.vContent.hidden = YES;
    self.vMemoryContent.hidden = NO;
    self.vShowingContent = self.vMemoryContent;
}

- (void)showMemory:(NSString *)address {
    [self showMemory];
    self.tfMemory.text = address;
    self.tvMemory.text = @"";
    [self onSearchMemoryTapped:nil];
}

- (void)onConsoleButtonTapped:(id)sender {
    [self doExpand];
}

#pragma mark - Expand & Collapse
- (void)expand {
    _shouldNotBeDragged = YES;
    CGRect frame = self.rcCollapsedFrame;
    frame.origin = self.frame.origin;
    self.rcCollapsedFrame = frame;
    self.btnConsole.hidden = YES;
    self.layer.cornerRadius = 0;
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.frame = self.rcExpandedFrame;
                         self.alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MAX_ALPHA;
                     }
                     completion:^(BOOL finished) {
                         self.frame = self.rcExpandedFrame;
                         self.alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MAX_ALPHA;
                         self.vShowingContent.hidden = NO;
                         self->_expanded = YES;
                     }];
    
    [self addGesture];
}

- (void)collapse {
    _shouldNotBeDragged = NO;
    CGRect frame = self.rcExpandedFrame;
    frame.origin = self.frame.origin;
    self.rcExpandedFrame = frame;
    self.layer.cornerRadius = CGRectGetWidth(self.rcCollapsedFrame) / 2;
    self.vShowingContent.hidden = YES;
    [self.tfFocused resignFirstResponder];
    [self removeGesture];
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.frame = self.rcCollapsedFrame;
                         self.alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MIN_ALPHA;
                     }
                     completion:^(BOOL finished) {
                         self.frame = self.rcCollapsedFrame;
                         self.alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MIN_ALPHA;
                         self->_expanded = NO;
                     }];
}

#pragma mark - Gesture
- (void)handleGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint pt = [sender locationInView:self.window];
        CGRect frameInScreen = self.tfValue.frame;
        frameInScreen.origin.x += CGRectGetMinX(self.frame);
        frameInScreen.origin.y += CGRectGetMinY(self.frame);
        if (CGRectContainsPoint(frameInScreen, pt)) {
            if ([self.tfValue canBecomeFirstResponder]) {
                [self.tfValue becomeFirstResponder];
            }
        } else {
            [self doCollapse];
        }
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.tfValue) {
        if (textField.returnKeyType == UIReturnKeySearch) {
            [self onSearchTapped:nil];
        }
    } else if (textField == self.tfMemory) {
        if (textField.returnKeyType == UIReturnKeySearch) {
            [self onSearchMemoryTapped:nil];
        }
    } else if (textField == self.tfMemorySize) {
        if (textField.returnKeyType == UIReturnKeyNext) {
            [self.tfMemory becomeFirstResponder];
        }
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.tfFocused = textField;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.chainCount > MaxResultCount) return 0;
    return self.chainCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @@CLASSPREFIX@@MemUIViewCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @@CLASSPREFIX@@MemUIViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@@CLASSPREFIX@@MemUIViewCellID forIndexPath:indexPath];
    cell.delegate = self;
    cell.textFieldDelegate = self;
    
    NSInteger index = indexPath.row;
    search_result_t result = chainArray[index];
    NSString *address = [NSString stringWithFormat:@"%llX", result->address];
    NSString *value = [self valueStringFromResult:result];
    cell.address = address;
    cell.value = value;
    cell.modifying = NO;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger index = indexPath.row;
    search_result_t result = chainArray[index];
    NSString *address = [NSString stringWithFormat:@"%llX", result->address];
    [self showMemory:address];
}

#pragma mark - @@CLASSPREFIX@@MemUIViewCellDelegate
- (void)@@CLASSPREFIX@@MemUIViewCellModify:(NSString *)address value:(NSString *)value {
    if ([self.delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUIModifyValue:address:type:)]) {
        @@CLASSPREFIX@@MemValueType type = [self currentValueType];
        [self.delegate @@CLASSPREFIX@@MemUIModifyValue:value address:address type:type];
    }
}

- (void)@@CLASSPREFIX@@MemUIViewCellViewMemory:(NSString *)address {
    [self showMemory:address];
}

#pragma mark - Utils
- (NSString *)valueStringFromResult:(search_result_t)result {
    NSString *value = nil;
    int type = result->type;
    if (type == SearchResultValueTypeUInt8) {
        uint8_t v = *(uint8_t *)(result->value);
        value = [NSString stringWithFormat:@"%u", v];
    } else if (type == SearchResultValueTypeSInt8) {
        int8_t v = *(int8_t *)(result->value);
        value = [NSString stringWithFormat:@"%d", v];
    } else if (type == SearchResultValueTypeUInt16) {
        uint16_t v = *(uint16_t *)(result->value);
        value = [NSString stringWithFormat:@"%u", v];
    } else if (type == SearchResultValueTypeSInt16) {
        int16_t v = *(int16_t *)(result->value);
        value = [NSString stringWithFormat:@"%d", v];
    } else if (type == SearchResultValueTypeUInt32) {
        uint32_t v = *(uint32_t *)(result->value);
        value = [NSString stringWithFormat:@"%u", v];
    } else if (type == SearchResultValueTypeSInt32) {
        int32_t v = *(int32_t *)(result->value);
        value = [NSString stringWithFormat:@"%d", v];
    } else if (type == SearchResultValueTypeUInt64) {
        uint64_t v = *(uint64_t *)(result->value);
        value = [NSString stringWithFormat:@"%llu", v];
    } else if (type == SearchResultValueTypeSInt64) {
        int64_t v = *(int64_t *)(result->value);
        value = [NSString stringWithFormat:@"%lld", v];
    } else if (type == SearchResultValueTypeFloat) {
        float v = *(float *)(result->value);
        value = [NSString stringWithFormat:@"%f", v];
    } else if (type == SearchResultValueTypeDouble) {
        double v = *(double *)(result->value);
        value = [NSString stringWithFormat:@"%f", v];
    } else {
        NSMutableString *ms = [NSMutableString string];
        char *v = (char *)(result->value);
        for (int i = 0; i < result->size; ++i) {
            printf("%02X ", v[i]);
            [ms appendFormat:@"%02X ", v[i]];
        }
        value = ms;
    }
    return value;
}

- (@@CLASSPREFIX@@MemValueType)currentValueType {
    @@CLASSPREFIX@@MemValueType type = @@CLASSPREFIX@@MemValueTypeSignedInt;
    switch (self.selectedValueTypeIndex) {
        case 0: type = self.isUnsignedValueType ? @@CLASSPREFIX@@MemValueTypeUnsignedByte : @@CLASSPREFIX@@MemValueTypeSignedByte; break;
        case 1: type = self.isUnsignedValueType ? @@CLASSPREFIX@@MemValueTypeUnsignedShort : @@CLASSPREFIX@@MemValueTypeSignedShort; break;
        case 2: type = self.isUnsignedValueType ? @@CLASSPREFIX@@MemValueTypeUnsignedInt : @@CLASSPREFIX@@MemValueTypeSignedInt; break;
        case 3: type = self.isUnsignedValueType ? @@CLASSPREFIX@@MemValueTypeUnsignedLong : @@CLASSPREFIX@@MemValueTypeSignedLong; break;
        case 4: type = self.isUnsignedValueType ? @@CLASSPREFIX@@MemValueTypeFloat : @@CLASSPREFIX@@MemValueTypeDouble; break;
    }
    return type;
}

- (@@CLASSPREFIX@@MemComparison)currentComparison {
    @@CLASSPREFIX@@MemComparison comparison = @@CLASSPREFIX@@MemComparisonEQ;
    switch (self.selectedComparisonIndex) {
        case 0: comparison = @@CLASSPREFIX@@MemComparisonLT; break;
        case 1: comparison = @@CLASSPREFIX@@MemComparisonLE; break;
        case 2: comparison = @@CLASSPREFIX@@MemComparisonEQ; break;
        case 3: comparison = @@CLASSPREFIX@@MemComparisonGE; break;
        case 4: comparison = @@CLASSPREFIX@@MemComparisonGT; break;
    }
    return comparison;
}

- (NSString *)stringFromValueType:(@@CLASSPREFIX@@MemValueType)type {
    switch (type) {
        case @@CLASSPREFIX@@MemValueTypeUnsignedByte: return @"UByte";
        case @@CLASSPREFIX@@MemValueTypeSignedByte: return @"SByte";
        case @@CLASSPREFIX@@MemValueTypeUnsignedShort: return @"UShort";
        case @@CLASSPREFIX@@MemValueTypeSignedShort: return @"SShort";
        case @@CLASSPREFIX@@MemValueTypeUnsignedInt: return @"UInt";
        case @@CLASSPREFIX@@MemValueTypeSignedInt: return @"SInt";
        case @@CLASSPREFIX@@MemValueTypeUnsignedLong: return @"ULong";
        case @@CLASSPREFIX@@MemValueTypeSignedLong: return @"SLong";
        case @@CLASSPREFIX@@MemValueTypeFloat: return @"Float";
        case @@CLASSPREFIX@@MemValueTypeDouble: return @"Double";
        default: return @"--";
    }
}

@end

@interface @@CLASSPREFIX@@MemUIViewCell ()

@property (nonatomic) UILabel *lblAddress;
@property (nonatomic) UILabel *lblValue;
@property (nonatomic) UITextField *tfValue;
@property (nonatomic) UIButton *btnMod;
@property (nonatomic) UIButton *btnViewMemory;

@end

@implementation @@CLASSPREFIX@@MemUIViewCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initAll];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initAll];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initAll];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initAll];
    }
    return self;
}

- (void)initAll {
    [self initUI];
}

- (void)initUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.textLabel.textColor = [UIColor whiteColor];
    [self initSplitLine];
    [self initAddressLabel];
    [self initValueLabel];
    [self initViewMemoryButton];
    [self initModButton];
    [self initValueInput];
}

- (void)initSplitLine {
    UIImageView *iv = [[UIImageView alloc] init];
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    iv.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:iv];
    
    NSDictionary *views = @{@"iv":iv};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[iv]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[iv(1)]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];
}

- (void)initAddressLabel {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentLeft;
    lbl.textColor = [UIColor whiteColor];
    lbl.text = @"Thêm địa chỉ";
    [self.contentView addSubview:lbl];
    
    NSDictionary *views = @{@"lbl":lbl};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[lbl(128)]" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbl]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];
    
    self.lblAddress = lbl;
}

- (void)initValueLabel {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentLeft;
    lbl.textColor = [UIColor whiteColor];
    lbl.text = @"Giá trị";
    [self.contentView addSubview:lbl];
    
    NSDictionary *views = @{@"addr":self.lblAddress, @"lbl":lbl};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[addr]-8-[lbl]" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbl]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];
    
    self.lblValue = lbl;
}

- (void)initViewMemoryButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"V" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onViewMemoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(32)]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];
    
    self.btnViewMemory = btn;
}

- (void)initModButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"M" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onModButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:btn];
    
    NSDictionary *views = @{@"lbl":self.lblValue, @"btn":btn, @"vm":self.btnViewMemory};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[lbl]-8-[btn(32)]-8-[vm]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];
    
    self.btnMod = btn;
}

- (void)initValueInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.backgroundColor = [UIColor whiteColor];
    tf.textColor = [UIColor blackColor];
    tf.placeholder = @"Giá trị mới";
    tf.returnKeyType = UIReturnKeyDone;
    tf.keyboardType = UIKeyboardTypeDefault;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.spellCheckingType = UITextSpellCheckingTypeNo;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.enabled = YES;
    tf.hidden = YES;
    [self.contentView addSubview:tf];
    
    NSDictionary *views = @{@"lbl":self.lblAddress, @"btn":self.btnMod, @"tf":tf};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[lbl]-8-[tf]-8-[btn]" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[tf]" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views];
    [self.contentView addConstraints:cv];
    
    self.tfValue = tf;
}

#pragma mark - Setter / Getter
- (void)setAddress:(NSString *)address {
    _address = address;
    self.lblAddress.text = address;
}

- (void)setValue:(NSString *)value {
    _value = value;
    self.lblValue.text = value;
    self.tfValue.text = value;
}

- (void)setModifying:(BOOL)modifying {
    _modifying = modifying;
    self.tfValue.text = self.value;
    self.lblValue.hidden = modifying;
    self.tfValue.hidden = !modifying;
    [self.btnMod setTitle:modifying ? @"OK" : @"M" forState:UIControlStateNormal];
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)textFieldDelegate {
    _textFieldDelegate = textFieldDelegate;
    self.tfValue.delegate = textFieldDelegate;
}

#pragma mark - Events
- (void)onModButtonTapped:(id)sender {
    if (self.modifying) {
        [self.tfValue resignFirstResponder];
        NSString *text = self.tfValue.text;
        if (text.length == 0) return;
        self.value = text;
        if ([self.delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUIViewCellModify:value:)]) {
            [self.delegate @@CLASSPREFIX@@MemUIViewCellModify:self.address value:self.value];
        }
    }
    self.modifying = !self.modifying;
}

- (void)onViewMemoryButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(@@CLASSPREFIX@@MemUIViewCellViewMemory:)]) {
        [self.delegate @@CLASSPREFIX@@MemUIViewCellViewMemory:self.address];
    }
}

@end

@implementation @@CLASSPREFIX@@MemEntry

static void __attribute__((constructor)) entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[[@@CLASSPREFIX@@Mem alloc] init] launch@@CLASSPREFIX@@Mem];
    });
}

@end

@interface @@CLASSPREFIX@@Mem () <@@CLASSPREFIX@@MemUIViewDelegate> {
    mach_port_t g_task;
    search_result_chain_t g_chain;
    int g_type;
}

@property (nonatomic, weak) @@CLASSPREFIX@@MemUIView *memView;

@end

@implementation @@CLASSPREFIX@@Mem

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initVars];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%@ dealloc", self);
}

- (void)initVars {
    g_task = mach_task_self();
    g_chain = NULL;
    g_type = SearchResultValueTypeUndef;
}

- (void)launch@@CLASSPREFIX@@Mem {
    [@@CLASSPREFIX@@MemUI add@@CLASSPREFIX@@MemUIView:self];
}

- (void)searchMem:(const char *)value type:(int)type comparison:(int)comparison {
    int size = 0;
    void *v = value_of_type(value, type, &size);
    int found = 0;
    search_result_chain_t chain = g_chain;
    g_chain = search_mem(g_task, v, size, type, comparison, chain, &found);
    self.memView.chainCount = found;
    self.memView.chain = g_chain;
}

- (void)modifyMem:(mach_vm_address_t)address value:(const char *)value type:(int)type {
    int size = 0;
    void *v = value_of_type(value, type, &size);
    int ret = write_mem(g_task, address, v, size);
    if (ret == 1) { NSLog(@"Modified successfully."); }
    else { NSLog(@"Failed to modify. Error: %d", ret); }
}

#pragma mark - @@CLASSPREFIX@@MemUIViewDelegate
- (void)@@CLASSPREFIX@@MemUILaunched:(@@CLASSPREFIX@@MemUIView *)view {
    self.memView = view;
}

- (void)@@CLASSPREFIX@@MemUISearchValue:(NSString *)value type:(@@CLASSPREFIX@@MemValueType)type comparison:(@@CLASSPREFIX@@MemComparison)comparison {
    const char *v = [value UTF8String];
    int t = [self memTypeFrom@@CLASSPREFIX@@MemValueType:type];
    int c = [self memComparisonFrom@@CLASSPREFIX@@MemComparison:comparison];
    [self searchMem:v type:t comparison:c];
}

- (void)@@CLASSPREFIX@@MemUIModifyValue:(NSString *)value address:(NSString *)address type:(@@CLASSPREFIX@@MemValueType)type {
    mach_vm_address_t a = 0;
    NSScanner *scanner = [NSScanner scannerWithString:address];
    if (![scanner scanHexLongLong:&a]) return;
    const char *v = [value UTF8String];
    int t = [self memTypeFrom@@CLASSPREFIX@@MemValueType:type];
    [self modifyMem:a value:v type:t];
}

- (void)@@CLASSPREFIX@@MemUIRefresh {
    review_mem_in_chain(g_task, g_chain);
    self.memView.chain = g_chain;
}

- (void)@@CLASSPREFIX@@MemUIReset {
    destroy_all_search_result_chain(g_chain);
    g_chain = NULL;
    self.memView.chainCount = 0;
    self.memView.chain = g_chain;
}

- (NSString *)@@CLASSPREFIX@@MemUIMemory:(NSString *)address size:(NSString *)size {
    mach_vm_address_t a = 0;
    NSScanner *scanner = [NSScanner scannerWithString:address];
    if (![scanner scanHexLongLong:&a]) return nil;
    int s = [size intValue];
    mach_vm_address_t addr = 0;
    mach_vm_size_t data_size = 0;
    void *data = read_range_mem(g_task, a, 0, s, &addr, &data_size);
    if (data == NULL || size == 0) return @"No memory.";
    
    NSMutableString *hex = [NSMutableString stringWithCapacity:data_size * 4];
    NSMutableString *chs = [NSMutableString stringWithCapacity:data_size];
    [hex appendFormat:@"%08llX ", addr];
    for (mach_vm_size_t i = 0; i < data_size; ++i) {
        if (i > 0 && i % 8 == 0) {
            [hex appendFormat:@"%@\n", chs];
            [hex appendFormat:@"%08llX ", addr + i];
            [chs setString:@""];
        }
        uint8_t v = *(((uint8_t *)data) + i);
        [hex appendFormat:@"%02X ", v];
        char c = v;
        if (c < 32 || c > 126) c = '.';
        [chs appendFormat:@"%c", c];
    }
    [hex appendFormat:@"%@\n", chs];
    return hex;
}

#pragma mark - Utils
- (int)memTypeFrom@@CLASSPREFIX@@MemValueType:(@@CLASSPREFIX@@MemValueType)type {
    switch (type) {
        case @@CLASSPREFIX@@MemValueTypeUnsignedByte: return SearchResultValueTypeUInt8;
        case @@CLASSPREFIX@@MemValueTypeSignedByte: return SearchResultValueTypeSInt8;
        case @@CLASSPREFIX@@MemValueTypeUnsignedShort: return SearchResultValueTypeUInt16;
        case @@CLASSPREFIX@@MemValueTypeSignedShort: return SearchResultValueTypeSInt16;
        case @@CLASSPREFIX@@MemValueTypeUnsignedInt: return SearchResultValueTypeUInt32;
        case @@CLASSPREFIX@@MemValueTypeSignedInt: return SearchResultValueTypeSInt32;
        case @@CLASSPREFIX@@MemValueTypeUnsignedLong: return SearchResultValueTypeUInt64;
        case @@CLASSPREFIX@@MemValueTypeSignedLong: return SearchResultValueTypeSInt64;
        case @@CLASSPREFIX@@MemValueTypeFloat: return SearchResultValueTypeFloat;
        case @@CLASSPREFIX@@MemValueTypeDouble: return SearchResultValueTypeDouble;
        default: return SearchResultValueTypeUndef;
    }
}

- (int)memComparisonFrom@@CLASSPREFIX@@MemComparison:(@@CLASSPREFIX@@MemComparison)comparison {
    switch (comparison) {
        case @@CLASSPREFIX@@MemComparisonLT: return SearchResultComparisonLT;
        case @@CLASSPREFIX@@MemComparisonLE: return SearchResultComparisonLE;
        case @@CLASSPREFIX@@MemComparisonEQ: return SearchResultComparisonEQ;
        case @@CLASSPREFIX@@MemComparisonGE: return SearchResultComparisonGE;
        case @@CLASSPREFIX@@MemComparisonGT: return SearchResultComparisonGT;
        default: return SearchResultComparisonEQ;
    }
}

@end

@implementation UIWindow (@@CLASSPREFIX@@MemUI)

- (BOOL)dragging {
    NSNumber *num = objc_getAssociatedObject(self, @selector(dragging));
    BOOL d = [num boolValue];
    return d;
}
- (void)setDragging:(BOOL)dragging {
    NSNumber *num = [NSNumber numberWithBool:dragging];
    objc_setAssociatedObject(self, @selector(dragging), num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGPoint)startPosition {
    NSValue *value = objc_getAssociatedObject(self, @selector(startPosition));
    CGPoint pt = [value CGPointValue];
    return pt;
}

- (void)setStartPosition:(CGPoint)pt {
    NSValue *value = [NSValue valueWithCGPoint:pt];
    objc_setAssociatedObject(self, @selector(startPosition), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (@@CLASSPREFIX@@MemUIView *)@@CLASSPREFIX@@MemUIView {
    @@CLASSPREFIX@@MemUIView *view = objc_getAssociatedObject(self, @selector(@@CLASSPREFIX@@MemUIView));
    return view;
}
- (void)set@@CLASSPREFIX@@MemUIView:(@@CLASSPREFIX@@MemUIView *)view{
    objc_setAssociatedObject(self, @selector(@@CLASSPREFIX@@MemUIView), view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)handleGesture:(UIPanGestureRecognizer *)sender {
    UIView *view = self;
    CGRect frame = [self @@CLASSPREFIX@@MemUIView].frame;
    
    CGPoint location = [sender locationInView:view];
    if (CGRectContainsPoint(frame, location) || self.dragging) {
        if (sender.state == UIGestureRecognizerStateBegan) {
            self.startPosition = [self @@CLASSPREFIX@@MemUIView].frame.origin;
            self.dragging = YES;
            [UIView animateWithDuration:0.2f
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [self @@CLASSPREFIX@@MemUIView].alpha = 1.0f;
                             }
                             completion:^(BOOL finished) {
                                 [self @@CLASSPREFIX@@MemUIView].alpha = 1.0f;
                             }];
        } else if (sender.state == UIGestureRecognizerStateChanged) {
            CGPoint pt = [sender translationInView:view];
            frame.origin.x = self.startPosition.x + pt.x;
            frame.origin.y = self.startPosition.y + pt.y;
            
            if ([self @@CLASSPREFIX@@MemUIView].shouldNotBeDragged) {
                CGRect screenBounds = [UIScreen mainScreen].bounds;
                CGFloat screenWidth = CGRectGetWidth(screenBounds);
                CGFloat screenHeight = CGRectGetHeight(screenBounds);
                
                if (CGRectGetMinX(frame) < 0) frame.origin.x = 0;
                else if (CGRectGetMaxX(frame) > screenWidth) frame.origin.x = screenWidth - CGRectGetWidth(frame);
                if (CGRectGetMinY(frame) < 0) frame.origin.y = 0;
                else if (CGRectGetMaxY(frame) > screenHeight) frame.origin.y = screenHeight - CGRectGetHeight(frame);
            }
            
            [self @@CLASSPREFIX@@MemUIView].frame = frame;
        } else {
            self.dragging = NO;
            
            CGRect screenBounds = [UIScreen mainScreen].bounds;
            CGFloat screenWidth = CGRectGetWidth(screenBounds);
            CGFloat screenHeight = CGRectGetHeight(screenBounds);
            
            if ([self @@CLASSPREFIX@@MemUIView].shouldNotBeDragged) {
                CGRect screenBounds = [UIScreen mainScreen].bounds;
                CGFloat screenWidth = CGRectGetWidth(screenBounds);
                CGFloat screenHeight = CGRectGetHeight(screenBounds);
                
                if (CGRectGetMinX(frame) < 0) frame.origin.x = 0;
                else if (CGRectGetMaxX(frame) > screenWidth) frame.origin.x = screenWidth - CGRectGetWidth(frame);
                if (CGRectGetMinY(frame) < 0) frame.origin.y = 0;
                else if (CGRectGetMaxY(frame) > screenHeight) frame.origin.y = screenHeight - CGRectGetHeight(frame);
                
                
                [UIView animateWithDuration:0.2f
                                      delay:0.0f
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     [self @@CLASSPREFIX@@MemUIView].frame = frame;
                                     [self @@CLASSPREFIX@@MemUIView].alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MAX_ALPHA;
                                 }
                                 completion:^(BOOL finished) {
                                     [self @@CLASSPREFIX@@MemUIView].frame = frame;
                                     [self @@CLASSPREFIX@@MemUIView].alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MAX_ALPHA;
                                 }];
            } else {
                CGFloat w = CGRectGetWidth(frame);
                CGFloat h = CGRectGetHeight(frame);
                CGFloat x = frame.origin.x;
                CGFloat y = frame.origin.y;
                
                CGFloat margin = 20;
                
                if ((x < margin ) || (x > screenWidth - w - margin)) {
                    if (x < (screenWidth - w) / 2) { x = 0; }
                    else { x = screenWidth - w; }
                    if (y < 0) { y = 0; }
                    else if (y > screenHeight - h) { y = screenHeight - h; }
                } else {
                    BOOL yChanged = NO;
                    if (y < h) { y = 0; yChanged = YES; }
                    else if (y > screenHeight - h - h) { y = screenHeight - h; yChanged = YES; }
                    if (yChanged) {
                        if (x < 0) { x = 0; }
                        else if (x > screenWidth - w) { x = screenWidth - w; }
                    } else {
                        if (x < (screenWidth - w) / 2) { x = 0; }
                        else { x = screenWidth - w; }
                    }
                }
                frame.origin.x = x;
                frame.origin.y = y;
                
                [UIView animateWithDuration:0.2f
                                      delay:0.0f
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     [self @@CLASSPREFIX@@MemUIView].frame = frame;
                                     [self @@CLASSPREFIX@@MemUIView].alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MIN_ALPHA;
                                 }
                                 completion:^(BOOL finished) {
                                     [self @@CLASSPREFIX@@MemUIView].frame = frame;
                                     [self @@CLASSPREFIX@@MemUIView].alpha = @@CLASSPREFIX@@_DEBUG_CONSOLE_VIEW_MIN_ALPHA;
                                 }];
            }
        }
    }
}

- (void)handleTTTapGesture:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self @@CLASSPREFIX@@MemUIView].hidden = ![self @@CLASSPREFIX@@MemUIView].hidden;
    }
}

@end

