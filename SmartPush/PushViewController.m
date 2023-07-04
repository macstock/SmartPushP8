//
//  PushViewController.m
//  SmartPush
//
//  Created by Jakey on 15/3/15.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#define Push_Developer  "api.sandbox.push.apple.com"
#define Push_Production  "api.push.apple.com"

#define KEY_CERNAME     @"KEY_CERNAME"
#define KEY_CER         @"KEY_CERPATH"
#define KEY_TOKEN       @"KEY_TOKEN"
#define KEY_PAYLOAD     @"KEY_PAYLOAD"
#define KEY_TEAM_ID     @"KEY_TEAM_ID"
#define KEY_KEY_ID     @"KEY_KEY_ID"
#define KEY_BUNDLE_ID     @"KEY_BUNDLE_ID"

#import "PushViewController.h"
#import "SecManager.h"
#import "Sec.h"
#import "NetworkManager.h"
#import "SmartPushWithP8-Swift.h"

@interface PushViewController ()
@property (weak) IBOutlet NSTextField *cerKeyTextField;
@property (weak) IBOutlet NSTextField *priorityKeyTextField;
@property (weak) IBOutlet NSLayoutConstraint *tokenKeyTopConstraint;


@end

@implementation PushViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.payload.string = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6,\"sound\": \"default\"}}";
     
    //    [[ NSUserDefaults  standardUserDefaults] removeObjectForKey:KEY_CERNAME];
    //    [[ NSUserDefaults  standardUserDefaults] removeObjectForKey:KEY_CER];
    
    _connectResult = -50;
    _closeResult = -50;
    [self modeSwitch:self.devSelect];
    [self loadUserData];
    [self loadKeychain];
    
}

- (void)viewDidLayout {
    [super viewDidLayout];
    [self updateUI];
}

- (void)updateUI {
    //p8视图下,证书key 与 token key的间距
    CGFloat dertaCerVWithTokenAndCer = CGRectGetMaxY(self.cerKeyTextField.frame) - CGRectGetMinY(self.bundleIDKeyTextField.frame) - 30;
    CGFloat dertaP8VWithTokenAndCer = 20;
    if (_currentSec.type == SecTypeCer) {
        self.teamIDKeyTextField.hidden = YES;
        self.teamIDTextField.hidden = YES;
        self.keyIDKeyTextField.hidden = YES;
        self.keyIDTextField.hidden = YES;
        self.bundleIDKeyTextField.hidden = YES;
        self.bundleIDTextField.hidden = YES;
        self.tokenKeyTopConstraint.constant = -dertaCerVWithTokenAndCer;
    } else {
        self.teamIDKeyTextField.hidden = NO;
        self.teamIDTextField.hidden = NO;
        self.keyIDKeyTextField.hidden = NO;
        self.keyIDTextField.hidden = NO;
        self.bundleIDKeyTextField.hidden = NO;
        self.bundleIDTextField.hidden = NO;
        self.tokenKeyTopConstraint.constant = dertaP8VWithTokenAndCer;
    }
}

- (IBAction)devPopButtonSelect:(DragPopUpButton*)sender {
    if (sender.indexOfSelectedItem ==0) {
        _cerName = nil;
        _lastCerPath = nil;
    }
    else if (sender.indexOfSelectedItem ==1) {
        //        [self devCerBrowse:nil];
        [self browseDone:^(NSString *url) {
            [self updateUI];
            [self applyWithCerPath:url];
        }];
    } else {
        [self log:[NSString stringWithFormat:@"选择证书 %@",_cerName] warning:NO];
        [self resetConnect];
        _currentSec =   [_certificates objectAtIndex:sender.indexOfSelectedItem-2];
        _cerName = _currentSec.name;
        [self connect:nil];
        
    }
    [self updateUI];
    [self saveUserData];
}

- (void)applyWithCerPath:(NSString*)cerPath {
    Sec2 *currentSec;
    if ([JWTManager isP8FileWithPath:cerPath]) {
        _lastCerPath = cerPath;
        currentSec = [SecManager secModelWithP8Path:cerPath];
        _cerName = currentSec.name;
    } else {
        SecCertificateRef secRef =  [SecManager certificatesWithPath:cerPath];
        if ([SecManager isPushCertificate:secRef]) {
            _lastCerPath = cerPath;
            if (secRef) {
                for (Sec2 *sec in _certificates) {
                    if ([sec.key isEqualToString:@"lastSelected"]) {
                        [_certificates removeObject:sec];
                        break;
                    }
                }
                currentSec = [SecManager secModelWithRef:secRef];
                currentSec.key = @"lastSelected";
                _cerName = currentSec.name;
            }
        }
    }
    
    if (currentSec) {
        _currentSec = currentSec;
        [self resetConnect];
        [_certificates addObject:_currentSec];
        [self reloadCerPopButton];
    } else {
        [self showMessage:@"不是有效的推送证书"];
        [self log:@"不是有效的推送证书" warning:YES];
    }
    
    [self saveUserData];
    
}

- (void)reloadCerPopButton {
    [self.cerPopUpButton dragPopUpButtonDragEnd:^(NSString *text) {
        [self applyWithCerPath:text];
    }];
    
    [self.cerPopUpButton removeAllItems];
    [self.cerPopUpButton addItemWithTitle:@"从下拉列表选择或者拖拽推送证书到选择框"];
    [self.cerPopUpButton addItemWithTitle:@"从文件选择推送证书(.cer / .p8)"];
    
    int selectIndex= -1;
    for (int i = 0; i < [_certificates count]; i++) {
        Sec2 *sec =  [_certificates objectAtIndex:i];
        [self.cerPopUpButton addItemWithTitle:[NSString stringWithFormat:@"%@ %@ %@", sec.name, sec.type == SecTypeCer ? sec.expire : @"",[sec.key isEqualToString:@"lastSelected"]?@"文件":@""]];
        if([_cerName length] > 0 && [sec.name isEqualToString:_cerName]) {
            [self log:[NSString stringWithFormat:@"选择证书 %@",_cerName] warning:NO];
            [self resetConnect];
            selectIndex = i+2;
            _currentSec =   sec;
            _cerName = _currentSec.name;
            [self connect:nil];
        }
    }
    [self.cerPopUpButton selectItemAtIndex:selectIndex];
}

- (void)loadKeychain {
    _certificates = [[SecManager allPushCertificatesWithEnvironment:YES] mutableCopy];
    if (_lastCerPath.length > 0) {
        
        if ([JWTManager isP8FileWithPath:_lastCerPath]) {
            Sec2 *sec = [SecManager secModelWithP8Path:_lastCerPath];
            sec.key = @"lastSelected";
            [_certificates addObject:sec];
        } else {
            Sec2 *sec = [SecManager secModelWithRef:[SecManager certificatesWithPath:_lastCerPath]];
            sec.key = @"lastSelected";
            [_certificates addObject:sec];
        }
    }
    [self log:@"读取Keychain中证书" warning:NO];
    [self reloadCerPopButton];
}

#pragma mark Private
- (void)loadUserData {
    NSLog(@"load userdefaults");
    [self log:@"读取保存的信息" warning:NO];
    
    _defaults = [NSUserDefaults standardUserDefaults];
    if ([_defaults valueForKey:KEY_TOKEN])
        [self.deviceTokenTextField setStringValue:[_defaults valueForKey:KEY_TOKEN]];
    
    if ([[_defaults valueForKey:KEY_PAYLOAD] description].length>0)
        self.payload.string = [_defaults valueForKey:KEY_PAYLOAD];
    
    if ([[_defaults valueForKey:KEY_CERNAME] description].length>0)
        _cerName = [_defaults valueForKey:KEY_CERNAME];
    
    if ([[_defaults valueForKey:KEY_CER] description].length>0)
        _lastCerPath = [_defaults valueForKey:KEY_CER];
    
    if ([[_defaults valueForKey:KEY_TEAM_ID] description].length>0)
        [self.teamIDTextField setStringValue:[_defaults valueForKey:KEY_TEAM_ID]];
    
    if ([[_defaults valueForKey:KEY_KEY_ID] description].length>0)
        [self.keyIDTextField setStringValue:[_defaults valueForKey:KEY_KEY_ID]];
    
    if ([[_defaults valueForKey:KEY_BUNDLE_ID] description].length>0)
        [self.bundleIDTextField setStringValue:[_defaults valueForKey:KEY_BUNDLE_ID]];

}

- (void)saveUserData {
    [_defaults setValue:_lastCerPath forKey:KEY_CER];
    [_defaults setValue:self.deviceTokenTextField.stringValue forKey:KEY_TOKEN];
    [_defaults setValue:self.payload.string forKey:KEY_PAYLOAD];
    [_defaults setValue:_cerName forKey:KEY_CERNAME];
    [_defaults setValue:self.teamIDTextField.stringValue forKey:KEY_TEAM_ID];
    [_defaults setValue:self.keyIDTextField.stringValue forKey:KEY_KEY_ID];
    [_defaults setValue:self.bundleIDTextField.stringValue forKey:KEY_BUNDLE_ID];
    [_defaults synchronize];
}

- (void)disconnect {
    NSLog(@"disconnect");
    [self log:@"断开链接" warning:NO];
    [self log:@"---------------------------------" warning:NO];

    if (_closeResult != 0) {
        return;
    }
    // 关闭SSL会话
    _closeResult = SSLClose(_context);
    //NSLog(@"SSLClose(): %d", _closeResult);
    
    // Release identity.
    if (_identity != NULL)
        CFRelease(_identity);
    
    // Release keychain.
    if (_keychain != NULL)
        CFRelease(_keychain);
    
    // Close connection to server.
    close((int)socket);
    
    // Delete SSL context.
    _closeResult = SSLDisposeContext(_context);
    
}

#pragma mark --IBAction
- (IBAction)connect:(id)sender {
    [self saveUserData];
    
    if (_currentSec.type == SecTypeCer) {
        if (_currentSec.certificateRef == NULL) {
            [self showMessage:@"读取证书失败!"];
            [self log:@"读取证书失败!" warning:YES];
            return;
        }
        [self log:@"连接服务器!" warning:NO];
        
        NSLog(@"connect");
        // Open keychain.
        _connectResult = SecKeychainCopyDefault(&_keychain);
        NSLog(@"SecKeychainOpen(): %d", _connectResult);
        [self prepareCerData];
    } else if (_currentSec.type == SecTypeP8) {
        if (_currentSec.p8String.length == 0) {
            [self showMessage:@"读取证书失败!"];
            [self log:@"读取证书失败!" warning:YES];
            return;
        }
        [self log:@"连接服务器!" warning:NO];
        NSLog(@"connect");
        [self prepareCerData];
    }
}

- (void)resetConnect {
    [self log:@"重置连接" warning:NO];
    _connectResult = -50;
    [self disconnect];
}

- (void)prepareCerData {
    if (_currentSec.type == SecTypeCer) {
        if (_currentSec.certificateRef == NULL) {
            [self showMessage:@"读取证书失败!"];
            [self log:@"读取证书失败!" warning:YES];
            return;
        }
        
        // Create identity.
        _connectResult = SecIdentityCreateWithCertificate(_keychain, _currentSec.certificateRef, &_identity);
        // NSLog(@"SecIdentityCreateWithCertificate(): %d", result);
        if(_connectResult != errSecSuccess ){
            [self log:[NSString stringWithFormat:@"SSL端点域名不能被设置 %d",_connectResult] warning:YES];
        }
        
        if(_connectResult == errSecItemNotFound ){
            [self log:[NSString stringWithFormat:@"Keychain中不能找到证书 %d",_connectResult] warning:YES];
        }
        
        // Set client certificate.
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)&_identity, 1, NULL);
        _connectResult = SSLSetCertificate(_context, certificates);
        // NSLog(@"SSLSetCertificate(): %d", result);
        CFRelease(certificates);
        
        [[NetworkManager sharedManager] setIdentity:_identity];
    } else if (_currentSec.type == SecTypeP8) {
        if (_currentSec.p8String.length == 0) {
            [self showMessage:@"读取证书失败!"];
            [self log:@"读取证书失败!" warning:YES];
            return;
        }
    }

}

- (IBAction)push:(id)sender {
    [self saveUserData];
    
    NSString *deviceToken = [self.deviceTokenTextField.stringValue stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *pushType = self.pushTypeButton.selectedItem.title;
    NSString *topic = _currentSec ? _currentSec.topicName : @"";
    
    NSString *p8Token = nil;
    
    if (self.cerPopUpButton.indexOfSelectedItem < 2) {
        [self showMessage:@"未选择推送证书"];
        [self log:@"未选择推送证书" warning:YES];
        return;
    }
    
    if (_currentSec.type == SecTypeCer) {
        if (_currentSec.certificateRef == NULL) {
            [self showMessage:@"读取证书失败!"];
            [self log:@"读取证书失败!" warning:YES];
            return;
        }
        
    } else if (_currentSec.type == SecTypeP8) {
        if (_currentSec.p8String.length == 0) {
            [self showMessage:@"读取证书失败!"];
            [self log:@"读取证书失败!" warning:YES];
            return;
        }
        NSString *keyId = self.keyIDTextField.stringValue;
        NSString *teamId = self.teamIDTextField.stringValue;
        if (keyId.length == 0) {
            [self showMessage:@"KeyID获取失败!"];
            [self log:@"KeyID获取失败!" warning:YES];
            return;
        }
        if (teamId.length == 0) {
            [self showMessage:@"TeamID获取失败!"];
            [self log:@"TeamID获取失败!" warning:YES];
            return;
        }
        topic = self.bundleIDTextField.stringValue;
        p8Token = [JWTManager tokenWithKeyId:keyId teamId:teamId p8String:_currentSec.p8String];
    }
    
    if ([pushType isEqualToString:@"liveactivity"]) {
        topic = [NSString stringWithFormat:@"%@.push-type.liveactivity", self.bundleIDTextField.stringValue];
    }
    [self log:@"发送推送信息" warning:NO];
    [[NetworkManager sharedManager] postWithPayload:self.payload.string
                                            toToken:deviceToken
                                          withTopic:topic
                                           priority:@(self.prioritySegmentedControl.selectedTag).stringValue
                                         collapseID:@""
                                           pushType:pushType
                                            p8Token:p8Token
                                          inSandbox:(self.devSelect == self.mode.selectedCell)
                                         exeSuccess:^(id  _Nonnull responseObject) {
        [self showMessage:@"发送成功"];
        [self log:@"发送成功" warning:NO];
    } exeFailed:^(NSString * _Nonnull error) {
        [self showMessage:@"发送失败"];
        [self log:error warning:YES];
        [self log:@"发送失败" warning:YES];
    }];
}

//环境切换
- (IBAction)modeSwitch:(id)sender {
    [self resetConnect];
    //测试环境
    if (self.devSelect == self.mode.selectedCell) {
        [self log:@"切换到开发环境" warning:NO];
    }
    //生产正式环境
    if (self.productSelect == self.mode.selectedCell) {
        //_cerPath = [[NSBundle mainBundle] pathForResource:self.productCer.stringValue ofType:@"cer"];
        [self log:@"切换到生产正式环境" warning:NO];
    }
}

- (IBAction)prioritySwitch:(id)sender {
    
}

- (IBAction)playLoadTypeTouched:(id)sender {
    
}

- (IBAction)payLoadButtonTouched:(NSPopUpButton*)sender {
    NSString *stringValue = @"";
    switch (sender.indexOfSelectedItem) {
        case 1:
            stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\"}}";
            break;
        case 2:
            stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6}}";
            break;
        case 3:
            stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6,\"sound\": \"default\"}}";
            break;
        default:
            stringValue = @"{\"aps\":{\"alert\":\"This is some fancy message.\",\"badge\":6,\"sound\": \"default\"}}";
            break;

    }
                
    self.payload.string  = stringValue;

}

- (void)browseDone:(void (^)(NSString *url))complete {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    [openDlg setCanChooseFiles:TRUE];
    [openDlg setCanChooseDirectories:FALSE];
    [openDlg setAllowsMultipleSelection:FALSE];
    [openDlg setAllowsOtherFileTypes:FALSE];
    [openDlg setAllowedFileTypes:@[@"cer", @"CER", @"p8"]];
    
    [openDlg beginSheetModalForWindow:[[NSApplication sharedApplication] windows].firstObject completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK)
        {
            complete( [[[openDlg URLs] objectAtIndex:0] path]);
        } else {
            complete(nil);
        }
    }];
}

#pragma mark --alert
- (void)showMessage:(NSString*)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        
    }];
    
}

- (void)showAlert:(NSAlertStyle)style title:(NSString *)title message:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:style];
    [alert runModal];
}
#pragma mark - Logging

- (void)log:(NSString *)message warning:(BOOL)warning {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (message.length>0) {
            NSDictionary *attributes = @{NSForegroundColorAttributeName:warning?[NSColor redColor]:([self isDarkMode]?[NSColor whiteColor]:[NSColor blackColor]) , NSFontAttributeName: [NSFont systemFontOfSize:12]};
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:message attributes:attributes];
            [self.logTextView.textStorage appendAttributedString:string];
            [self.logTextView.textStorage.mutableString appendString:@"\n"];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.textStorage.length - 1, 1)];
        }
    });
}

#pragma mark -- text field delegate

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
}

- (void)controlTextDidChange:(NSNotification *)obj {
    
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}
 
- (BOOL)isDarkMode {
    if (@available(macOS 10.14, *)) {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
        BOOL isDarkMode = [[dict objectForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"];
        return isDarkMode;
    }
    return NO;
}
@end
