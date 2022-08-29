//
//  SVGAImageIOCoder.h
//  SVGAPlayer
//
//  Created by laowu on 2022/8/26.
//  Copyright © 202022年 UED Center. All rights reserved.
//

#import "SVGAImageIOCoder.h"
#import <ImageIO/ImageIO.h>


static NSString * kSDCGImageSourceRasterizationDPI = @"kCGImageSourceRasterizationDPI";


void svga_executeCleanupBlock (__strong svga_cleanupBlock_t *block) {
    (*block)();
}

@interface SVGAImageIOCoder ()

@end

@implementation SVGAImageIOCoder


+ (SVGAImageFormat)svga_imageFormatFromUTType:(CFStringRef)uttype {
    if (!uttype) {
        return SVGAImageFormatUndefined;
    }
    SVGAImageFormat imageFormat;
    if (CFStringCompare(uttype, kSVGAUTTypeJPEG, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatJPEG;
    } else if (CFStringCompare(uttype, kSVGAUTTypePNG, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatPNG;
    } else if (CFStringCompare(uttype, kSVGAUTTypeGIF, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatGIF;
    } else if (CFStringCompare(uttype, kSVGAUTTypeTIFF, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatTIFF;
    } else if (CFStringCompare(uttype, kSVGAUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatWebP;
    } else if (CFStringCompare(uttype, kSVGAUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatHEIC;
    } else if (CFStringCompare(uttype, kSVGAUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatHEIF;
    } else if (CFStringCompare(uttype, kSVGAUTTypePDF, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatPDF;
    } else if (CFStringCompare(uttype, kSVGAUTTypeSVG, 0) == kCFCompareEqualTo) {
        imageFormat = SVGAImageFormatSVG;
    } else {
        imageFormat = SVGAImageFormatUndefined;
    }
    return imageFormat;
}

+ (UIImage *)createFrameAtIndex:(NSUInteger)index source:(CGImageSourceRef)source scale:(CGFloat)scale preserveAspectRatio:(BOOL)preserveAspectRatio thumbnailSize:(CGSize)thumbnailSize options:(NSDictionary *)options {
    // Some options need to pass to `CGImageSourceCopyPropertiesAtIndex` before `CGImageSourceCreateImageAtIndex`, or ImageIO will ignore them because they parse once :)
    // Parse the image properties
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    CGFloat pixelWidth = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
    CGFloat pixelHeight = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
    CGImagePropertyOrientation exifOrientation = (CGImagePropertyOrientation)[properties[(__bridge NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    if (!exifOrientation) {
        exifOrientation = kCGImagePropertyOrientationUp;
    }
    
    CFStringRef uttype = CGImageSourceGetType(source);
    // Check vector format
    BOOL isVector = NO;
    
    if ([SVGAImageIOCoder svga_imageFormatFromUTType:uttype] == SVGAImageFormatPDF) {
        isVector = YES;
    }

    NSMutableDictionary *decodingOptions;
    if (options) {
        decodingOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    } else {
        decodingOptions = [NSMutableDictionary dictionary];
    }
    CGImageRef imageRef;
    BOOL createFullImage = thumbnailSize.width == 0 || thumbnailSize.height == 0 || pixelWidth == 0 || pixelHeight == 0 || (pixelWidth <= thumbnailSize.width && pixelHeight <= thumbnailSize.height);
    if (createFullImage) {
        if (isVector) {
            if (thumbnailSize.width == 0 || thumbnailSize.height == 0) {
                // Provide the default pixel count for vector images, simply just use the screen size
                thumbnailSize = UIScreen.mainScreen.bounds.size;
            }
            CGFloat maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.height);
            NSUInteger DPIPerPixel = 2;
            NSUInteger rasterizationDPI = maxPixelSize * DPIPerPixel;
            decodingOptions[kSDCGImageSourceRasterizationDPI] = @(rasterizationDPI);
        }
        imageRef = CGImageSourceCreateImageAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    } else {
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform] = @(preserveAspectRatio);
        CGFloat maxPixelSize;
        if (preserveAspectRatio) {
            CGFloat pixelRatio = pixelWidth / pixelHeight;
            CGFloat thumbnailRatio = thumbnailSize.width / thumbnailSize.height;
            if (pixelRatio > thumbnailRatio) {
                maxPixelSize = thumbnailSize.width;
            } else {
                maxPixelSize = thumbnailSize.height;
            }
        } else {
            maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.height);
        }
        decodingOptions[(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(maxPixelSize);
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
        imageRef = CGImageSourceCreateThumbnailAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    }
    if (!imageRef) {
        return nil;
    }
    // Thumbnail image post-process
    if (!createFullImage) {
        if (preserveAspectRatio) {
            // kCGImageSourceCreateThumbnailWithTransform will apply EXIF transform as well, we should not apply twice
            exifOrientation = kCGImagePropertyOrientationUp;
        } else {
            // `CGImageSourceCreateThumbnailAtIndex` take only pixel dimension, if not `preserveAspectRatio`, we should manual scale to the target size
            CGImageRef scaledImageRef = [SVGAImageIOCoder CGImageCreateScaled:imageRef size:thumbnailSize];
            CGImageRelease(imageRef);
            imageRef = scaledImageRef;
        }
    }
    
    UIImageOrientation imageOrientation = [SVGAImageIOCoder imageOrientationFromEXIFOrientation:exifOrientation];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];

    CGImageRelease(imageRef);
    return image;
}

static inline size_t ByteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

+ (CGImageRef)CGImageCreateScaled:(CGImageRef)cgImage size:(CGSize)size {
    if (!cgImage) {
        return NULL;
    }
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    if (width == size.width && height == size.height) {
        CGImageRetain(cgImage);
        return cgImage;
    }
    
    __block vImage_Buffer input_buffer = {}, output_buffer = {};

    @didExit {
        if (input_buffer.data) free(input_buffer.data);
        if (output_buffer.data) free(output_buffer.data);
    };
    BOOL hasAlpha = [self CGImageContainsAlpha:cgImage];
    // iOS display alpha info (BGRA8888/BGRX8888)
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    vImage_CGImageFormat format = (vImage_CGImageFormat) {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = bitmapInfo,
        .version = 0,
        .decode = NULL,
        .renderingIntent = kCGRenderingIntentDefault,
    };
    
    vImage_Error a_ret = vImageBuffer_InitWithCGImage(&input_buffer, &format, NULL, cgImage, kvImageNoFlags);
    if (a_ret != kvImageNoError) return NULL;
    output_buffer.width = MAX(size.width, 0);
    output_buffer.height = MAX(size.height, 0);
    output_buffer.rowBytes = ByteAlign(output_buffer.width * 4, 64);
    output_buffer.data = malloc(output_buffer.rowBytes * output_buffer.height);
    if (!output_buffer.data) return NULL;
    
    vImage_Error ret = vImageScale_ARGB8888(&input_buffer, &output_buffer, NULL, kvImageHighQualityResampling);
    if (ret != kvImageNoError) return NULL;
    
    CGImageRef outputImage = vImageCreateCGImageFromBuffer(&output_buffer, &format, NULL, NULL, kvImageNoFlags, &ret);
    if (ret != kvImageNoError) {
        CGImageRelease(outputImage);
        return NULL;
    }
    
    return outputImage;
}

+ (BOOL)CGImageContainsAlpha:(CGImageRef)cgImage {
    if (!cgImage) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
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
