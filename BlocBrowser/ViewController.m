//
//  ViewController.m
//  BlocBrowser
//
//  Created by Matti Salokangas on 10/25/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "CustomUITextField.h"

@interface ViewController () <WKNavigationDelegate, UITextFieldDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) CustomUITextField *textField;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *reloadButton;
@end

@implementation ViewController

#pragma mark - UIViewController

- (void)loadView {
    UIView *mainView = [UIView new];
    
    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;
    
    self.textField = [[CustomUITextField alloc] init];
    self.textField.padding = 10;
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"http://", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:240/255.0f alpha:1];
    self.textField.delegate = self;
    
    self.backButton = [self setupNavButton:self.backButton withTitleKey:@"Back" andDesc:@"Back command" withAction:@selector(goBack)];
    self.forwardButton = [self setupNavButton:self.forwardButton withTitleKey:@"Forward" andDesc:@"Forward command" withAction:@selector(goForward)];
    self.stopButton = [self setupNavButton:self.stopButton withTitleKey:@"Stop" andDesc:@"Stop command" withAction:@selector(stopLoading)];
    self.reloadButton = [self setupNavButton:self.reloadButton withTitleKey:@"Refresh" andDesc:@"Refresh command" withAction:@selector(reload)];
    
    NSArray *subViews = @[self.webView, self.textField, self.backButton, self.forwardButton, self.stopButton, self.reloadButton];
    
    [self addSubViews:subViews toMainView:mainView];
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight - itemHeight;
    CGFloat buttonWidth = CGRectGetWidth(self.view.bounds) / 4;
    
    
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    CGFloat currentButtonX = 0;
    
    for (UIButton *thisButton in @[self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        thisButton.frame = CGRectMake(currentButtonX, CGRectGetMaxY(self.webView.frame), buttonWidth, itemHeight);
        currentButtonX += buttonWidth;
    }
}

#pragma mark - CustomTextField

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    
    NSURL *URL = [NSURL URLWithString: URLString];
    
    if (!URL.scheme) {
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
    }
    
    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webView loadRequest:request];
    }
    
    return NO;
}

#pragma mark - WKNavigationDelegate

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webView:webView didFailNavigation:navigation withError:error];
}

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled) {
        return;
    }
    
    UIAlertController *alert =  [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", "Error")
                                                                    message:[error localizedDescription]
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Helpers

-(UIButton *) setupNavButton:(UIButton *)button withTitleKey:(NSString *)titleKey andDesc:(NSString *)titleDesc withAction:(SEL)action {
    button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setEnabled:NO];
    [button setTitle:NSLocalizedString(titleKey, titleDesc) forState:UIControlStateNormal];
    [button addTarget:self.webView action:action forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

-(void) addSubViews:(NSArray *)subviews toMainView:(UIView *)mainView {
    for (UIView *view in subviews) {
        [mainView addSubview:view];
    }
}

@end
