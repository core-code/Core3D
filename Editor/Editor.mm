//
//  Editor.m
//  Core3D-Editor
//
//  Created by CoreCode on 10.06.09.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Editor.h"
#import <objc/runtime.h>
#import <objc/objc.h>
#import "Editorsimulation.h"
#import "PathNode.h"



#define SUPPORTEDFILETYPES $array(@"obj", @"octree", @"snz", @"path", @"path0", @"path1", @"path2", @"path3", @"path4", @"path5", @"path6", @"path7", @"path8", @"path9", @"path10", @"path11", @"path12" )
Editor *gEditor;



@interface StringVector3Transformer : NSValueTransformer
@end

@implementation StringVector3Transformer
+ (Class)transformedValueClass
{
    return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
    return YES;
}
- (id)transformedValue:(id)value
{
	v3 vec;
	[value getValue:&vec];
	return $stringf(@"%.1f %.1f %.1f", vec.x, vec.y, vec.z);
}
- (id)reverseTransformedValue:(id)value
{
    NSArray *comp = [value componentsSeparatedByString:@" "];
    v3 vec = {	[[comp objectAtIndex:0] floatValue],
				[[comp objectAtIndex:1] floatValue],
                [[comp objectAtIndex:2] floatValue]};
    return [NSValue valueWithBytes:&vec objCType:@encode(v3)];
}
@end

@interface StringVector4Transformer : NSValueTransformer
@end

@implementation StringVector4Transformer
+ (Class)transformedValueClass
{
    return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
    return YES;
}
- (id)transformedValue:(id)value
{
	v4 vec;
	[value getValue:&vec];
	return $stringf(@"%.1f %.1f %.1f %.1f", vec.x, vec.y, vec.z, vec.w);
}
- (id)reverseTransformedValue:(id)value
{
    NSArray *comp = [value componentsSeparatedByString:@" "];
    v4 vec = {	[[comp objectAtIndex:0] floatValue],
				[[comp objectAtIndex:1] floatValue],
				[[comp objectAtIndex:2] floatValue],
				[[comp objectAtIndex:3] floatValue]	};
    return [NSValue valueWithBytes:&vec objCType:@encode(v4)];
}
@end

@implementation Editor

+ (void)loadEditor:(id)sender
{
    [NSBundle loadNibNamed:@"Editor" owner:NSApp];
    Editorsimulation *sim = [[[Editorsimulation alloc] init] autorelease];
    [sim setRealsimulator:sender];
    [sim setRealcamera:[[scene mainRenderPass] camera]];

    Camera *nc = [[[Camera alloc] init] autorelease];
    [nc setAxisConfiguration:kXYZRotation];

    [nc setPosition:[[[scene mainRenderPass] camera] aggregatePosition]];
    [nc setRotation:[[[scene mainRenderPass] camera] rotation]];
    [[scene mainRenderPass] setCamera:nc];

    [scene setSimulator:sim];
}

- (id)init
{
    if ((self = [super init]))
    {
        gEditor = self;
        nameDict = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)awakeFromNib
{
    [outlineView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    //	NSRect r = [[NSScreen mainScreen] frame];
    //	[window setFrame:NSMakeRect(r.origin.x, r.origin.y, r.size.width - 150, r.size.height) display:YES];
}

- (void)dealloc
{
    gEditor = nil;

    [window close];

    [nameDict release];
    [super dealloc];
}

- (IBAction)add:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowedFileTypes:SUPPORTEDFILETYPES];

    if ([panel runModal] == NSOKButton)
        [self addFile:[[panel URLs] objectAtIndex:0]];
}

- (IBAction)remove:(id)sender
{
    __unsafe_unretained __block id item = [outlineView itemAtRow:[outlineView selectedRow]];

    if ([item isKindOfClass:[SceneNode class]])
    {
		[item retain];

		[scene removeNode:item];
		
        [self reload:self];
		
		[[scene simulator] performBlockOnRenderThread:^
		 {
			 [item release];
		 }];
    }
}

- (IBAction)reload:(id)sender
{
    [outlineView reloadItem:nil];
    [outlineView expandItem:nil expandChildren:YES];
}

- (IBAction)cameraAction:(id)sender
{
    [(Editorsimulation *) [scene simulator] stopCamera];

    if ([[sender titleOfSelectedItem] isEqualToString:@"Iso"])
    {
        [[[scene mainRenderPass] camera] setPosition:vector3f(20, 25, 20)];
        [[[scene mainRenderPass] camera] setRotation:vector3f(-45, 45, 0)];
    }
    else if ([[sender titleOfSelectedItem] isEqualToString:@"Top"])
    {
        [[[scene mainRenderPass] camera] setPosition:vector3f(0, 10, 0)];
        [[[scene mainRenderPass] camera] setRotation:vector3f(-90, 0, 0)];
    }
    else if ([[sender titleOfSelectedItem] isEqualToString:@"Side"])
    {
        [[[scene mainRenderPass] camera] setPosition:vector3f(0, 0, 10)];
        [[[scene mainRenderPass] camera] setRotation:vector3f(0, 0, 0)];
    }
    else if ([[sender titleOfSelectedItem] isEqualToString:@"Front"])
    {
        [[[scene mainRenderPass] camera] setPosition:vector3f(10, 0, 0)];
        [[[scene mainRenderPass] camera] setRotation:vector3f(0, 90, 0)];
    }
    else if ([[sender titleOfSelectedItem] isEqualToString:@"Locate"])
    {
        SceneNode *item = [outlineView itemAtRow:[outlineView selectedRow]];
        if ([item isKindOfClass:[SceneNode class]])
            [[[scene mainRenderPass] camera] setRotationFromLookAt:[item position]];
        else if ([item isKindOfClass:[Mesh class]])
            [[[scene mainRenderPass] camera] setRotationFromLookAt:[item position] + [(Mesh *) item center]];
    }
}

- (void)renderAxis
{
	const GLfloat axis[] = {0, 0, 0,    1.0, 0, 0,    1.0, 0.0, 0.0,    0.75f,  0.075f,  0.075f,    1.0, 0.0, 0.0,    0.75f,  0.075f, -0.075f,    1.0, 0.0, 0.0,    0.75f, -0.075f, -0.075f,    1.0, 0.0, 0.0,    0.75f, -0.075f,  0.075f,    0.75f,  0.075f,  0.075f,    0.75f,  0.075f, -0.075f,    0.75f,  0.075f, -0.075f,    0.75f, -0.075f, -0.075f,    0.75f, -0.075f, -0.075f,    0.75f, -0.075f,  0.075f,    0.75f, -0.075f,  0.075f,    0.75f,  0.075f,  0.075f,
		0, 0, 0,    0, 1.0, 0,    0.0, 1.0, 0.0,     0.075f, 0.75f,  0.075f,    0.0, 1.0, 0.0,     0.075f, 0.75f, -0.075f,    0.0, 1.0, 0.0,    -0.075f, 0.75f, -0.075f,    0.0, 1.0, 0.0,    -0.075f, 0.75f,  0.075f,     0.075f, 0.75f,  0.075f,     0.075f, 0.75f, -0.075f,     0.075f, 0.75f, -0.075f,    -0.075f, 0.75f, -0.075f,    -0.075f, 0.75f, -0.075f,    -0.075f, 0.75f,  0.075f,    -0.075f, 0.75f,  0.075f,     0.075f, 0.75f,  0.075f,
		0, 0, 0,    0, 0, 1.0,    0.0, 0.0, 1.0,     0.075f,  0.075f, 0.75f,    0.0, 0.0, 1.0,     0.075f, -0.075f, 0.75f,    0.0, 0.0, 1.0,    -0.075f, -0.075f, 0.75f,    0.0, 0.0, 1.0,    -0.075f,  0.075f, 0.75f,     0.075f,  0.075f, 0.75f,     0.075f, -0.075f, 0.75f,     0.075f, -0.075f, 0.75f,    -0.075f, -0.075f, 0.75f,    -0.075f, -0.075f, 0.75f,    -0.075f,  0.075f, 0.75f,    -0.075f,  0.075f, 0.75f,     0.075f,  0.075f, 0.75f};
	
	[[scene colorOnlyShader] bind];
	myEnableBlendParticleCullDepthtestDepthwrite(false, false, false, false, false);
	
	myClientStateVTN(kNeedEnabled, kNeedDisabled, kNeedDisabled);
	glVertexAttribPointer(VERTEX_ARRAY, 3, GL_FLOAT, GL_FALSE, 0, axis);
	myLineWidth(1.5);
	
	[currentShader prepare];
	
	[currentShader setColor:vector4f(1.0, 0.1, 0.1, 1.0)];
	glDrawArrays(GL_LINES, 0, 18);
	
	[currentShader setColor:vector4f(0.1, 1.0, 0.1, 1.0)];
	glDrawArrays(GL_LINES, 18, 18);
	
	[currentShader setColor:vector4f(0.1, 0.0, 1.0, 1.0)];
	glDrawArrays(GL_LINES, 2*18, 18);
	
	myEnableBlendParticleCullDepthtestDepthwrite(false, false, false, true, true);
}

- (void)render
{
	id item = [outlineView itemAtRow:[outlineView selectedRow]];

	if ([item isKindOfClass:[SceneNode class]])
	{
		[currentCamera push];

		[(SceneNode *)item transform];

		[self renderAxis];

		[currentCamera pop];
	}
	
	[currentCamera push];

	[self renderAxis];

	[currentCamera pop];
}

- (void)mouseDragged:(vector2f)delta withFlags:(uint32_t)flags
{
    if (flags & NSCommandKeyMask)
    {
        id item = [outlineView itemAtRow:[outlineView selectedRow]];

        if ([item isKindOfClass:[SceneNode class]])
        {
            SceneNode *sn = item;

            vector3f rot = [sn rotation];
            rot[1] += delta[0] / 10.0;
            rot[0] -= delta[1] / 10.0;
            [sn setRotation:rot];
        }
    }
    else if (flags & NSAlternateKeyMask)
    {
        id item = [outlineView itemAtRow:[outlineView selectedRow]];

        if ([item isKindOfClass:[SceneNode class]])
        {
            SceneNode *sn = item;

            vector3f rot = [sn rotation];
            rot[2] += delta[0] / 10.0;
            [sn setRotation:rot];
        }
    }
    else if (flags & NSControlKeyMask)
    {
        id item = [outlineView itemAtRow:[outlineView selectedRow]];

        if ([item isKindOfClass:[SceneNode class]])
        {
            SceneNode *sn = item;

            vector3f pos = [sn position];
            pos[0] += delta[0] / 10.0;
            pos[2] += delta[1] / 10.0;
            [sn setPosition:pos];
        }
    }
    else if (flags & NSShiftKeyMask)
    {
        id item = [outlineView itemAtRow:[outlineView selectedRow]];

        if ([item isKindOfClass:[SceneNode class]])
        {
            SceneNode *sn = item;

            vector3f pos = [sn position];
            pos[1] += delta[0] / 10.0;
            [sn setPosition:pos];
        }
    }
    else
    {
        vector3f rot = [[[scene mainRenderPass] camera] rotation];

        rot[1] -= delta[0] / 10.0;
        rot[0] -= delta[1] / 10.0;

        [[[scene mainRenderPass] camera] setRotation:rot];
    }

    //	[self outlineViewSelectionDidChange:nil];
}

- (void)selectItem:(id)item
{
    NSInteger itemIndex = [outlineView rowForItem:item];
    if (itemIndex < 0)
    {
        itemIndex = [outlineView rowForItem:item];
        if (itemIndex < 0)
            return;
    }

    [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemIndex] byExtendingSelection:NO];
	[outlineView scrollRowToVisible:itemIndex];

}

- (void)addFile:(NSURL *)inputURL
{
#ifndef GNUSTEP
    NSURL *url = inputURL;
	NSURL *generatedURL = [[inputURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"octree"];
    BOOL regenerate = FALSE;


    if ([[inputURL pathExtension] hasPrefix:@"path"])
    {
        PathNode *p = [(PathNode *) [PathNode alloc] initWithContentsOfURL:inputURL];
        [[scene objects] addObject:p];
        [p release];
        [[[[scene renderpasses] objectAtIndex:0] objects] addObject:p];
        [self reload:self];
        return;
    }

	
    if ([[inputURL pathExtension] isEqualToString:@"obj"] && [[NSFileManager defaultManager] fileExistsAtPath:[generatedURL path]])
		if (NSRunAlertPanel(@"Core3D-Editor", $stringf(@"There is already an octree at the destination path: %@", [generatedURL path]),	@"Regenerate Octree", @"Open old Octree", nil) == NSOKButton)
			regenerate = TRUE;


    if ([[inputURL pathExtension] isEqualToString:@"obj"] || regenerate)
    {
		assert([scaleField floatValue] > 0.0001);
        NSTask *task = [[NSTask alloc] init];
        NSArray *arguments = $array( [[NSBundle mainBundle] pathForResource:@"generateOctreeFromObj" ofType:@"py"], $stringf(@"-s=%f", [scaleField floatValue]), [inputURL path]);
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = [pipe fileHandleForReading];

        [task setArguments:arguments];
        [task setLaunchPath:@"/usr/bin/python"];
        [task setStandardOutput:pipe];
		
        [task launch];

        NSData *data = [file readDataToEndOfFile];

        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSRange sr = [string rangeOfString:@"SUCCESS"];

        if (sr.location == NSNotFound)
            NSRunAlertPanel(@"Core3D-Editor", $stringf(@"Could not compile obj file: \n%@", string), @"OK", nil, nil);

        [task release];
        [string release];
		
		url = generatedURL;
    }



	[[scene simulator] performBlockOnRenderThread:^
	{
#ifdef __COCOTRON__
		 Mesh *o = [[[Mesh alloc] initWithOctree:url andName:[url lastPathComponent]] autorelease];
#else
		 CollideableMeshBullet *o = [[[CollideableMeshBullet alloc] initWithOctree:url andName:[url lastPathComponent]] autorelease];
		 [o setCollisionShapeTriangleMesh:NO];
#endif
		
		if ([o octree]->magicWord != 0x6D616C62)
		{
			for (NSString *ext in IMG_EXTENSIONS)
			{
				NSURL *textureURL = [[[inputURL URLByDeletingPathExtension] URLByDeletingPathExtension] URLByAppendingPathExtension:ext];
				
				if ([[NSFileManager defaultManager] fileExistsAtPath:[textureURL path]])
				{
					Texture *texture = [[(Texture *)[Texture alloc] initWithContentsOfURL:textureURL] autorelease];
					[texture load];
					[o setTexture:texture];
					break;
				}
			}
		}
		
		//NSLog([o description]);
		 [[scene objects] addObject:o];
		 
		 SceneNode *n = [[[[scene renderpasses] objectAtIndex:0] objects] objectAtIndex:0];
		 [[n children] addObject:o];
		
		dispatch_async(dispatch_get_main_queue(), ^(void)
		{
			[self reload:self];
		});
	 }];

#endif
}

#pragma mark *** NSOutlineViewDataSource protocol-methods ***

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    //NSLog(@"id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item %lx", item );
    if (item == nil)
    {
        return scene;
    }
    else
    {
        if ([item isKindOfClass:[NSArray class]])
            return [item objectAtIndex:index];
        else
        {
            int num = 0;
            id _class = [item class];
            do
            {
                //printf("%s\n", class_getName(_class));
                unsigned int outCount, i;
                objc_property_t *properties = class_copyPropertyList(_class, &outCount);
                for (i = 0; i < outCount; i++)
                {
                    objc_property_t property = properties[i];
                    //				fprintf(stdout, "%s %s\n", property_getName(property), property_getAttributes(property));
                    NSString *attr = [NSString stringWithUTF8String:property_getAttributes(property)];
                    //			NSArray *attrs = [attr componentsSeparatedByString:@","];

                    NSString *name = $stringf(@"%s", property_getName(property));
                    if ([name isEqualToString:@"relativeModeTarget"]) continue;
					if ([name isEqualToString:@"mainRenderPass"]) continue;
                    if ([name hasPrefix:@"_"]) continue;
                    SEL selector = NSSelectorFromString(name);

                    if ([attr rangeOfString:@"T@\"NSMutableArray\""].location != NSNotFound)
                    {
                        id returnedAttributeItem = [item performSelector:selector];


                        if ([(NSArray *) returnedAttributeItem count])
                        {
                            if (num == index)
                            {
                                [nameDict setObject:name forKey:$stringf(@"%p", returnedAttributeItem)];
                                assert(returnedAttributeItem);
                                return returnedAttributeItem;
                            }
                            num++;
                        }
                    }
                    else if (([attr rangeOfString:@"T@\""].location != NSNotFound) &&
                            ([attr rangeOfString:@"T@\"NSString"].location == NSNotFound))
                    {
                        id returnedAttributeItem = [item performSelector:selector];

                        if (num == index && returnedAttributeItem)
                        {
                            [nameDict setObject:name forKey:$stringf(@"%p", returnedAttributeItem)];
                            assert(returnedAttributeItem);
                            return returnedAttributeItem;
                        }

                        if (returnedAttributeItem)
                            num++;
                    }
                }
                free(properties);

                _class = class_getSuperclass(_class);
            } while (_class != nil);
        }
    }

    return nil;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // NSLog(@"- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:%@", [item description]);
    if (!item)
        return 1;
    if ([item isKindOfClass:[NSArray class]])
        return [(NSArray *) item count];
    else
    {
        int num = 0;
        id _class = [item class];
        do
        {
            //printf("%s\n", class_getName(_class));
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList(_class, &outCount);
            for (i = 0; i < outCount; i++)
            {
                objc_property_t property = properties[i];
                //fprintf(stdout, "%s %s\n", property_getName(property), property_getAttributes(property));
                NSString *attr = [NSString stringWithUTF8String:property_getAttributes(property)];
                //	NSArray *attrs = [attr componentsSeparatedByString:@","];
                NSString *name = $stringf(@"%s", property_getName(property));
                if ([name isEqualToString:@"relativeModeTarget"]) continue;
                if ([name isEqualToString:@"mainRenderPass"]) continue;
                if ([name hasPrefix:@"_"]) continue;

                SEL selector = NSSelectorFromString(name);
                if ([attr rangeOfString:@"T@\"NSMutableArray\""].location != NSNotFound)
                {
                    NSMutableArray *array = [item performSelector:selector];
                    if ([array count])
                        num++;
                }
                else if (([attr rangeOfString:@"T@\""].location != NSNotFound) &&
                        ([attr rangeOfString:@"T@\"NSString"].location == NSNotFound))
                {


                    id returnedAttributeItem = [item performSelector:selector];
                    if (returnedAttributeItem)
                        num++;
                }
            }
            _class = class_getSuperclass(_class);
            free(properties);
        } while (_class != nil);

        return num;
    }
}

- (BOOL)outlineView:(NSOutlineView *)_outlineView isItemExpandable:(id)item
{
    //	if ([item isKindOfClass:[NSArray class]])
    //		return YES;
    //	else
    //		return YES;
    return ([self outlineView:_outlineView numberOfChildrenOfItem:item] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[NSString class]])
        return item;
    if ([item isKindOfClass:[Mesh class]])
        return [item name];
    else if ([nameDict objectForKey:$stringf(@"%p", item)])
        return [nameDict objectForKey:$stringf(@"%p", item)];
    else
        return [item className];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
    return NSDragOperationEvery;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
#if !defined(__COCOTRON__) && !defined(GNUSTEP)
    NSArray *classArray = [NSArray arrayWithObject:[NSURL class]]; // types of objects you are looking for
    NSDictionary *options = $dict($numui(YES), NSPasteboardURLReadingFileURLsOnlyKey);
    NSArray *arrayOfURLs = [[info draggingPasteboard] readObjectsForClasses:classArray options:options]; // read objects of those classes

    if (![arrayOfURLs count])
        return NO;

    for (NSURL *url in arrayOfURLs)
        if ([SUPPORTEDFILETYPES indexOfObject:[url pathExtension]] != NSNotFound)
            [self addFile:url];
#endif
    return YES;
}

#pragma mark *** NSOutlineView delegate-methods ***

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    // NSLog(@"outlineViewSelectionDidChange");

    id item = [outlineView itemAtRow:[outlineView selectedRow]];

    for (NSView *subview in [containerView subviews])
        [subview unbind:@"value"];
    while ([[containerView subviews] count])
        [[[containerView subviews] objectAtIndex:0] removeFromSuperview];

    if ([item isKindOfClass:[SceneNode class]])
    {
        int y = 262;
        id _class = [item class];
        do
        {
            //printf("%s\n", class_getName(_class));
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList(_class, &outCount);
            for (i = 0; i < outCount; i++)
            {
                objc_property_t property = properties[i];
                fprintf(stdout, "%s %s\n", property_getName(property), property_getAttributes(property));



                NSString *attr = [NSString stringWithUTF8String:property_getAttributes(property)];

                NSArray *attrs = [attr componentsSeparatedByString:@","];
                if ([[[attrs objectAtIndex:0] substringFromIndex:1] isEqualToString:@"f"] ||
					[[[attrs objectAtIndex:0] substringFromIndex:1] isEqualToString:@"i"] ||
					[[[attrs objectAtIndex:0] substringFromIndex:1] isEqualToString:@"c"] ||
					[attr rangeOfString:@"{_v3=fff}"].location != NSNotFound ||
					[attr rangeOfString:@"{_v4=ffff}"].location != NSNotFound)
                {
                    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(10, y, 190, 20)];
                    [label setStringValue:[NSString stringWithUTF8String:property_getName(property)]];
                    [label setEditable:NO];

					NSTextField *tf = [[NSTextField alloc] initWithFrame:NSMakeRect(200, y, 143, 20)];
					NSString *kp = [NSString stringWithUTF8String:property_getName(property)];
					NSDictionary *dict = nil;
			
					if (([attr rangeOfString:@"{_v3=fff}"].location != NSNotFound))
                        dict = [NSDictionary dictionaryWithObject:[[StringVector3Transformer alloc] init]
														   forKey: NSValueTransformerBindingOption];
					else if (([attr rangeOfString:@"{_v4=ffff}"].location != NSNotFound))
                        dict = [NSDictionary dictionaryWithObject:[[StringVector4Transformer alloc] init]
														   forKey: NSValueTransformerBindingOption];
					
					[tf setEditable:([attr rangeOfString:@",R,"].location == NSNotFound)];

					[tf bind:@"value" toObject:item withKeyPath:kp options:dict];

					[containerView addSubview:tf];
					[tf release];

                    y -= 20;
                    [containerView addSubview:label];
                    [label release];
                }

                //				else
                //					NSLog(@"%@", [[attrs objectAtIndex:0] substringFromIndex:1]);

            }
            _class = class_getSuperclass(_class);
        } while (_class != nil);
    }


    [decriptionField setStringValue:item ? [item description] : @""];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if (item == @"Objects")
        return 0;
    else
        return 1;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(NSArray *)context
{
//	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
//	{
//		SceneNode *item = [context objectAtIndex:0];
//		NSTextField *tf = [context objectAtIndex:1];
//		
//		vector3f vec = [item position];
//		
//		[tf setStringValue:$stringf(@"x: %.1f y: %.1f z: %.1f", vec[0], vec[1], vec[2])];
//		
//		[context release];
//	});
}
@end

