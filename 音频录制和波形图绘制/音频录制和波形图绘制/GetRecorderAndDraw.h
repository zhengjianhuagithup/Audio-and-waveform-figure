//
//  GetRecorderAndDraw.h
//  录音与播放
//
//  Created by tusm on 16/6/15.
//  Copyright © 2016年 tusm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GetRecorderAndDraw : UIView
@property (nonatomic,retain)NSURL *url;
- (NSData *)getRecorderDataFromURL:(NSURL *)url;
- (void)drawRect:(CGRect)rect;
@end
