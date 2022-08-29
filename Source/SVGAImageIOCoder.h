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

typedef NSInteger SVGAImageFormat NS_TYPED_EXTENSIBLE_ENUM;
static const SVGAImageFormat SVGAImageFormatUndefined = -1;
static const SVGAImageFormat SVGAImageFormatJPEG      = 0;
static const SVGAImageFormat SVGAImageFormatPNG       = 1;
static const SVGAImageFormat SVGAImageFormatGIF       = 2;
static const SVGAImageFormat SVGAImageFormatTIFF      = 3;
static const SVGAImageFormat SVGAImageFormatWebP      = 4;
static const SVGAImageFormat SVGAImageFormatHEIC      = 5;
static const SVGAImageFormat SVGAImageFormatHEIF      = 6;
static const SVGAImageFormat SVGAImageFormatPDF       = 7;
static const SVGAImageFormat SVGAImageFormatSVG       = 8;

// AVFileTypeHEIC/AVFileTypeHEIF is defined in AVFoundation via iOS 11, we use this without import AVFoundation
#define kSVGAUTTypeHEIC  ((__bridge CFStringRef)@"public.heic")
#define kSVGAUTTypeHEIF  ((__bridge CFStringRef)@"public.heif")
// HEIC Sequence (Animated Image)
#define kSVGAUTTypeHEICS ((__bridge CFStringRef)@"public.heics")
// kSDUTTypeWebP seems not defined in public UTI framework, Apple use the hardcode string, we define them :)
#define kSVGAUTTypeWebP  ((__bridge CFStringRef)@"org.webmproject.webp")

#define kSVGAUTTypeImage ((__bridge CFStringRef)@"public.image")
#define kSVGAUTTypeJPEG  ((__bridge CFStringRef)@"public.jpeg")
#define kSVGAUTTypePNG   ((__bridge CFStringRef)@"public.png")
#define kSVGAUTTypeTIFF  ((__bridge CFStringRef)@"public.tiff")
#define kSVGAUTTypeSVG   ((__bridge CFStringRef)@"public.svg-image")
#define kSVGAUTTypeGIF   ((__bridge CFStringRef)@"com.compuserve.gif")
#define kSVGAUTTypePDF   ((__bridge CFStringRef)@"com.adobe.pdf")


#define svga_metamacro_concat(A, B) \
        svga_metamacro_concat_(A, B)
#define svga_metamacro_concat_(A, B) A ## B

#if DEBUG
#define svga_keywordify autoreleasepool {}
#else
#define svga_keywordify try {} @catch (...) {}
#endif

#ifndef didExit
#define didExit \
svga_keywordify \
__strong svga_cleanupBlock_t svga_metamacro_concat(svga_exitBlock_, __LINE__) __attribute__((cleanup(svga_executeCleanupBlock), unused)) = ^
#endif

typedef void (^svga_cleanupBlock_t)(void);

#if defined(__cplusplus)
extern "C" {
#endif
    void svga_executeCleanupBlock (__strong svga_cleanupBlock_t *block);
#if defined(__cplusplus)
}
#endif



@interface SVGAImageIOCoder : NSObject

+ (UIImage *)createFrameAtIndex:(NSUInteger)index source:(CGImageSourceRef)source scale:(CGFloat)scale preserveAspectRatio:(BOOL)preserveAspectRatio thumbnailSize:(CGSize)thumbnailSize options:(NSDictionary *)options;

@end
