//
//  Editor.h
//  Core3D-Editor
//
//  Created by CoreCode on 10.06.09.
//  Copyright 2009 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "Simulation.h"


@interface Editor : NSObject
{
    NSMutableDictionary *nameDict;
    IBOutlet NSOutlineView *outlineView;
    IBOutlet NSTextField *scaleField;
    IBOutlet NSTextField *posX, *posY, *posZ;
    IBOutlet NSTextField *rotX, *rotY, *rotZ;
    IBOutlet NSWindow *window;

    IBOutlet NSView *containerView;
    IBOutlet NSTextField *decriptionField;
}

+ (void)loadEditor:(id)sender;

- (IBAction)reload:(id)sender;
- (void)render;

- (IBAction)add:(id)sender;
- (IBAction)remove:(id)sender;

- (void)selectItem:(id)item;

- (IBAction)cameraAction:(id)sender;

- (void)mouseDragged:(vector2f)delta withFlags:(uint32_t)flags;
- (void)addFile:(NSURL *)inputURL;

@end
