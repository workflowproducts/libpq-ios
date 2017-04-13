//
//  ViewController.m
//  libpq-test
//
//  Created by nunzio on 4/13/17.
//  Copyright © 2017 Workflow Products, L.L.C. All rights reserved.
//

#import "ViewController.h"
#include "libpq-fe.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	
	// Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


- (IBAction)buttonClick:(id)sender {
    
    PGconn *conn = PQconnectdb([_connstring.text cStringUsingEncoding:NSUTF8StringEncoding]);
    if (PQstatus(conn) == CONNECTION_BAD) {
        _textView.text = [NSString stringWithUTF8String: PQerrorMessage(conn)];
    } else {
        _textView.text = @"Success";
    }
    
    PQfinish(conn);
}
@end
