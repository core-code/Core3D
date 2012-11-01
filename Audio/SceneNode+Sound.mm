//
//  SceneNode+Sound.m
//  Core3D
//
//  Created by CoreCode on 16.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


#import "Core3D.h"


int soundNodes;

@implementation SceneNode (Sound)

- (void)attachSoundNamed:(NSString *)n
{
#ifndef DISABLE_SOUND
	if (globalSettings.soundEnabled)
	{

		[self deallocSound];

		buffer = [SoundBuffer newSoundBufferNamed:n];

		// Create some OpenAL Source Objects
		alGenSources(1, &source);
		soundNodes++;
		if (alGetError() != AL_NO_ERROR)
			fatal("Error generating sources! \n");

		if (!source)
			fatal("Error generating sources null! \n");
		{
			ALenum error = AL_NO_ERROR;

			{
				// Set Source Position
				alSourcefv(source, AL_POSITION, position.data());

				alSourcef(source, AL_REFERENCE_DISTANCE, 10.0f);

				alSourcef(source, AL_MAX_DISTANCE, 800.0f);

				alSourcef(source, AL_ROLLOFF_FACTOR, 0.3f);

				alSourcef(source, AL_GAIN, 1.0f);

				alSourcei(source, AL_BUFFER, buffer.buffer);
			}

			if ((error = alGetError()) != AL_NO_ERROR)
				fatal("Error attaching buffer to source");
		}
	}
#endif
}

- (void)setProperty:(int)property toValue:(float)value
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourcef(source, property, value);
#endif
}

- (void)updateSound
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourcefv(source, AL_POSITION, position.data());
#endif
}

- (void)setVolume:(float)inVolume
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourcef(source, AL_GAIN, inVolume);
#endif
}

- (void)setPitch:(float)inPitch
{
//    if (source)     cout << inPitch << endl;
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourcef(source, AL_PITCH, inPitch);
#endif
}

- (void)setLooping:(BOOL)looping
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourcei(source, AL_LOOPING, looping ? AL_TRUE : AL_FALSE);
#endif
}

- (BOOL)isPlaying
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
	{
		ALint val;
		alGetSourcei(source, AL_SOURCE_STATE, &val);
		return (val == AL_PLAYING);
	}
	else
		return NO;
#endif
}

- (void)playSound
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourcePlay(source);
#endif
}

- (void)stopSound
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourceStop(source);
#endif
}

- (void)rewindSound
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourceRewind(source);
#endif
}

- (void)pauseSound
{
#ifndef DISABLE_SOUND
	if (source && globalSettings.soundEnabled)
		alSourcePause(source);
#endif
}

- (void)deallocSound
{
#ifndef DISABLE_SOUND
	if (source)
		alDeleteSources(1, &source);
	if (source)
		soundNodes--;
	[buffer release];
#endif
}
@end
