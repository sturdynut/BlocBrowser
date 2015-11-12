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
#import "FloatingToolbar.h"

#define kWebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define kWebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define kWebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define kWebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload command")

@interface ViewController () <WKNavigationDelegate, UITextFieldDelegate, FloatingToolbarDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) CustomUITextField *textField;
@property (nonatomic, strong) FloatingToolbar *floatingToolbar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@end

@implementation ViewController

#pragma mark - UIViewController

-(void)showWelcomeMessage {
    NSString *welcomeMessage = NSLocalizedString(@"Welcome to the Internet.", "Welcome message");
    
    UIAlertController *alert =  [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Welcome", "Welcome")
                                                                    message:welcomeMessage
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)resetWebView {
    [self.webView removeFromSuperview];
    [self loadView];
    
    [self onStateChanged];
}

- (void)loadView {
    UIView *mainView = [UIView new];
    
    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;
    
    [self initUrlField];
    [self initFloatingToolbar];
    [self initViews:mainView];
    [self initLoader];
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self layoutViews];
}

#pragma mark - CustomTextField

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *urlString = textField.text;
    NSURL *url = [NSURL URLWithString: urlString];
    
    // Check if user entered http://
    //   - This may also be a search, e.g. User entered "cute kittens"
    if (!url.scheme) {
        NSString *searchQueryPrefix = @"";
        NSDataDetector *urlDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *urlMatches = [urlDetector matchesInString:urlString options:NSMatchingAnchored range:NSMakeRange(0, urlString.length)];
        
        if ([urlMatches count] == 0) {
            // This is not a URL, prepend with a google query
            searchQueryPrefix = @"google.com/search?q=";
            // Url encode the search request, just replace spaces with +'s for now.
            urlString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        }
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", searchQueryPrefix, urlString]];
    }
    
    if (url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
    
    return NO;
}

#pragma mark - WKNavigationDelegate

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webView:webView didFailNavigation:navigation withError:error];
    
    [self onStateChanged];
}

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    BOOL hasError = error.code != NSURLErrorCancelled;
    
    if (hasError) {
        UIAlertController *alert =  [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", "Error")
                                                                    message:[error localizedDescription]
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleCancel handler:nil];
    
        [alert addAction:okAction];
    
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [self onStateChanged];
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self onStateChanged];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self onStateChanged];
}

#pragma mark - FloatingToolbarDelegate

- (void) floatingToolbar:(FloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:kWebBrowserBackString]) {
        [self.webView goBack];
    } else if ([title isEqual:kWebBrowserForwardString]) {
        [self.webView goForward];
    } else if ([title isEqual:kWebBrowserStopString]) {
        [self.webView stopLoading];
    } else if ([title isEqual:kWebBrowserRefreshString]) {
        [self.webView reload];
    }
}

- (void) floatingToolbar:(FloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    if (CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        toolbar.frame = potentialNewFrame;
    }
}

- (void) floatingToolbar:(FloatingToolbar *)toolbar didTryToPinchWithScale:(CGFloat)scale {
    toolbar.transform = CGAffineTransformMakeScale(scale, scale);
}

#pragma mark - Helpers

-(void) initLoader {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

-(void) initUrlField {
    self.textField = [[CustomUITextField alloc] init];
    self.textField.padding = 10;
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Enter url or search terms...", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:240/255.0f alpha:1];
    self.textField.delegate = self;
}

-(void) initFloatingToolbar {
    self.floatingToolbar = [[FloatingToolbar alloc] initWithFourTitles:@[kWebBrowserBackString, kWebBrowserForwardString, kWebBrowserStopString, kWebBrowserRefreshString]];
    self.floatingToolbar.delegate = self;
}

-(void) initViews:(UIView *)mainView {
    NSArray *subViews = @[self.webView, self.textField, self.floatingToolbar];
    
    for (UIView *view in subViews) {
        [mainView addSubview:view];
    }
}

-(void) layoutViews {
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight - itemHeight;
    
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    CGFloat toolbarWidth = width * .75;
    CGFloat toolbarX = (width - toolbarWidth) / 2;
    CGFloat toolbarY = CGRectGetMaxY(self.webView.bounds);
    
    self.floatingToolbar.frame = CGRectMake(toolbarX, toolbarY, toolbarWidth, 60);
}

-(void) onStateChanged {
    NSString *webpageTitle = [self.webView.title copy];
    self.title = [webpageTitle length] ? webpageTitle : self.webView.URL.absoluteString;
    
    [self.floatingToolbar setEnabled:[self.webView canGoBack] forButtonWithTitle:kWebBrowserBackString];
    [self.floatingToolbar setEnabled:[self.webView canGoForward] forButtonWithTitle:kWebBrowserForwardString];
    [self.floatingToolbar setEnabled:[self.webView isLoading] forButtonWithTitle:kWebBrowserStopString];
    [self.floatingToolbar setEnabled:![self.webView isLoading] && self.webView.URL forButtonWithTitle:kWebBrowserRefreshString];
    
    if (self.webView.isLoading) {
        [self.activityIndicator startAnimating];
    }
    else {
        [self.activityIndicator stopAnimating];
    }
}

@end
