//
//  CustomUITextField.m
//  BlocBrowser
//
//  Created by Matti Salokangas on 10/30/15.
//  Copyright © 2015 Sturdy Nut. All rights reserved.
//

#import "CustomUITextField.h"

@implementation CustomUITextField

@synthesize padding;

-(CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, padding, padding);
}

-(CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

@end
