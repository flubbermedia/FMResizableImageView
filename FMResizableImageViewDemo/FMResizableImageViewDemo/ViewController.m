//
//  ViewController.m
//  FMResizableImageViewDemo
//
//  Created by Andrea Ottolina on 20/09/2012.
//  Copyright (c) 2012 Flubber Media Ltd. All rights reserved.
//

#import "ViewController.h"
#import "FMResizableImageView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)addImageView:(id)sender
{
	UIImage *contentImage = [UIImage imageNamed:@"demo"];
	FMResizableImageView *imageView = [[FMResizableImageView alloc] initWithImage:contentImage];
	imageView.center  = self.view.center;
	
	[self.view addSubview:imageView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
