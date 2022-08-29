//
//  SVGAImageIOCoder.h
//  SVGAPlayer
//
//  Created by laowu on 2022/8/26.
//  Copyright © 202022年 UED Center. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>

@interface SVGAImageIOCoder : NSObject

+ (UIImage *)decode:(NSData*)data scale:(CGFloat)scale options:(NSDictionary *)options;

@end
