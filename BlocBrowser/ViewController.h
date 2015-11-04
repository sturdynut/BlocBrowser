//
//  ViewController.h
//  BlocBrowser
//
//  Created by Matti Salokangas on 10/25/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

/* Refreshes the web view.
    - Erases history
    - Updates URL field and toolbar buttons accordingly
*/
- (void) resetWebView;
/* Shows the welcome message */
- (void) showWelcomeMessage;

@end

