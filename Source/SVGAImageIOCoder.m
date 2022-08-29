//
//  SVGAImageIOCoder.h
//  SVGAPlayer
//
//  Created by laowu on 2022/8/26.
//  Copyright © 202022年 UED Center. All rights reserved.
//

#import "SVGAImageIOCoder.h"
#import <ImageIO/ImageIO.h>

@interface SVGAImageIOCoder ()

@end

@implementation SVGAImageIOCoder


+ (UIImage *)decode:(NSData*)data scale:(CGFloat)scale options:(NSDictionary *)options {
    
    if (data == nil || data.length == 0) {
        return  nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    if (!source || count == 0) {
        return nil;
    }
    size_t index = 0;
    // Some options need to pass to `CGImageSourceCopyPropertiesAtIndex` before `CGImageSourceCreateImageAtIndex`, or ImageIO will ignore them because they parse once :)
    // Parse the image properties
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    CGFloat pixelWidth = 0.0;
    CGFloat pixelHeight = 0.0;
    CGImagePropertyOrientation exifOrientation = kCGImagePropertyOrientationUp;
    
    if (properties != nil) {
        pixelWidth = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
        pixelHeight = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
        exifOrientation = (CGImagePropertyOrientation)[properties[(__bridge NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    }
    if (!exifOrientation) {
        exifOrientation = kCGImagePropertyOrientationUp;
    }
    NSMutableDictionary *decodingOptions;
    if (options) {
        decodingOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    } else {
        decodingOptions = [NSMutableDictionary dictionary];
    }
    CGImageRef imageRef;
    
    imageRef = CGImageSourceCreateImageAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    
    if (!imageRef) {
        return nil;
    }
    
    UIImageOrientation imageOrientation = [SVGAImageIOCoder imageOrientationFromEXIFOrientation:exifOrientation];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];

    CGImageRelease(imageRef);
    return image;
}

// Convert an EXIF image orientation to an iOS one.
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(CGImagePropertyOrientation)exifOrientation {
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case kCGImagePropertyOrientationUp:
            imageOrientation = UIImageOrientationUp;
            break;
        case kCGImagePropertyOrientationDown:
            imageOrientation = UIImageOrientationDown;
            break;
        case kCGImagePropertyOrientationLeft:
            imageOrientation = UIImageOrientationLeft;
            break;
        case kCGImagePropertyOrientationRight:
            imageOrientation = UIImageOrientationRight;
            break;
        case kCGImagePropertyOrientationUpMirrored:
            imageOrientation = UIImageOrientationUpMirrored;
            break;
        case kCGImagePropertyOrientationDownMirrored:
            imageOrientation = UIImageOrientationDownMirrored;
            break;
        case kCGImagePropertyOrientationLeftMirrored:
            imageOrientation = UIImageOrientationLeftMirrored;
            break;
        case kCGImagePropertyOrientationRightMirrored:
            imageOrientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return imageOrientation;
}


@end
