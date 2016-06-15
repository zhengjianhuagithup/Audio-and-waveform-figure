//
//  GetRecorderAndDraw.m
//  录音与播放
//
//  Created by tusm on 16/6/15.
//  Copyright © 2016年 tusm. All rights reserved.
//

#import "GetRecorderAndDraw.h"
#import <AVFoundation/AVFoundation.h>

@interface GetRecorderAndDraw ()

@property (nonatomic,retain)NSMutableData *audioData;  //音频数据
@property (nonatomic,retain)NSMutableArray *cutDataMA; //保存缩减后的数据
@end

@implementation GetRecorderAndDraw



- (NSData *)getRecorderDataFromURL:(NSURL *)url {
    
    NSMutableData *data = [[NSMutableData alloc]init];     //用于保存音频数据
    AVAsset *asset = [AVAsset assetWithURL:url];           //从路径获取音频文件
  
    NSError *error;
    AVAssetReader *reader = [[AVAssetReader alloc]initWithAsset:asset error:&error]; //创建读取
    if (!reader) {
        
        NSLog(@"%@",[error localizedDescription]);
    }
    
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//从媒体中得到声音轨道
    //读取配置
    NSDictionary *dic   = @{AVFormatIDKey            :@(kAudioFormatLinearPCM),
                            AVLinearPCMIsBigEndianKey:@NO,
                            AVLinearPCMIsFloatKey    :@NO,
                            AVLinearPCMBitDepthKey   :@(16)
                            };
    //读取输出，在相应的轨道和输出对应格式的数据
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:dic];
    //赋给读取并开启读取
    [reader addOutput:output];
    [reader startReading];
    
    //读取是一个持续的过程，每次只读取后面对应的大小的数据。当读取的状态发生改变时，其status属性会发生对应的改变，我们可以凭此判断是否完成文件读取
    while (reader.status == AVAssetReaderStatusReading) {
        
        CMSampleBufferRef  sampleBuffer = [output copyNextSampleBuffer]; //读取到数据
        if (sampleBuffer) {
            
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);   //返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
            [data appendBytes:sampleBytes length:length];                 //将数据附加到data中
            CMSampleBufferInvalidate(sampleBuffer);  //销毁
            CFRelease(sampleBuffer);                 //释放
        }
    }
    if (reader.status == AVAssetReaderStatusCompleted) {
        
        self.audioData = data;

    }else{
        
        NSLog(@"获取音频数据失败");
        return nil;
    }
    
    //开始绘制波形图，重写了draw方法
    [self setNeedsDisplay];
    return data;

    
}

//缩减音频
- (NSArray *)cutAudioData:(CGSize)size {
    
    NSMutableArray *filteredSamplesMA = [[NSMutableArray alloc]init];
    NSData *data = [self getRecorderDataFromURL:self.url];
    NSUInteger  sampleCount = data.length / sizeof(SInt16);           //计算所有数据个数
    NSUInteger  binSize     = sampleCount / size.width;               //将数据分割，也就是按照我们的需求width将数据分为一个个小包
    
    SInt16 *bytes = (SInt16 *)self.audioData.bytes;                   //总的数据个数
    SInt16 maxSample = 0;                                             //sint16两个字节的空间
    
    //以binSize为一个样本。每个样本中取一个最大数。也就是在固定范围取一个最大的数据保存，达到缩减目的
    for (NSUInteger i= 0; i < sampleCount; i += binSize) {//在sampleCount（所有数据）个数据中抽样，抽样方法为在binSize个数据为一个样本，在样本中选取一个数据
        
        SInt16 sampleBin [binSize];
        for (NSUInteger j = 0; j < binSize; j++) {//先将每次抽样样本的binSize个数据遍历出来
            
            sampleBin[j] = CFSwapInt16LittleToHost(bytes[i + j]);
            
        }
        //选取样本数据中最大的一个数据
        SInt16 value = [self maxValueInArray:sampleBin ofSize:binSize];
        //保存数据
        [filteredSamplesMA addObject:@(value)];
        //将所有数据中的最大数据保存，作为一个参考。可以根据情况对所有数据进行“缩放”
        if (value > maxSample) {
            
            maxSample = value;
        }
    }
    //计算比例因子
    CGFloat scaleFactor = (size.height/2)/maxSample;
    //对所有数据进行“缩放”
    for (NSUInteger i = 0; i < filteredSamplesMA.count; i++) {
        
        filteredSamplesMA[i] = @([filteredSamplesMA[i] integerValue] * scaleFactor);
    }
    
    [self setNeedsDisplay];
    NSLog(@"filteredSamplesMA====%ld",filteredSamplesMA.count);
    return filteredSamplesMA;
}

//比较大小的方法，返回最大值
- (SInt16)maxValueInArray:(SInt16[])values ofSize:(NSUInteger)size {
    
    SInt16 maxvalue = 0;
    for (int i = 0; i < size; i++) {
        
        if (abs(values[i] > maxvalue)) {
            
            maxvalue = abs(values[i]);
        }
    }
    return maxvalue;
}

- (void)drawRect:(CGRect)rect  {
    
    CGContextRef context = UIGraphicsGetCurrentContext(); //当前上下文
    CGContextScaleCTM(context, 0.8, 0.8);                 //绘制区域相对于当前区域的比例，相当于缩放
    
    //缩放后将绘制图像移动
    CGFloat xOffset = self.bounds.size.width - (self.bounds.size.width*0.8);
    CGFloat yOffset = self.bounds.size.height - (self.bounds.size.height*0.8);
    CGContextTranslateCTM(context, xOffset/2, yOffset/2);
    
    NSArray *filerSamples = [self cutAudioData:self.bounds.size];      //得到绘制数据
    CGFloat midY = CGRectGetMidY(rect);                                //得到中心y的坐标
    CGMutablePathRef halfPath = CGPathCreateMutable();                 //绘制路径
    CGPathMoveToPoint(halfPath, nil, 0.0f, midY);      //在路径上移动当前画笔的位置到一个点，这个点由CGPoint 类型的参数指定。

    for (NSUInteger i = 0; i < filerSamples.count; i ++) {
        
        float sample = [filerSamples[i] floatValue];
        CGPathAddLineToPoint(halfPath, NULL, i, midY - sample);   //从当前的画笔位置向指定位置（同样由CGPoint类型的值指定）绘制线段
    }
    
    CGPathAddLineToPoint(halfPath, NULL, filerSamples.count, midY); //重置起点

    //实现波形图反转
    CGMutablePathRef fullPath = CGPathCreateMutable();//创建新路径
    CGPathAddPath(fullPath, NULL, halfPath);          //合并路径
    
    CGAffineTransform transform = CGAffineTransformIdentity; //反转
    //反转配置
    transform = CGAffineTransformTranslate(transform, 0, CGRectGetHeight(rect));
    transform = CGAffineTransformScale(transform, 1.0, -1.0);
    CGPathAddPath(fullPath, &transform, halfPath);
    
    //将路径添加到上下文中
    CGContextAddPath(context, fullPath);
    //绘制颜色
    CGContextSetFillColorWithColor(context, [UIColor cyanColor].CGColor);
    //开始绘制
    CGContextDrawPath(context, kCGPathFill);
    
    //移除
    CGPathRelease(halfPath);
    CGPathRelease(fullPath);
    [super drawRect:rect];

}





//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
