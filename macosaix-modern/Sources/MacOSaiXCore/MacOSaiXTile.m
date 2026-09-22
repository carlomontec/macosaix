#import "MacOSaiXTile.h"

@implementation MacOSaiXTile {
    NSMutableData *_targetPixelsData;
    NSMutableData *_maskPixelsData;
}

- (instancetype)initWithGeometry:(MacOSaiXTileGeometry *)geometry
{
    self = [super init];
    if (self) {
        _geometry = geometry;
        _bestScore = 1.0f; // 1.0 = worst match
        _bestImageIdentifier = nil;
        _bestImageURL = nil;
    }
    return self;
}

- (NSData *)targetPixels
{
    return _targetPixelsData;
}

- (NSData *)maskPixels
{
    return _maskPixelsData;
}

- (void)extractTargetThumbnailFromImage:(CGImageRef)targetImage
                             mosaicSize:(CGSize)mosaicSize
{
    const int size = 16;
    const int bytesPerRow = size * 4;
    _targetPixelsData = [NSMutableData dataWithLength:size * bytesPerRow];
    unsigned char *buffer = (unsigned char *)_targetPixelsData.mutableBytes;
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(buffer,
                                                 size,
                                                 size,
                                                 8,
                                                 bytesPerRow,
                                                 rgbColorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(rgbColorSpace);
    
    if (!context) return;
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    const size_t imgWidth = CGImageGetWidth(targetImage);
    const size_t imgHeight = CGImageGetHeight(targetImage);
    
    if (imgWidth == 0 || imgHeight == 0 || mosaicSize.width <= 0.0 || mosaicSize.height <= 0.0) {
        CGContextRelease(context);
        return;
    }
    
    CGRect bounds = _geometry.bounds;
    
    const double scaleX = (double)imgWidth / (double)mosaicSize.width;
    const double scaleY = (double)imgHeight / (double)mosaicSize.height;
    
    // Scale from mosaic size to target image pixel size
    double rawX = bounds.origin.x * scaleX;
    double rawY = bounds.origin.y * scaleY;
    double rawW = bounds.size.width * scaleX;
    double rawH = bounds.size.height * scaleY;
    
    // Clamp to valid image pixel coordinates
    if (rawX < 0.0) { rawW += rawX; rawX = 0.0; }
    if (rawY < 0.0) { rawH += rawY; rawY = 0.0; }
    if (rawX + rawW > (double)imgWidth) { rawW = (double)imgWidth - rawX; }
    if (rawY + rawH > (double)imgHeight) { rawH = (double)imgHeight - rawY; }
    
    if (rawW > 0.5 && rawH > 0.5) {
        size_t intX = (size_t)floor(rawX);
        size_t intY = (size_t)floor(rawY);
        size_t intW = (size_t)ceil(rawW);
        size_t intH = (size_t)ceil(rawH);
        
        if (intX >= imgWidth) intX = imgWidth - 1;
        if (intY >= imgHeight) intY = imgHeight - 1;
        if (intX + intW > imgWidth) intW = imgWidth - intX;
        if (intY + intH > imgHeight) intH = imgHeight - intY;
        
        if (intW > 0 && intH > 0) {
            CGRect cropRect = CGRectMake(intX, intY, intW, intH);
            CGImageRef subImage = CGImageCreateWithImageInRect(targetImage, cropRect);
            if (subImage) {
                CGContextDrawImage(context, CGRectMake(0, 0, size, size), subImage);
                CGImageRelease(subImage);
            } else {
                CGContextDrawImage(context, CGRectMake(0, 0, size, size), targetImage);
            }
        } else {
            CGContextDrawImage(context, CGRectMake(0, 0, size, size), targetImage);
        }
    } else {
        CGContextDrawImage(context, CGRectMake(0, 0, size, size), targetImage);
    }
    
    CGContextRelease(context);
}

- (void)rasterizeMaskWithResolution:(int)resolution
{
    const int size = (resolution > 0) ? resolution : 16;
    const int bytesPerRow = size;
    _maskPixelsData = [NSMutableData dataWithLength:size * bytesPerRow];
    unsigned char *buffer = (unsigned char *)_maskPixelsData.mutableBytes;
    
    CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(buffer,
                                                 size,
                                                 size,
                                                 8,
                                                 bytesPerRow,
                                                 graySpace,
                                                 kCGImageAlphaNone);
    CGColorSpaceRelease(graySpace);
    
    if (!context) return;
    
    // Clear to black (0)
    CGContextSetGrayFillColor(context, 0.0f, 1.0f);
    CGContextFillRect(context, CGRectMake(0, 0, size, size));
    
    // Fill tile path with white (1.0)
    CGContextSetGrayFillColor(context, 1.0f, 1.0f);
    
    CGRect bounds = _geometry.bounds;
    if (bounds.size.width > 0.001f && bounds.size.height > 0.001f) {
        CGContextScaleCTM(context,
                          (float)size / bounds.size.width,
                          (float)size / bounds.size.height);
        CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y);
        
        CGContextAddPath(context, _geometry.outline);
        CGContextFillPath(context);
    }
    
    CGContextRelease(context);
}

@end
