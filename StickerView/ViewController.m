//
//  ViewController.m
//  StickerView
//
//  Created by Iftekhar Mac Pro on 8/19/13.
//  Copyright (c) 2013 Canopus. All rights reserved.
//

#import "ViewController.h"
#import "IQStickerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /**/
    IQStickerView *stickerView = [[IQStickerView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sample1.jpeg"]];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [stickerView setContentView:imageView];
    [self.view addSubview:stickerView];
    /**/
    
    
    
    /**/
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    [aView setBackgroundColor:[UIColor greenColor]];
    [aView setClipsToBounds:YES];
    
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 20, 120, 20)];
    [aLabel setAutoresizingMask:(UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin)];
    [aLabel setText:@"Sample Text"];
    [aView addSubview:aLabel];
    
    UIButton *aButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [aButton setAutoresizingMask:(UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin)];
    [aButton setTitle:@"Sample Button" forState:UIControlStateNormal];
    [aButton setFrame:CGRectMake(30, 140, 120, 30)];
    [aView addSubview:aButton];
    
    UIScrollView *scrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 160, 200, 40)];
    [scrollview setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleHeight)];
    [scrollview setBackgroundColor:[UIColor greenColor]];
    [scrollview setContentSize:CGSizeMake(200, 200)];
    [aView addSubview:scrollview];
    
    IQStickerView *stickerView1 = [[IQStickerView alloc] initWithFrame:CGRectMake(120, 10, 180, 180)];
    [stickerView1 setContentView:aView];
    [self.view addSubview:stickerView1];
    /**/
    
    /**/
    anView = [[UIView alloc] initWithFrame:scrollViewSample.bounds];
    [aView setUserInteractionEnabled:YES];
    [anView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
    [scrollViewSample addSubview:anView];
    
    IQStickerView *stickerView2 = [[IQStickerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [stickerView2 setCenter:anView.center];
    UIImageView *imageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sample2.jpeg"]];
    [imageView2 setContentMode:UIViewContentModeScaleAspectFit];
    [stickerView2 setContentView:imageView2];
    [anView addSubview:stickerView2];
    /**/
    
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    //Control size maintenance.
    for (IQStickerView *sticker in anView.subviews)
        if ([sticker isKindOfClass:[IQStickerView class]])
            [sticker refresh];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return anView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    scrollViewSample = nil;
    [super viewDidUnload];
}



@end
