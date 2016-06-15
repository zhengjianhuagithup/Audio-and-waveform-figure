//
//  ViewController.m
//  录音与播放
//
//  Created by tusm on 16/6/11.
//  Copyright © 2016年 tusm. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GetRecorderAndDraw.h"

@interface ViewController ()

@property (nonatomic,retain)AVAudioRecorder *recorder;         //录音器
@property (nonatomic,retain)NSDictionary    *setRecorderDic;   //用于配置音频信息
@property (nonatomic,retain)NSString        *filePath;         //音频路径
@property (nonatomic,retain)AVAudioPlayer   *player;           //播放器
@property (nonatomic,retain)GetRecorderAndDraw *getrecorder;
@property (nonatomic,assign)BOOL            isRecorder;       //用于判断是否在录制
@end

@implementation ViewController

- (AVAudioRecorder *)recorder {
    
    if (!_recorder) {
        
        //配置recoder，配置条件为URL（保存文件的路径），字典（字典中存储音频的相关信息，如格式，音频质量等）
        NSURL *url    = [NSURL fileURLWithPath:self.filePath];
        NSError *error;
        _recorder     = [[AVAudioRecorder alloc]initWithURL:url settings:self.setRecorderDic error:&error];
    }
    return _recorder;
}

- (NSDictionary *)setRecorderDic {
    
    if (!_setRecorderDic) {
        
        _setRecorderDic = @{AVFormatIDKey  : @(kAudioFormatAppleIMA4),       //格式
                            AVSampleRateKey: @44100.0f,                      //采样率
                            AVNumberOfChannelsKey   : @1,                    //通道数（单通道或立体声）
                            AVEncoderBitDepthHintKey: @16,                   //采样位深（和声音强度有关）
                            AVEncoderAudioQualityKey: @(AVAudioQualityMedium)}; //音频的质量
    }
    return _setRecorderDic;
}



- (NSString *)filePath {
    
    if (!_filePath) {
        
        //配置录制的声音存储的位置以及文件名称
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"yyy-MM-dd HH:mm:ss"];
        NSString *str = [formatter stringFromDate:[NSDate date]];
        _filePath     = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf",str]];
        NSLog(@"%@",_filePath);
    }
    return _filePath;
}




- (void)viewDidLoad {
    [super viewDidLoad];

}

//开始按钮
- (IBAction)startBTAction:(UIButton *)sender {
    
    //开启录制
    if (self.recorder && self.isRecorder == NO) {
        
        [self.recorder prepareToRecord];
        [self.recorder record];
        [sender setTitle:@"停止录制" forState:UIControlStateSelected];
        sender.selected = YES;
        self.isRecorder = YES;
        NSLog(@"录制启动成功");
    } else {
        
        //停止录制
        sender.selected = NO;
        self.isRecorder = NO;
        [self.recorder stop];
    }
}

//停止按钮
- (IBAction)endBTAction:(id)sender {
    
    //暂停录制
    [self.recorder stop];
}

//播放按钮
- (IBAction)playerBTAction:(id)sender {
    
    //录制完的播放控制，通过路径找到对应的录制文件
    [self.player stop];
    NSError *error;
    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:self.filePath] error:&error];
    
    if (self.player) {
        
        [self.player play];
    }
}

//波形图按钮,点击添加波形图界面并绘制波形图
- (IBAction)waveform:(UIButton *)sender {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL hasFile = [manager fileExistsAtPath:self.filePath];
    if (hasFile) {
        
        self.getrecorder = [[GetRecorderAndDraw alloc]init];
        self.getrecorder.url   = [NSURL fileURLWithPath:self.filePath];
        self.getrecorder.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width);
        [self.view addSubview:self.getrecorder];
        self.getrecorder.backgroundColor = [UIColor orangeColor];
        
    }else {
        
        UIAlertView *alerview = [[UIAlertView alloc]initWithTitle:@"没有音频" message:@"请先录制，再点结束" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [alerview show];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
