//
//  MacOSaiXEditorsView.h
//  MacOSaiX
//
//  Created by Frank Midgley on 12/22/06.
//  Copyright 2006 Frank M. Midgley. All rights reserved.
//

@class MosaicView, MacOSaiXEditor;


@interface MacOSaiXEditorsView : NSView
{
	MosaicView		*mosaicView;
	
	NSMutableArray	*editors, 
					*editorButtons;
	
	MacOSaiXEditor	*activeEditor;
}

- (void)setMosaicView:(MosaicView *)view;
- (MosaicView *)mosaicView;

- (void)addEditor:(MacOSaiXEditor *)editor;

- (NSArray *)editors;

- (MacOSaiXEditor *)activeEditor;

@end