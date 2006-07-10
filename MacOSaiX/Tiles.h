//  Created by fmidgley on Mon Apr 11 2001.
//  Copyright (c) 2001-2005 Frank M. Midgley. All rights reserved.

#import <Cocoa/Cocoa.h>

#import "MacOSaiXImageSource.h"
#import "MacOSaiXImageMatch.h"


#define TILE_BITMAP_SIZE		16.0


@class MacOSaiXMosaic;


@interface MacOSaiXTile : NSObject
{
	NSBezierPath		*outline;				// The shape of this tile
	float				orientation;			// The orientation of this tile (in radians)
	
	NSBitmapImageRep	*bitmapRep,				// The portion of the original image that is in this tile
						*maskRep;
	MacOSaiXImageMatch	*uniqueImageMatch,
						*bestImageMatch,
						*userChosenImageMatch;	// will be nil if user has not choosen an image
	MacOSaiXMosaic		*mosaic;				// The mosaic this tile is a part of (non-retained)
}

	// designated initializer
- (id)initWithOutline:(NSBezierPath *)outline fromMosaic:(MacOSaiXMosaic *)inMosaic;

- (void)setOrientation:(float)angle;
- (float)orientation;

- (MacOSaiXMosaic *)mosaic;

- (void)setOutline:(NSBezierPath *)outline;
- (NSBezierPath *)outline;

- (void)resetBitmapRepAndMask;
- (NSBitmapImageRep *)bitmapRep;
- (NSBitmapImageRep *)maskRep;

- (MacOSaiXImageMatch *)uniqueImageMatch;
- (void)setUniqueImageMatch:(MacOSaiXImageMatch *)match;

- (MacOSaiXImageMatch *)bestImageMatch;
- (void)setBestImageMatch:(MacOSaiXImageMatch *)match;

- (void)setUserChosenImageMatch:(MacOSaiXImageMatch *)match;
- (MacOSaiXImageMatch *)userChosenImageMatch;

- (MacOSaiXImageMatch *)displayedImageMatch;

@end
