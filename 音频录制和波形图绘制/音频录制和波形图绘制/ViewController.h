//
//  ViewController.h
//  录音与播放
//
//  Created by tusm on 16/6/11.
//  Copyright © 2016年 tusm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *startBT;
@property (weak, nonatomic) IBOutlet UIButton *endBT;
- (IBAction)startBTAction:(UIButton *)sender;
- (IBAction)endBTAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *playerBT;
- (IBAction)playerBTAction:(UIButton *)sender;

@end

