/*
	GoogleImageSource.m
	MacOSaiX

	Created by Frank Midgley on Wed Mar 13 2002.
	Copyright (c) 2002-2004 Frank M. Midgley. All rights reserved.
*/

#import "GoogleImageSource.h"
#import "GoogleImageSourceController.h"
#import <CoreFoundation/CFURL.h>
#import <sys/time.h>


	// The image cache is shared between all instances so we need a class level lock.
static NSLock	*imageCacheLock = nil;
static NSString	*imageCachePath = nil;


NSString *escapedNSString(NSString *string)
{
	NSString	*escapedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, 
																					 NULL, NULL, kCFStringEncodingUTF8);
	return [escapedString autorelease];
}


@implementation GoogleImageSource


+ (void)load
{
	imageCachePath = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] 
											stringByAppendingPathComponent:@"Caches"]
											stringByAppendingPathComponent:@"MacOSaiX Google Images"] retain];
	if (![[NSFileManager defaultManager] fileExistsAtPath:imageCachePath])
		[[NSFileManager defaultManager] createDirectoryAtPath:imageCachePath attributes:nil];
	
	imageCacheLock = [[NSLock alloc] init];
}


+ (NSString *)name
{
	return @"Google";
}


+ (Class)editorClass
{
	return [GoogleImageSourceController class];
}


+ (BOOL)allowMultipleImageSources
{
	return YES;
}


- (id)init
{
	if (self = [super init])
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath:imageCachePath])
		{
			imageURLQueue = [[NSMutableArray array] retain];
		}
		else
		{
			[self autorelease];
			self = nil;
		}
	}
	
	return self;
}


- (NSString *)escapeXMLEntites:(NSString *)string
{
	NSMutableString	*escapedString = [NSMutableString stringWithString:(string ? string : @"")];
	
	[escapedString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"'" withString:@"&apos;" options:0 range:NSMakeRange(0, [escapedString length])];
	[escapedString replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:NSMakeRange(0, [escapedString length])];
	
	return [NSString stringWithString:escapedString];
}


- (NSString *)settingsAsXMLElement
{
	NSMutableString	*settingsXML = [NSMutableString string];
	
	[settingsXML appendFormat:@"<TERMS REQUIRED=\"%@\"\n       OPTIONAL=\"%@\"\n       EXCLUDED=\"%@\"/>\n", 
							  [self escapeXMLEntites:[self requiredTerms]],
							  [self escapeXMLEntites:[self optionalTerms]],
							  [self escapeXMLEntites:[self requiredTerms]]];
	
	switch ([self colorSpace])
	{
		case anyColorSpace:
			[settingsXML appendString:@"<COLOR_SPACE FILTER=\"ANY\"/>\n"]; break;
		case rgbColorSpace:
			[settingsXML appendString:@"<COLOR_SPACE FILTER=\"RGB\"/>\n"]; break;
		case grayscaleColorSpace:
			[settingsXML appendString:@"<COLOR_SPACE FILTER=\"GRAYSCALE\"/>\n"]; break;
		case blackAndWhiteColorSpace:
			[settingsXML appendString:@"<COLOR_SPACE FILTER=\"B&amp;W\"/>\n"]; break;
	}
	
	if ([self siteString])
		[settingsXML appendFormat:@"<SITE FILTER=\"%@\"/>\n", [self escapeXMLEntites:[self siteString]]];
	
	switch ([self adultContentFiltering])
	{
		case strictFiltering:
			[settingsXML appendString:@"<ADULT_CONTENT FILTER=\"STRICT\"/>\n"]; break;
		case moderateFiltering:
			[settingsXML appendString:@"<ADULT_CONTENT FILTER=\"MODERATE\"/>\n"]; break;
		case noFiltering:
			[settingsXML appendString:@"<ADULT_CONTENT FILTER=\"NONE\"/>\n"]; break;
	}
	
	return settingsXML;
}


- (void)updateQueryAndDescriptor
{
	[urlBase autorelease];
	urlBase = [[NSMutableString stringWithString:@"http://images.google.com/images?svnum=10&hl=en&"] retain];
	if (requiredTerms && [requiredTerms length] > 0)
		[urlBase appendString:[NSString stringWithFormat:@"as_q=%@&", escapedNSString(requiredTerms)]];
	if (optionalTerms && [optionalTerms length] > 0)
		[urlBase appendString:[NSString stringWithFormat:@"as_oq=%@&", escapedNSString(optionalTerms)]];
	if (excludedTerms && [excludedTerms length] > 0)
		[urlBase appendString:[NSString stringWithFormat:@"as_eq=%@&", escapedNSString(excludedTerms)]];
	switch (colorSpace)
	{
		case anyColorSpace:
			[urlBase appendString:@"imgc=&"]; break;
		case rgbColorSpace:
			[urlBase appendString:@"imgc=color&"]; break;
		case grayscaleColorSpace:
			[urlBase appendString:@"imgc=gray&"]; break;
		case blackAndWhiteColorSpace:
			[urlBase appendString:@"imgc=mono&"]; break;
	}
	if (siteString && [siteString length] > 0)
		[urlBase appendString:[NSString stringWithFormat:@"as_sitesearch=%@&", escapedNSString(siteString)]];
	switch (adultContentFiltering)
	{
		case strictFiltering:
			[urlBase appendString:@"safe=active&"]; break;
		case moderateFiltering:
			[urlBase appendString:@"safe=images&"]; break;
		case noFiltering:
			[urlBase appendString:@"safe=off&"]; break;
	}
	[urlBase appendString:@"start="];

	[descriptor autorelease];
	descriptor = [[NSMutableString string] retain];
	[descriptor appendString:@"something..."];
}


- (void)setRequiredTerms:(NSString *)terms
{
	[requiredTerms autorelease];
	requiredTerms = [terms copy];
	
	[self updateQueryAndDescriptor];
}


- (NSString *)requiredTerms
{
	return requiredTerms;
}


- (void)setOptionalTerms:(NSString *)terms
{
	[optionalTerms autorelease];
	optionalTerms = [terms copy];
	
	[self updateQueryAndDescriptor];
}


- (NSString *)optionalTerms
{
	return optionalTerms;
}


- (void)setExcludedTerms:(NSString *)terms
{
	[excludedTerms autorelease];
	excludedTerms = [terms copy];
	
	[self updateQueryAndDescriptor];
}


- (NSString *)excludedTerms
{
	return excludedTerms;
}


- (void)setColorSpace:(GoogleColorSpace)inColorSpace
{
	colorSpace = inColorSpace;
	
	[self updateQueryAndDescriptor];
}


- (GoogleColorSpace)colorSpace
{
	return colorSpace;
}


- (void)setSiteString:(NSString *)string
{
	[siteString autorelease];
	siteString = [string copy];
	
	[self updateQueryAndDescriptor];
}


- (NSString *)siteString
{
	return siteString;
}


- (void)setAdultContentFiltering:(GoogleAdultContentFiltering)filtering
{
	adultContentFiltering = filtering;
	
	[self updateQueryAndDescriptor];
}


- (GoogleAdultContentFiltering)adultContentFiltering
{
	return adultContentFiltering;
}


- (void)reset
{
	[imageURLQueue removeAllObjects];
	startIndex = 0;
}


- (NSImage *)image;
{
    return [NSImage imageNamed:@"GoogleImageSource"];
}


- (NSString *)descriptor
{
    return descriptor;
}


- (id)copyWithZone:(NSZone *)zone
{
	GoogleImageSource	*copy = [[GoogleImageSource allocWithZone:zone] init];
	
	[copy setRequiredTerms:requiredTerms];
	[copy setOptionalTerms:optionalTerms];
	[copy setExcludedTerms:excludedTerms];
	[copy setColorSpace:colorSpace];
	[copy setSiteString:siteString];
	[copy setAdultContentFiltering:adultContentFiltering];
	
	return copy;
}


- (void)populateImageQueueFromNextPage
{
	while ([imageURLQueue count] == 0 && startIndex >= 0)
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		NSString			*nextPage = [urlBase stringByAppendingString:[NSString stringWithFormat:@"%d", startIndex]];
		NSString			*URLcontent = [NSString stringWithContentsOfURL:[NSURL URLWithString:nextPage]];
		
		if (URLcontent)
		{
				// break up the HTML by img tags and look for image URLs
			NSEnumerator	*tagEnumerator = [[URLcontent componentsSeparatedByString:@"<img "] objectEnumerator];
			NSString		*tag = nil;
			
			[tagEnumerator nextObject];	// The first item didn't start with "<img ", the rest do.
			while (tag = [tagEnumerator nextObject])
			{
					// Find where the image URL starts.
				NSRange		src = [tag rangeOfString:@"src="];
				tag = [tag substringWithRange:NSMakeRange(src.location + 4, [tag length] - src.location - 4)];
				
					// Find where the image URL ends
				src = [tag rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" \">"]];
				if (src.location != NSNotFound)
					src.length = src.location;
				else
					src.length = [tag length];
				src.location = 0;
				
					// If the URL has the expected prefix then add it to the queue.
				NSString	*imageURL = [tag substringWithRange:src];
				if ([imageURL hasPrefix:@"/images?q="])
					[imageURLQueue addObject:[imageURL substringToIndex:([[imageURL substringFromIndex:1] rangeOfString:@"/"].location + 1)]];
			}
			
				// Check if there are any more pages of search results.
			if ([URLcontent rangeOfString:@"nav_next.gif"].location == NSNotFound)
				startIndex = -1;	// This was the last page of search results.
			else
				startIndex += 20;
		}
		[pool release];
	}
}


- (BOOL)hasMoreImages
{
	return ([imageURLQueue count] > 0 || startIndex >= 0);
}


- (NSImage *)nextImageAndIdentifier:(NSString **)identifier
{
	NSImage		*image = nil;
    
	do
	{
		if ([imageURLQueue count] == 0)
			[self populateImageQueueFromNextPage];
		else
		{
				// Get the image for the first identifier in the queue.
			image = [self imageForIdentifier:[imageURLQueue objectAtIndex:0]];
			if (image)
				*identifier = [[[imageURLQueue objectAtIndex:0] retain] autorelease];
			[imageURLQueue removeObjectAtIndex:0];
		}
	} while (!image && [self hasMoreImages]);
	
	return image;
}


- (NSImage *)imageForIdentifier:(NSString *)identifier
{
	NSImage		*image = nil;
	
	if ([identifier length] > 26)
	{
		NSString	*imageID = [identifier substringWithRange:NSMakeRange(14, 12)],
					*imageFileName = [NSString stringWithFormat:@"%x%x%x%x%x%x%x%x%x%x%x%x",
																[imageID characterAtIndex:0], [imageID characterAtIndex:1],
																[imageID characterAtIndex:2], [imageID characterAtIndex:3],
																[imageID characterAtIndex:4], [imageID characterAtIndex:5],
																[imageID characterAtIndex:6], [imageID characterAtIndex:7],
																[imageID characterAtIndex:8], [imageID characterAtIndex:9],
																[imageID characterAtIndex:10], [imageID characterAtIndex:11]],
					*imagePath = [imageCachePath stringByAppendingPathComponent:imageFileName];
		NSData		*imageData = nil;
		
			// First check if we have this image in the cache.
		[imageCacheLock lock];
			if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath])
			{
				imageData = [[[NSData alloc] initWithContentsOfFile:imagePath] autorelease];
				utimes([imageCachePath fileSystemRepresentation], NULL);
			}
		[imageCacheLock unlock];
		if (imageData)
			image = [[[NSImage alloc] initWithData:imageData] autorelease];
		
			// If it's not in the cache or couldn't be read from the cache then
			// fetch the image from Google.
		if (!image)
		{
			NSURL	*imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://images.google.com%@", identifier]];
			
			imageData = [[[NSData alloc] initWithContentsOfURL:imageURL] autorelease];
			if (imageData)
			{
				image = [[[NSImage alloc] initWithData:imageData] autorelease];
				[imageCacheLock lock];
					[imageData writeToFile:imagePath atomically:NO];
				
					// TODO: purge oldest image(s) when cache size limit exceeded.
				[imageCacheLock unlock];
			}
		}
	}
	
    return image;
}


- (void)dealloc
{
	[requiredTerms release];
	[optionalTerms release];
	[excludedTerms release];
	[siteString release];
	
	[imageURLQueue release];
	
	[super dealloc];
}


@end
