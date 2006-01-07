/*
	FlickrImageSourceController.h
	MacOSaiX

	Created by Frank Midgley on Mon Nov 14 2005.
	Copyright (c) 2005 Frank M. Midgley. All rights reserved.
*/

#import "FlickrImageSourceController.h"


@implementation FlickrImageSourceController


- (NSView *)mainView
{
	if (!editorView)
		[NSBundle loadNibNamed:@"Flickr Image Source" owner:self];
	
	return editorView;
}


- (NSSize)minimumSize
{
	return NSMakeSize(374.0, 181.0);
}


- (NSResponder *)firstResponder
{
	return queryField;
}


- (void)setOKButton:(NSButton *)button
{
	okButton = button;
}


- (void)editImageSource:(id<MacOSaiXImageSource>)imageSource
{
	currentImageSource = (FlickrImageSource *)imageSource;
	
	[queryField setStringValue:([currentImageSource queryString] ? [currentImageSource queryString] : @"")];
	[queryTypeMatrix selectCellAtRow:[currentImageSource queryType] column:0];
}


- (IBAction)visitFlickr:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.flickr.com"]];
}


- (void)getCountOfMatchingPhotos
{
	if (matchingPhotosTimer)
	{
		[matchingPhotosTimer invalidate];
		[matchingPhotosTimer release];
	}
	
	matchingPhotosTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 
															target:self 
														  selector:@selector(getCountOfMatchingPhotos:) 
														  userInfo:nil 
														   repeats:NO] retain];
}


- (void)getCountOfMatchingPhotos:(NSTimer *)timer
{
	if (currentImageSource)
	{
		[matchingPhotosCount setHidden:YES];
		[matchingPhotosIndicator setHidden:NO];
		[matchingPhotosIndicator startAnimation:self];
		
		[NSThread detachNewThreadSelector:@selector(getPhotoCount) toTarget:self withObject:nil];
	}
	
	[matchingPhotosTimer release];
	matchingPhotosTimer = nil;
}


- (void)getPhotoCount
{
	NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
	WSMethodInvocationRef	flickrInvocation = WSMethodInvocationCreate((CFURLRef)[NSURL URLWithString:@"http://www.flickr.com/services/xmlrpc/"],
																		CFSTR("flickr.photos.search"),
																		kWSXMLRPCProtocol);
	NSMutableDictionary		*parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												@"514c14062bc75c91688dfdeacc6252c7", @"api_key", 
												[NSNumber numberWithInt:1], @"page", 
												[NSNumber numberWithInt:1], @"per_page", 
												nil];
	
	if ([currentImageSource queryType] == matchAllTags)
	{
		[parameters setObject:[currentImageSource queryString] forKey:@"tags"];
		[parameters setObject:@"all" forKey:@"tagmode"];
	}
	else if ([currentImageSource queryType] == matchAnyTags)
	{
		[parameters setObject:[currentImageSource queryString] forKey:@"tags"];
		[parameters setObject:@"any" forKey:@"tagmode"];
	}
	else
		[parameters setObject:[currentImageSource queryString] forKey:@"text"];
	
	NSDictionary			*wrappedParameters = [NSDictionary dictionaryWithObject:parameters forKey:@"foo"];
	WSMethodInvocationSetParameters(flickrInvocation, (CFDictionaryRef)wrappedParameters, nil);
	CFDictionaryRef			results = WSMethodInvocationInvoke(flickrInvocation);
	
	NSString				*photoCount = @"unknown";
	if (!WSMethodResultIsFault(results))
	{
			// Extract the count of photos from the XML response.
		NSString	*xmlString = [(NSDictionary *)results objectForKey:(NSString *)kWSMethodInvocationResult];
		NSScanner	*xmlScanner = [NSScanner scannerWithString:xmlString];
		
		if ([xmlScanner scanUpToString:@"total=\"" intoString:nil] &&
			[xmlScanner scanString:@"total=\"" intoString:nil])
			[xmlScanner scanUpToString:@"\"" intoString:&photoCount];
	}
	[self performSelectorOnMainThread:@selector(displayMatchingPhotoCount:) withObject:photoCount waitUntilDone:NO];
	
	CFRelease(results);
	[pool release];
}


- (void)displayMatchingPhotoCount:(NSString *)photoCount
{
	[matchingPhotosIndicator startAnimation:self];
	[matchingPhotosIndicator setHidden:YES];
	[matchingPhotosCount setStringValue:photoCount];
	[matchingPhotosCount setHidden:NO];
	
}


- (void)controlTextDidChange:(NSNotification *)notification
{
	if ([notification object] == queryField)
	{
		NSString	*queryString = [[queryField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		[currentImageSource setQueryString:queryString];
		
		[okButton setEnabled:([queryString length] > 0)];
		
		[self getCountOfMatchingPhotos];
	}
}


- (IBAction)setQueryType:(id)sender
{
	[currentImageSource setQueryType:[queryTypeMatrix selectedRow]];
	
	[self getCountOfMatchingPhotos];
}


@end
