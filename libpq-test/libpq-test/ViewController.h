//
//  ViewController.h
//  libpq-test
//
//  Created by nunzio on 4/13/17.
//  Copyright © 2017 Workflow Products, L.L.C. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (IBAction)buttonClick:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *connstring;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
 
