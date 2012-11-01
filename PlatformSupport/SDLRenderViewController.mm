//
//  SDLRenderViewController.m
//  Core3D
//
//  Created by CoreCode on 11.01.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//

#ifdef __linux__
#include <GL/glx.h>
#endif

#include "SDLRenderViewController.h"
#include "SDL.h"
#include "Core3D.h"
#include "Simulation.h"


@class GameSheetController;

SDL_Surface *screen;

RenderViewController *rvc = nil;

@implementation RenderViewController

+ (RenderViewController *)sharedController
{
	return rvc;
}

- (void)mainLoop
{
	for (NSString *p in globalInfo.commandLineParameters)
	{
		NSArray *c = [p componentsSeparatedByString:@"="];

		if ([p hasPrefix:@"-videoresolution"] && [c count] == 2)
		$setdefault([[c objectAtIndex:1] stringByReplacingOccurrencesOfString:@"x" withString:@" x "], @"videoresolution");
		else if ([p hasPrefix:@"-"] && [c count] == 2)
		$setdefaulti([[c objectAtIndex:1] intValue], [[c objectAtIndex:0] substringFromIndex:1]);
	}
	$defaultsync;

	// NSLog(@"SDL RenderViewController mainLoop");
	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_JOYSTICK) == -1)
		fatal("Error: SDL_Init failed");

	if (Mix_OpenAudio(48000, MIX_DEFAULT_FORMAT, 2, 1024) < 0)
		NSLog(@"Error: SDL_mixer can't open audio");

	int w = 0, h = 0;
	const SDL_VideoInfo *info = NULL;



	info = SDL_GetVideoInfo();
	if (!info)
		fatal("Error: video query failed: %s\n", SDL_GetError());

	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);



	NSLog(@"Info: current video mode: %i x %i : %i\n", (int) info->current_w, (int) info->current_h, (int) info->vfmt->BitsPerPixel);

	if ($defaulti(kFsaaKey))
	{
		NSLog(@"Notice: enabling FSAA: %i\n", (int) $defaulti(kFsaaKey) * 2);
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
		SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, (int) $defaulti(kFsaaKey) * 2);
	}

	BOOL windowed = $defaulti(@"windowed");
	int bpp = $defaulti(@"bpp");
	int synctovbl = !$defaulti(@"disablevbl") && !IS_TIMEDEMO;


	if (SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, synctovbl) < 0)
		NSLog(@"Warning: SDL_GL_SWAP_CONTROL: %s", SDL_GetError());


	if ([$default(kVideoresolutionKey) length])
	{
		NSArray *rescomp = [$default(kVideoresolutionKey) componentsSeparatedByString:@" x "];
		if ([rescomp count] == 2)
		{
			w = [[rescomp objectAtIndex:0] intValue];
			h = [[rescomp objectAtIndex:1] intValue];
		}
	}
	if (!w) w = info->current_w;
	if (!h) h = info->current_h;


	//    screen = SDL_SetVideoMode(400, 300, 24, SDL_OPENGL); // no fullscreen while buggy
	//    #warning TODO
	Uint32 flags;
	if (windowed)
		flags = SDL_OPENGL | SDL_ANYFORMAT;
	else
		flags = SDL_OPENGL | SDL_FULLSCREEN | SDL_ANYFORMAT;

	NSLog(@"Info: Requesting renderable of size %ix%i:%i (VBL: %i)", w, h, bpp, synctovbl);

	screen = SDL_SetVideoMode(w, h, bpp, flags);
	if (!screen)
	{
		if ($defaulti(kFsaaKey))
		{
			NSLog(@"Notice: could not set video mode, turning off FSAA and trying again");


			SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 0);
			SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);

			screen = SDL_SetVideoMode(w, h, bpp, flags);
			if (!screen)
			{
				if ((w != info->current_w) || (h != info->current_h))
				{
					NSLog(@"Notice: again could not set video mode, falling back to current resolution (%i x %i)", info->current_w, info->current_h);

					screen = SDL_SetVideoMode(info->current_w, info->current_h, bpp, flags);
					if (!screen)
						fatal("Error: video mode set failed: %s\n", SDL_GetError());

					w = info->current_w;
					h = info->current_h;
				}
				else
					fatal("Error: video mode set failed: %s\n", SDL_GetError());
			}
		}
		else if ((w != info->current_w) || (h != info->current_h))
		{
			NSLog(@"Notice: could not set video mode, falling back to current resolution (%i x %i)", info->current_w, info->current_h);

			screen = SDL_SetVideoMode(info->current_w, info->current_h, bpp, flags);


			if (!screen)
				fatal("Error: video mode set failed: %s\n", SDL_GetError());

			w = info->current_w;
			h = info->current_h;
		}
		else
			fatal("Error: video mode set failed: %s\n", SDL_GetError());
	}


	SDL_WM_SetCaption("Core3D", NULL);
	SDL_ShowCursor(SDL_DISABLE);

	info = SDL_GetVideoInfo();

	GLint param[4] = {0, 0, 0, 0};
	GLint freeRAM = 0;

	if (HasExtension(@"ATI_meminfo"))
		glGetIntegerv(0x87FC, param);       //  TEXTURE_FREE_MEMORY_ATI                 0x87FC
	else if (HasExtension(@"NVX_gpu_memory_info"))
		glGetIntegerv(0x9049, param);       //  GPU_MEMORY_INFO_CURRENT_AVAILABLE_VIDMEM_NVX  0x9049

	if (param[0])
		freeRAM = param[0] / 1024; // both extensions report in kb
	if (freeRAM > 0 &&
			freeRAM < 180 &&
			$defaulti(kTextureQualityKey) == 0)
	{
		NSLog(@"Warning: the texture quality parameter has automatically been lowered because you dont have 180 MB free GPU video RAM (only %i MB)", freeRAM);
		$setdefaulti(1, kTextureQualityKey);
	}


	scene = [[Scene alloc] init];
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	[scene reshape:CGSizeMake((w ? w : info->current_w), h ? h : info->current_h)];

	[Game renderSplash];
	SDL_GL_SwapBuffers();

	id sim = [[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SimulationClass"]) alloc] init];
	if (sim)
	{

		[scene setSimulator:sim];
		[sim release];
	}
	else
		fatal("no sim %s", [[[[NSBundle mainBundle] infoDictionary] description] UTF8String]);

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	[scene reshape:CGSizeMake((w ? w : info->current_w), h ? h : info->current_h)];

	int firstmillis = SDL_GetTicks();

	//	int startticks = SDL_GetTicks();
	loop:
			while (!done)
			{
				NSAutoreleasePool *pool;
				pool = [[NSAutoreleasePool alloc] init];

				if (globalSettings.displayFPS)
				{


					static int frames = 0;
					static int lastmillis = 0;

					int millis = SDL_GetTicks();

#ifdef TIMEDEMO
			if (millis - firstmillis > 1000 * 80)
				fatal("finished benchmark");
#endif

#ifndef PRINT_FRAMERATE_EVERY_60_FRAMES
					if (((millis - lastmillis) > 1000) && (globalInfo.fps = frames))
#else
            if ((frames >= 60) && (globalInfo.fps = ((1000.0 / (float)(millis - lastmillis)) * 60.0)))
#endif
					{
						lastmillis = millis;
						frames = 0;

#ifdef PRINT_DETAILED_STATISTICS
                    printf("FPS: %i\tRenderedFaces: %i\nMainRenderPass:\t\t\t RenderedFaces: %i of %i (%.2f%%) VisitedNodes: %i of %i (%.2f%%)\nShadowRenderPass:\t\t\t RenderedFaces: %i of %i (%.2f%%) VisitedNodes: %i of %i (%.2f%%)\nAdditionalRenderPass:\t RenderedFaces: %i of %i (%.2f%%) VisitedNodes: %i of %i (%.2f%%) DrawCalls: %i\n", (int)globalInfo.fps, globalInfo.renderedFaces[0]+globalInfo.renderedFaces[1]+globalInfo.renderedFaces[2], globalInfo.renderedFaces[0], globalInfo.totalFaces, (float)globalInfo.renderedFaces[0]*100/(float)globalInfo.totalFaces, globalInfo.visitedNodes[0], globalInfo.totalNodes, (float)globalInfo.visitedNodes[0]*100/(float)globalInfo.totalNodes, globalInfo.renderedFaces[1], globalInfo.totalFaces, (float)globalInfo.renderedFaces[1]*100/(float)globalInfo.totalFaces, globalInfo.visitedNodes[1], globalInfo.totalNodes, (float)globalInfo.visitedNodes[1]*100/(float)globalInfo.totalNodes, globalInfo.renderedFaces[2], globalInfo.totalFaces, (float)globalInfo.renderedFaces[2]*100/(float)globalInfo.totalFaces, globalInfo.visitedNodes[2], globalInfo.totalNodes, (float)globalInfo.visitedNodes[2]*100/(float)globalInfo.totalNodes, globalInfo.drawCalls);
#else
						printf("FPS: %i\tRenderedFaces: %i\n", (int) globalInfo.fps, globalInfo.renderedFaces);
#endif
					}
					else
						frames++;
				}
				double millis = SDL_GetTicks();


				[scene update:millis / 1000.0];

				[scene render];



				SDL_GL_SwapBuffers();


				SDL_Event event;
				while (SDL_PollEvent(&event))
				{
					switch (event.type)
					{
						case SDL_KEYDOWN:
						case SDL_KEYUP:
						{
							unichar c = event.key.keysym.sym;
							NSEvent *e = [NSEvent keyEventWithType:(event.type == SDL_KEYDOWN) ? NSKeyDown : NSKeyUp
							                              location:NSMakePoint(0, 0)
									                 modifierFlags:0
												         timestamp:0
													  windowNumber:0
														   context:[NSGraphicsContext currentContext]
														characters:[NSString stringWithCharacters:&c length:1]
									   charactersIgnoringModifiers:[NSString stringWithCharacters:&c length:1]
														 isARepeat:NO keyCode:c];

							if (event.type == SDL_KEYDOWN)
							{
								[pressedKeys addObject:$numui(c)];
								[[scene simulator] keyDown:e];
							}
							else
							{
								[pressedKeys removeObject:$numui(c)];
								[[scene simulator] keyUp:e];
							}
						}
					        break;
						case SDL_QUIT:
					        [scene release];
					        fatal("CoreBreach proper termination\n");
					        break;
					        //				case SDL_MOUSEMOTION:
					        //					if (SDL_BUTTON(1) == event.motion.state)
					        //							[(Simulation *)[scene simulator] mouseDragged:vector2f(event.motion.xrel, event.motion.yrel) withFlags:0];
					        //					break;
						case SDL_MOUSEBUTTONDOWN:
					        //					if(event.button.button == SDL_BUTTON_WHEELUP)
					        //					{
					        //							[(Simulation *)[scene simulator] scrollWheel:3.0];
					        //					}
					        //					else if(event.button.button == SDL_BUTTON_WHEELDOWN)
					        //					{
					        //							[(Simulation *)[scene simulator] scrollWheel:-3.0];NSScroll
					        //					} else
					        if ((event.button.button == SDL_BUTTON_RIGHT) || (event.button.button == SDL_BUTTON_LEFT))
					        {
						        NSEvent *e = [NSEvent mouseEventWithType:(event.button.button == SDL_BUTTON_RIGHT) ? NSRightMouseDown : NSLeftMouseDown
						                                        location:NSMakePoint(event.button.x, event.button.y)
								                           modifierFlags:0
											                   timestamp:0
													        windowNumber:0
																 context:0
															 eventNumber:0
															  clickCount:1
																pressure:0];

						        if (event.button.button == SDL_BUTTON_LEFT)
							        [[scene simulator] mouseDown:e];
						        else
							        [[scene simulator] rightMouseDown:e];
					        }

					        break;
						case SDL_MOUSEBUTTONUP:
					        if ((event.button.button == SDL_BUTTON_RIGHT) || (event.button.button == SDL_BUTTON_LEFT))
					        {
						        NSEvent *e = [NSEvent mouseEventWithType:(event.button.button == SDL_BUTTON_RIGHT) ? NSRightMouseDown : NSLeftMouseDown
						                                        location:NSMakePoint(event.button.x, event.button.y)
								                           modifierFlags:0
											                   timestamp:0
													        windowNumber:0
																 context:0
															 eventNumber:0
															  clickCount:1
																pressure:0];

						        if (event.button.button == SDL_BUTTON_LEFT)
							        [[scene simulator] mouseUp:e];
						        else
							        [[scene simulator] rightMouseUp:e];
					        }
					        break;
						case FF_QUIT_EVENT:
					        break;
						case FF_ALLOC_EVENT:
					        ff_alloc_handler(event.user.data1);
					        break;
						case FF_REFRESH_EVENT:
					        ff_refresh_handler(event.user.data1);
					        break;
						case SDL_JOYBUTTONDOWN:  /* Handle Joystick Button Presses */
						case SDL_JOYBUTTONUP:  /* Handle Joystick Button Presses */
						case SDL_JOYAXISMOTION:  /* Handle Joystick Motion */
					        [[HIDSupport sharedInstance] handleEvent:event];
					}
				}

				[pool drain];
			}
	exit(1);
}


- (void)awakeFromNib
{
	rvc = self;

	[self performSelector:@selector(mainLoop) withObject:nil afterDelay:0.01];
}

- (void)dealloc
{
	//NSLog(@"sdl render view dealloc");

	[scene release];
	[super dealloc];
}
@end

