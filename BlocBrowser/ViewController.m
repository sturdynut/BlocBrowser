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
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@end

@implementation ViewController

#pragma mark - UIViewController

- (void)loadView {
    UIView *mainView = [UIView new];
    
    self.webView = [[WKWebView alloc] init];
    self.webView.navigationDelegate = self;
    
    [self initUrlField];
    [self initNavigationButtons];
    [self initViews:mainView];
    [self initLoader];
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
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

#pragma mark - Helpers

-(void) initLoader {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

-(void) initNavigationButtons {
    self.backButton = [self setupNavButton:self.backButton title:@"Back" action:@selector(goBack)];
    self.forwardButton = [self setupNavButton:self.forwardButton title:@"Forward" action:@selector(goForward)];
    self.stopButton = [self setupNavButton:self.stopButton title:@"Stop" action:@selector(stopLoading)];
    self.reloadButton = [self setupNavButton:self.reloadButton title:@"Refresh" action:@selector(reload)];
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

-(void) initViews:(UIView *)mainView {
    NSArray *subViews = @[self.webView, self.textField, self.backButton, self.forwardButton, self.stopButton, self.reloadButton];
    
    for (UIView *view in subViews) {
        [mainView addSubview:view];
    }
}

-(void) layoutViews {
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight - itemHeight;
    CGFloat buttonWidth = CGRectGetWidth(self.view.bounds) / 4;
    
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    [self layoutNavButtons:buttonWidth height:itemHeight];
}

-(void) layoutNavButtons:(CGFloat)width height:(CGFloat)height {
    CGFloat currentButtonX = 0;
    
    for (UIButton *thisButton in @[self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        thisButton.frame = CGRectMake(currentButtonX, CGRectGetMaxY(self.webView.frame), width, height);
        currentButtonX += width;
    }
}

-(void) onStateChanged {
    NSString *webpageTitle = [self.webView.title copy];
    self.title = [webpageTitle length] ? webpageTitle : self.webView.URL.absoluteString;
    
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    self.stopButton.enabled = self.webView.isLoading;
    self.reloadButton.enabled = !self.webView.isLoading;
    
    if (self.webView.isLoading) {
        [self.activityIndicator startAnimating];
    }
    else {
        [self.activityIndicator stopAnimating];
    }
}

-(UIButton *) setupNavButton:(UIButton *)button title:(NSString *)title action:(SEL)action {
    NSString *titleDescription = [NSString stringWithFormat:@"%@ command", title];
    
    button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setEnabled:NO];
    [button setTitle:NSLocalizedString(title, titleDescription) forState:UIControlStateNormal];
    [button addTarget:self.webView action:action forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

@end
