//
//  FloatingToolbar.h
//  BlocBrowser
//
//  Created by Matti Salokangas on 11/4/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FloatingToolbar;

@protocol FloatingToolbarDelegate <NSObject>

@optional

- (void) floatingToolbar:(FloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title;
- (void) floatingToolbar:(FloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset;

@end

@interface FloatingToolbar : UIView

- (instancetype) initWithFourTitles:(NSArray *)titles;

- (void) setEnabled:(BOOL)enabled forButtonWithTitle:(NSString *)title;

@property (nonatomic, weak) id <FloatingToolbarDelegate> delegate;

@end
