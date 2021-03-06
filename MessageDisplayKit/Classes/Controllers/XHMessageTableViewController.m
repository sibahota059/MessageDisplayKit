//
//  XHMessageTableViewController.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-4-24.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "XHMessageTableViewController.h"

@interface XHMessageTableViewController ()

/**
 *  判断是否用户手指滚动
 */
@property (nonatomic, assign) BOOL isUserScrolling;

/**
 *  记录旧的textView contentSize Heigth
 */
@property (nonatomic, assign) CGFloat previousTextViewContentHeight;

@property (nonatomic, assign) XHTextViewInputViewType textViewInputViewType;


@property (nonatomic, weak, readwrite) XHMessageTableView *messageTableView;
@property (nonatomic, weak, readwrite) XHMessageInputView *messageInputView;
@property (nonatomic, weak, readwrite) XHShareMenuView *shareMenuView;
@property (nonatomic, weak, readwrite) XHEmotionManagerView *emotionManagerView;

@property (nonatomic, strong) XHPhotographyHelper *photographyHelper;

@end

@implementation XHMessageTableViewController

#pragma mark - DataSource Change

- (void)exChangeMessageDataSourceQueue:(void (^)())queue {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), queue);
}

- (void)exMainQueue:(void (^)())queue {
    dispatch_async(dispatch_get_main_queue(), queue);
}

- (void)addMessage:(XHMessage *)addedMessage {
    WEAKSELF
    [self exChangeMessageDataSourceQueue:^{
        NSMutableArray *messages = [NSMutableArray arrayWithArray:self.messages];
        [messages addObject:addedMessage];
        
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:1];
        [indexPaths addObject:[NSIndexPath indexPathForRow:messages.count - 1 inSection:0]];
        
        [weakSelf exMainQueue:^{
            weakSelf.messages = messages;
            [weakSelf.messageTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [weakSelf scrollToBottomAnimated:YES];
        }];
    }];
}

- (void)removeMessageAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.messages.count)
        return;
    [self.messages removeObjectAtIndex:indexPath.row];
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:1];
    [indexPaths addObject:indexPath];
    
    [self.messageTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)insertOldMessages:(NSArray *)oldMessages {
    WEAKSELF
    [self exChangeMessageDataSourceQueue:^{
        NSMutableArray *messages = [NSMutableArray arrayWithArray:oldMessages];
        [messages addObjectsFromArray:self.messages];
        
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:oldMessages.count];
        [oldMessages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [indexPaths addObject:indexPath];
        }];
        
        [weakSelf exMainQueue:^{
            weakSelf.messages = messages;
            [weakSelf.messageTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
        }];
    }];
}

#pragma mark - Propertys

- (NSMutableArray *)messages {
    if (!_messages) {
        _messages = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return _messages;
}

- (XHShareMenuView *)shareMenuView {
    if (!_shareMenuView) {
        CGFloat keyboardViewHeight = 216;
        XHShareMenuView *shareMenuView = [[XHShareMenuView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - keyboardViewHeight, CGRectGetWidth(self.view.bounds), keyboardViewHeight)];
        shareMenuView.delegate = self;
        shareMenuView.backgroundColor = [UIColor grayColor];
        shareMenuView.alpha = 0.0;
        shareMenuView.shareMenuItems = self.shareMenuItems;
        [self.view addSubview:shareMenuView];
        _shareMenuView = shareMenuView;
    }
    [self.view bringSubviewToFront:_shareMenuView];
    return _shareMenuView;
}

- (XHEmotionManagerView *)emotionManagerView {
    if (!_emotionManagerView) {
        CGFloat keyboardViewHeight = 216;
        XHEmotionManagerView *emotionManagerView = [[XHEmotionManagerView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - keyboardViewHeight, CGRectGetWidth(self.view.bounds), keyboardViewHeight)];
        emotionManagerView.delegate = self;
        emotionManagerView.dataSource = self;
        emotionManagerView.backgroundColor = [UIColor grayColor];
        emotionManagerView.alpha = 0.0;
        [self.view addSubview:emotionManagerView];
        _emotionManagerView = emotionManagerView;
    }
    [self.view bringSubviewToFront:_emotionManagerView];
    return _emotionManagerView;
}

- (XHPhotographyHelper *)photographyHelper {
    if (!_photographyHelper) {
        WEAKSELF
        _photographyHelper = [[XHPhotographyHelper alloc] initWithViewController:self didFinishTakeMediaCompledBlock:^(UIImage *image, NSDictionary *editingInfo) {
            XHMessage *photoMessage = [[XHMessage alloc] initWithPhoto:[editingInfo valueForKey:UIImagePickerControllerOriginalImage] thumbnailUrl:nil originPhotoUrl:nil sender:@"Jayson" timestamp:[NSDate date]];
            [weakSelf addMessage:photoMessage];
        }];
    }
    return _photographyHelper;
}

#pragma mark - Messages view controller

- (void)finishSendMessageWithBubbleMessageType:(XHBubbleMessageMediaType)mediaType {
    switch (mediaType) {
        case XHBubbleMessageText: {
            [self.messageInputView.inputTextView setText:nil];
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
                self.messageInputView.inputTextView.enablesReturnKeyAutomatically = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.messageInputView.inputTextView.enablesReturnKeyAutomatically = YES;
                    [self.messageInputView.inputTextView reloadInputViews];
                });
            }
            break;
        }
        case XHBubbleMessagePhoto: {
            break;
        }
        case XHBubbleMessageVideo: {
            break;
        }
        case XHBubbleMessageVoice: {
            break;
        }
        case XHBubbleMessageFace: {
            break;
        }
        case XHBubbleMessageLocalPosition: {
            break;
        }
        default:
            break;
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    self.view.backgroundColor = color;
    _messageTableView.backgroundColor = color;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    self.messageTableView.backgroundView = nil;
    self.messageTableView.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
	if (![self shouldAllowScroll])
        return;
	
    NSInteger rows = [self.messageTableView numberOfRowsInSection:0];
    
    if (rows > 0) {
        [self.messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:animated];
    }
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath
			  atScrollPosition:(UITableViewScrollPosition)position
					  animated:(BOOL)animated {
	if (![self shouldAllowScroll])
        return;
	
	[self.messageTableView scrollToRowAtIndexPath:indexPath
						  atScrollPosition:position
								  animated:animated];
}

#pragma mark - Previte Method

- (BOOL)shouldAllowScroll {
    if (self.isUserScrolling) {
        if ([self.delegate respondsToSelector:@selector(shouldPreventScrollToBottomWhileUserScrolling)]
            && [self.delegate shouldPreventScrollToBottomWhileUserScrolling]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Life cycle

- (void)setup {
    _allowsPanToDismissKeyboard = YES;
    _allowsSendVoice = YES;
    _allowsSendMultiMedia = YES;
    _allowsSendFace = YES;
    _inputViewStyle = XHMessageInputViewStyleFlat;
    
    self.delegate = self;
    self.dataSource = self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)initilzer {
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    // 默认设置用户滚动为NO
    _isUserScrolling = NO;
    
    // 初始化message tableView
	XHMessageTableView *messageTableView = [[XHMessageTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	messageTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	messageTableView.dataSource = self;
	messageTableView.delegate = self;
    messageTableView.separatorColor = [UIColor clearColor];
    messageTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [messageTableView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
	[self.view addSubview:messageTableView];
    [self.view sendSubviewToBack:messageTableView];
	_messageTableView = messageTableView;
    
    // 设置Message TableView 的bottom edg
    CGFloat inputViewHeight = (self.inputViewStyle == XHMessageInputViewStyleFlat) ? 45.0f : 40.0f;
    [self setTableViewInsetsWithBottomValue:inputViewHeight];
    
    // 设置整体背景颜色
    [self setBackgroundColor:[UIColor whiteColor]];
    
    // 输入工具条的frame
    CGRect inputFrame = CGRectMake(0.0f,
                                   self.view.frame.size.height - inputViewHeight,
                                   self.view.frame.size.width,
                                   inputViewHeight);
    
    WEAKSELF
    if (self.allowsPanToDismissKeyboard) {
        // 控制输入工具条的位置块
        void (^AnimationForMessageInputViewAtPoint)(CGPoint point) = ^(CGPoint point) {
            CGRect inputViewFrame = weakSelf.messageInputView.frame;
            CGPoint keyboardOrigin = [weakSelf.view convertPoint:point fromView:nil];
            inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
            weakSelf.messageInputView.frame = inputViewFrame;
        };
        
        self.messageTableView.keyboardDidScrollToPoint = ^(CGPoint point) {
            AnimationForMessageInputViewAtPoint(point);
        };
        
        self.messageTableView.keyboardWillSnapBackToPoint = ^(CGPoint point) {
            AnimationForMessageInputViewAtPoint(point);
        };
        
        self.messageTableView.keyboardWillBeDismissed = ^() {
            CGRect inputViewFrame = weakSelf.messageInputView.frame;
            inputViewFrame.origin.y = weakSelf.view.bounds.size.height - inputViewFrame.size.height;
            weakSelf.messageInputView.frame = inputViewFrame;
        };
    }
    
    // block回调键盘通知
    self.messageTableView.keyboardWillChange = ^(CGRect keyboardRect, UIViewAnimationOptions options, double duration, BOOL showKeyborad) {
        if (weakSelf.textViewInputViewType == XHTextViewNormalInputViewType) {
            [UIView animateWithDuration:duration
                                  delay:0.0
                                options:options
                             animations:^{
                                 CGFloat keyboardY = [weakSelf.view convertRect:keyboardRect fromView:nil].origin.y;
                                 
                                 CGRect inputViewFrame = weakSelf.messageInputView.frame;
                                 CGFloat inputViewFrameY = keyboardY - inputViewFrame.size.height;
                                 
                                 // for ipad modal form presentations
                                 CGFloat messageViewFrameBottom = weakSelf.view.frame.size.height - inputViewFrame.size.height;
                                 if (inputViewFrameY > messageViewFrameBottom)
                                     inputViewFrameY = messageViewFrameBottom;
                                 
                                 weakSelf.messageInputView.frame = CGRectMake(inputViewFrame.origin.x,
                                                                              inputViewFrameY,
                                                                              inputViewFrame.size.width,
                                                                              inputViewFrame.size.height);
                                 
                                 [weakSelf setTableViewInsetsWithBottomValue:weakSelf.view.frame.size.height
                                  - weakSelf.messageInputView.frame.origin.y];
                                 if (showKeyborad)
                                     [weakSelf scrollToBottomAnimated:NO];
                             }
                             completion:nil];
        }
    };
    
    self.messageTableView.keyboardDidChange = ^(BOOL didShowed) {
        if ([weakSelf.messageInputView.inputTextView isFirstResponder]) {
            if (didShowed) {
                weakSelf.shareMenuView.alpha = 0.0;
                weakSelf.emotionManagerView.alpha = 0.0;
            }
        }
    };
    
    self.messageTableView.keyboardDidHide = ^() {
        [weakSelf.messageInputView.inputTextView resignFirstResponder];
    };
    
    // 初始化输入工具条
    XHMessageInputView *inputView = [[XHMessageInputView alloc] initWithFrame:inputFrame];
    inputView.allowsSendFace = self.allowsSendFace;
    inputView.allowsSendVoice = self.allowsSendVoice;
    inputView.allowsSendMultiMedia = self.allowsSendMultiMedia;
    inputView.delegate = self;
    [self.view addSubview:inputView];
    [self.view bringSubviewToFront:inputView];
    
    _messageInputView = inputView;
    
    
    // 设置手势滑动，默认添加一个bar的高度值
    self.messageTableView.messageInputBarHeight = CGRectGetHeight(_messageInputView.bounds);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 设置键盘通知或者手势控制键盘消失
    [self.messageTableView setupPanGestureControlKeyboardHide:self.allowsPanToDismissKeyboard];
    
    // KVO 检查contentSize
    [self.messageInputView.inputTextView addObserver:self
                                     forKeyPath:@"contentSize"
                                        options:NSKeyValueObservingOptionNew
                                        context:nil];
    // 滚动到底部
    [self scrollToBottomAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 取消输入框
    [self.messageInputView.inputTextView resignFirstResponder];
    [self setEditing:NO animated:YES];
    
    // remove键盘通知或者手势
    [self.messageTableView disSetupPanGestureControlKeyboardHide:self.allowsPanToDismissKeyboard];
    
    // remove KVO
    [self.messageInputView.inputTextView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"华捷微信";
    
    // 初始化消息页面布局
    [self initilzer];
    [[XHMessageBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    _messages = nil;
    _delegate = nil;
    _dataSource = nil;
    _messageTableView.delegate = nil;
    _messageTableView.dataSource = nil;
    _messageTableView = nil;
    _messageInputView = nil;
}

#pragma mark - View rotation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.messageTableView reloadData];
    [self.messageTableView setNeedsLayout];
}

#pragma mark - UITextView Helper method

- (CGFloat)getTextViewContentH:(UITextView *)textView {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        return ceilf([textView sizeThatFits:textView.frame.size].height);
    } else {
        return textView.contentSize.height;
    }
}

#pragma mark - Layout message input view

- (void)layoutAndAnimateMessageInputTextView:(UITextView *)textView {
    CGFloat maxHeight = [XHMessageInputView maxHeight];
    
    CGFloat contentH = [self getTextViewContentH:textView];
    
    BOOL isShrinking = contentH < self.previousTextViewContentHeight;
    CGFloat changeInHeight = contentH - _previousTextViewContentHeight;
    
    if (!isShrinking && (self.previousTextViewContentHeight == maxHeight || textView.text.length == 0)) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }
    
    if (changeInHeight != 0.0f) {
        [UIView animateWithDuration:0.25f
                         animations:^{
                             [self setTableViewInsetsWithBottomValue:self.messageTableView.contentInset.bottom + changeInHeight];
                             
                             [self scrollToBottomAnimated:NO];
                             
                             if (isShrinking) {
                                 if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
                                     self.previousTextViewContentHeight = MIN(contentH, maxHeight);
                                 }
                                 // if shrinking the view, animate text view frame BEFORE input view frame
                                 [self.messageInputView adjustTextViewHeightBy:changeInHeight];
                             }
                             
                             CGRect inputViewFrame = self.messageInputView.frame;
                             self.messageInputView.frame = CGRectMake(0.0f,
                                                                      inputViewFrame.origin.y - changeInHeight,
                                                                      inputViewFrame.size.width,
                                                                      inputViewFrame.size.height + changeInHeight);
                             if (!isShrinking) {
                                 if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0) {
                                     self.previousTextViewContentHeight = MIN(contentH, maxHeight);
                                 }
                                 // growing the view, animate the text view frame AFTER input view frame
                                 [self.messageInputView adjustTextViewHeightBy:changeInHeight];
                             }
                         }
                         completion:^(BOOL finished) {
                         }];
        
        self.previousTextViewContentHeight = MIN(contentH, maxHeight);
    }
    
    // Once we reached the max height, we have to consider the bottom offset for the text view.
    // To make visible the last line, again we have to set the content offset.
    if (self.previousTextViewContentHeight == maxHeight) {
        double delayInSeconds = 0.01;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime,
                       dispatch_get_main_queue(),
                       ^(void) {
                           CGPoint bottomOffset = CGPointMake(0.0f, contentH - textView.bounds.size.height);
                           [textView setContentOffset:bottomOffset animated:YES];
                       });
    }
}

#pragma mark - Scroll Message TableView Helper Method

- (void)setTableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = [self tableViewInsetsWithBottomValue:bottom];
    self.messageTableView.contentInset = insets;
    self.messageTableView.scrollIndicatorInsets = insets;
}

- (UIEdgeInsets)tableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
//#warning test for XCode 4.6.1
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        insets.top = 64;
    }
//#endif
    
    insets.bottom = bottom;
    
    return insets;
}

#pragma mark - XHMessageTableViewController delegate

- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

#pragma mark - XHMessage Send helper Method

- (void)didSendMessageWithPhoto:(UIImage *)photo {
    DLog(@"send photo : %@", photo);
    if ([self.delegate respondsToSelector:@selector(didSendPhoto:fromSender:onDate:)]) {
        [self.delegate didSendPhoto:photo fromSender:self.messageSender onDate:[NSDate date]];
    }
}

- (void)didSendMessageWithVideo:(NSString *)videoPath {
    DLog(@"send videoPath : %@", videoPath);
    if ([self.delegate respondsToSelector:@selector(didSendVideo:fromSender:onDate:)]) {
        [self.delegate didSendVideo:videoPath fromSender:self.messageSender onDate:[NSDate date]];
    }
}

- (void)didSendMessageWithvoice:(NSString *)voicePath {
    DLog(@"send voicePath : %@", voicePath);
    if ([self.delegate respondsToSelector:@selector(didSendVoice:fromSender:onDate:)]) {
        [self.delegate didSendVoice:voicePath fromSender:self.messageSender onDate:[NSDate date]];
    }
}

- (void)didSendFaceMessageWithFacePath:(NSString *)facePath {
    XHMessage *message = [[XHMessage alloc] initWithEmotionPath:facePath sender:@"Jayson" timestamp:[NSDate date]];
    [self addMessage:message];
}

#pragma mark - XHMessageInputView Delegate

- (void)inputTextViewWillBeginEditing:(XHMessageTextView *)messageInputTextView {
    self.textViewInputViewType = XHTextViewNormalInputViewType;
    self.messageInputView.faceSendButton.selected = NO;
    self.messageInputView.voiceChangeButton.selected = NO;
}

- (void)inputTextViewDidBeginEditing:(XHMessageTextView *)messageInputTextView {
    if (!self.previousTextViewContentHeight)
		self.previousTextViewContentHeight = [self getTextViewContentH:messageInputTextView];
}

- (void)didChangeSendVoiceMeesgae:(BOOL)changed {
    if (changed) {
        if (self.textViewInputViewType == XHTextViewNormalInputViewType)
            return;
        
        self.shareMenuView.alpha = 0.0;
        self.emotionManagerView.alpha = 0.0;
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect inputViewFrame = self.messageInputView.frame;
            inputViewFrame.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(inputViewFrame);
            self.messageInputView.frame = inputViewFrame;
            
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)didSendMessageWithText:(NSString *)text {
    DLog(@"text : %@", text);
    if ([self.delegate respondsToSelector:@selector(didSendText:fromSender:onDate:)]) {
        [self.delegate didSendText:text fromSender:self.messageSender onDate:[NSDate date]];
    }
}

- (void)didSelectedMultipleMediaAction {
    DLog(@"didSelectedMultipleMediaAction");
    self.textViewInputViewType = XHTextViewPlugMenuInputViewType;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect inputViewFrame = self.messageInputView.frame;
        inputViewFrame.origin.y = CGRectGetMinY(self.shareMenuView.frame) - CGRectGetHeight(inputViewFrame);
        self.messageInputView.frame = inputViewFrame;
        
    } completion:^(BOOL finished) {
        
    }];
    self.shareMenuView.alpha = 1.0;
    [self.messageInputView.inputTextView resignFirstResponder];
}

- (void)didSendFaceMessage:(BOOL)sendFace {
    if (sendFace) {
        self.textViewInputViewType = XHTextViewFaceInputViewType;
        
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect inputViewFrame = self.messageInputView.frame;
            inputViewFrame.origin.y = CGRectGetMinY(self.shareMenuView.frame) - CGRectGetHeight(inputViewFrame);
            self.messageInputView.frame = inputViewFrame;
            
        } completion:^(BOOL finished) {
            
        }];
        self.emotionManagerView.alpha = 1.0;
        [self.messageInputView.inputTextView resignFirstResponder];
    } else {
        [self.messageInputView.inputTextView becomeFirstResponder];
    }
}

- (void)didStartRecordingVoice {
    DLog(@"didStartRecordingVoice");
}

- (void)didCancelRecordingVoice {
    DLog(@"didCancelRecordingVoice");
}

- (void)didFinishRecoingVoice {
    DLog(@"didFinishRecoingVoice");
}

#pragma mark - XHMessageTableViewCell delegate

- (void)multiMediaMessageDidSelectedOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath onMessageTableViewCell:(XHMessageTableViewCell *)messageTableViewCell {
    switch (message.messageMediaType) {
        case XHBubbleMessagePhoto:
            DLog(@"message : %@", message.photo);
            break;
        case XHBubbleMessageVideo:
            DLog(@"message : %@", message.videoConverPhoto);
            break;
        case XHBubbleMessageVoice:
            DLog(@"message : %@", message.voicePath);
            [messageTableViewCell.messageBubbleView.animationVoiceImageView startAnimating];
            [messageTableViewCell.messageBubbleView.animationVoiceImageView performSelector:@selector(stopAnimating) withObject:nil afterDelay:10];
            break;
        case XHBubbleMessageFace:
            DLog(@"facePath : %@", message.emotionPath);
            break;
        case XHBubbleMessageLocalPosition:
            DLog(@"facePath : %@", message.localPositionPhoto);
            break;
        default:
            break;
    }
}

- (void)didDoubleSelectedOnTextMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"text : %@", message.text);
}

- (void)didSelectedAvatorAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"indexPath : %@", indexPath);
}

- (void)menuDidSelectedAtBubbleMessageMenuSelecteType:(XHBubbleMessageMenuSelecteType)bubbleMessageMenuSelecteType {
    
}

#pragma mark - XHShareMenuView delegate

- (void)didSelecteShareMenuItem:(XHShareMenuItem *)shareMenuItem atIndex:(NSInteger)index {
    NSLog(@"title : %@   index:%ld", shareMenuItem.title, (long)index);
    switch (index) {
        case 0: {
            [self.photographyHelper showOnPickerViewControllerSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
        }
        case 1: {
            [self.photographyHelper showOnPickerViewControllerSourceType:UIImagePickerControllerSourceTypeCamera];
            break;
        }
        default:
            break;
    }
}

#pragma mark - XHEmotionManagerView delegate

- (void)didSelecteEmotion:(XHEmotion *)emotion atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"indexPath : %@ ", indexPath);
}

#pragma mark - XHEmotionManagerView DataSource

- (NSInteger)numberOfEmotionManagers {
    return 0;
}

- (XHEmotionManager *)emotionManagerForColumn:(NSInteger)column {
    return nil;
}

- (NSArray *)emotionManagersAtManager {
    return nil;
}

#pragma mark - UIScrollView delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	self.isUserScrolling = YES;
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if (menu.isMenuVisible) {
        [menu setMenuVisible:NO animated:YES];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.isUserScrolling = NO;
}

#pragma mark - XHMessageTableViewController DataSource

- (id <XHMessageModel>)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.messages[indexPath.row];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <XHMessageModel> message = [self.dataSource messageForRowAtIndexPath:indexPath];
    
    BOOL displayTimestamp = YES;
    if ([self.delegate respondsToSelector:@selector(shouldDisplayTimestampForRowAtIndexPath:)]) {
        displayTimestamp = [self.delegate shouldDisplayTimestampForRowAtIndexPath:indexPath];
    }
    
    static NSString *cellIdentifier = @"XHMessageTableViewCell";
    
    XHMessageTableViewCell *messageTableViewCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!messageTableViewCell) {
        messageTableViewCell = [[XHMessageTableViewCell alloc] initWithMessage:message displaysTimestamp:displayTimestamp reuseIdentifier:cellIdentifier];
        messageTableViewCell.delegate = self;
    }
    
    messageTableViewCell.indexPath = indexPath;
    [messageTableViewCell configureCellWithMessage:message displaysTimestamp:displayTimestamp];
    [messageTableViewCell setBackgroundColor:tableView.backgroundColor];
    
    if ([self.delegate respondsToSelector:@selector(configureCell:atIndexPath:)]) {
        [self.delegate configureCell:messageTableViewCell atIndexPath:indexPath];
    }
    
    return messageTableViewCell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <XHMessageModel> message = [self.dataSource messageForRowAtIndexPath:indexPath];
    
    BOOL displayTimestamp = YES;
    if ([self.delegate respondsToSelector:@selector(shouldDisplayTimestampForRowAtIndexPath:)]) {
        displayTimestamp = [self.delegate shouldDisplayTimestampForRowAtIndexPath:indexPath];
    }
    
    return [XHMessageTableViewCell calculateCellHeightWithMessage:message displaysTimestamp:displayTimestamp];
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.messageInputView.inputTextView && [keyPath isEqualToString:@"contentSize"]) {
        [self layoutAndAnimateMessageInputTextView:object];
    }
}

@end
