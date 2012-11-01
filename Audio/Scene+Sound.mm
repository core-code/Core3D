//
//  Scene+Sound.m
//  Core3D
//
//  Created by CoreCode on 16.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#ifndef DISABLE_SOUND

#import "Core3D.h"


#ifdef ALUT
#include <AL/alut.h>
#endif
extern int soundNodes;

@implementation Scene (Sound)

- (void)initSound
{
//#ifdef __APPLE__SHIT
//
	ALCcontext *newContext = NULL;
	ALCdevice *newDevice = NULL;

	// Create a new OpenAL Device
	// Pass NULL to specify the system’s default output device
	newDevice = alcOpenDevice(NULL);
	if (newDevice != NULL)
	{
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created
		newContext = alcCreateContext(newDevice, 0);
		if (newContext != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(newContext);
		}
	}

	alDistanceModel(AL_INVERSE_DISTANCE_CLAMPED);

	int error = alGetError();
	if (error != AL_NO_ERROR)
		fatal("initSound alError %i", error);

	error = alcGetError(newDevice);
	if (error)
		fatal("alcError %i", error);

#ifdef ALUT
    static BOOL alutInited = FALSE;
    if (!alutInited)
    {
        if (!alutInitWithoutContext(0, NULL))
            NSLog(@"alutInit error %i", alutGetError());
        alutInited = TRUE;
    }
#endif
//#else
//    static BOOL inited = FALSE;
//
//    if (inited) return;
//
//    inited = TRUE;
//    if (!alutInit(0, NULL))
//    {
//        printf("alutInit error %li", (long)alutGetError);
//    }
//#endif
	alListenerfv(AL_VELOCITY, vector3f(0, 0, 0).data());
	alListenerf(AL_GAIN, globalSettings.soundVolume);
}

- (void)deallocSound
{
	@synchronized (self)
	{
		//  NSLog(@"dealloc sound");
		ALCcontext *context = NULL;
		ALCdevice *device = NULL;



		//Get active context
		context = alcGetCurrentContext();



		//Get device for active context
		device = alcGetContextsDevice(context);



		alcMakeContextCurrent(NULL);



		//Release context
		alcDestroyContext(context);



		//Close device
		alcCloseDevice(device);

#ifdef __APPLE__
		int error = alGetError();
		if (error != AL_NO_ERROR)
		{
			NSLog(@"Error: Scene+Sound dealloc: alError %i soundNodes %i soundBuffers %@", error, soundNodes, [[SoundBuffer allBuffers] description]);
		}
#endif

//#ifdef ALUT
//        NSLog(@"alutExit");
//        if (!alutExit())
//            NSLog(@"alutExit error %li", (long)alutGetError);
//#endif
	}
}

@end

#endif