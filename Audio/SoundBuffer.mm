//
//  SoundBuffer.mm
//  Core3D
//
//  Created by CoreCode on 25.05.11
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"
#import "Texture.h"


#ifndef DISABLE_SOUND

#ifdef ALUT
    #include <AL/alut.h>
#else
#include <AudioToolbox/AudioToolbox.h>


#endif

#endif


MutableDictionary *namedBuffers;


#ifdef __APPLE__
#ifndef DISABLE_SOUND
#ifndef ALUT
void *MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei *outSampleRate);
#endif
#endif
#endif

@implementation SoundBuffer
#ifndef DISABLE_SOUND

@synthesize name, buffer;
#else
@synthesize name;
#endif

+ (void)initialize
{
	if (!namedBuffers)
		namedBuffers = new MutableDictionary;
}

+ (NSArray *)allBuffers
{
	NSMutableArray *buffers = [NSMutableArray array];

	MutableDictionary::const_iterator end = namedBuffers->end();
	for (MutableDictionary::const_iterator it = namedBuffers->begin(); it != end; ++it)
		[buffers addObject:it->second];


	return buffers;
}

+ (SoundBuffer *)newSoundBufferNamed:(NSString *)_name
{
	if (namedBuffers->count([_name UTF8String]))
	{
		SoundBuffer *cachedBuffer = (*namedBuffers)[[_name UTF8String]];

		assert(cachedBuffer);

		return [cachedBuffer retain];
	}

	for (NSString *ext in SND_EXTENSIONS)
	{
		NSURL *url = [[NSBundle mainBundle] URLForResource:_name withExtension:ext];
		if (url)
		{
			SoundBuffer *snd = [(SoundBuffer *) [self alloc] initWithContentsOfURL:url];
			(*namedBuffers)[[_name UTF8String]] = snd;

			[snd setName:_name];
			return snd;
		}
	}

	NSLog(@"Warning: could not find sound named: %@", _name);

	return nil;
}

- (SoundBuffer *)initWithContentsOfURL:(NSURL *)_url
{
	if ((self = [self init]))
	{
#ifndef DISABLE_SOUND
#ifndef ALUT
		// Create some OpenAL Buffer Objects
		alGenBuffers(1, &buffer);
		if (alGetError() != AL_NO_ERROR)
			fatal("Error Generating Buffers: ");


		{
			ALenum error = AL_NO_ERROR;
			ALenum format;
			ALvoid *data;
			ALsizei size;
			ALsizei freq;


			// get some audio data from a wave file
			data = MyGetOpenALAudioData((CFURLRef) _url, &size, &format, &freq);

			if (format != AL_FORMAT_MONO16)
			{
				NSDebugLog(@"Warning: audio file stereo, won't be 3D: %@", [[_url path] lastPathComponent]);
			}

			if ((error = alGetError()) != AL_NO_ERROR)
				fatal("error loading %s: ", [[_url absoluteString] UTF8String]);


			// Attach Audio Data to OpenAL Buffer
			alBufferData(buffer, format, data, size, freq);

			// Release the audio data
			free(data);

			if ((error = alGetError()) != AL_NO_ERROR)
				printf("error unloading %s: ", [[_url absoluteString] UTF8String]);
		}
#else
        NSString *p = [_url path];

#ifdef WIN32
        if ([p hasPrefix:@"/"]) p = [p substringFromIndex:1];
        p = [p stringByReplacingOccurrencesOfString:@"/" withString:@"\\"];
#endif
        ALenum  error = AL_NO_ERROR;
        buffer = alutCreateBufferFromFile([p UTF8String]);


        if ((error = alGetError()) != AL_NO_ERROR)
            fatal("error loading %s: ", [p UTF8String]);

        if (!buffer)
            fatal("error loading no buffer %s: ", [p UTF8String]);

#endif
#endif
	}

	return self;
}

- (void)dealloc
{
	if (name)
	{
		namedBuffers->erase([name UTF8String]);
		//	NSLog(@"buf release %@", name );
	}

	[name release];

#ifndef DISABLE_SOUND

	int error = alGetError();
	if (error != AL_NO_ERROR)
		fatal("pre bufrel alError %i %i", error, buffer);

	if (buffer)
		alDeleteBuffers(1, &buffer);

	error = alGetError();
	if (error != AL_NO_ERROR)
		fatal("bufrel alError %i %i", error, buffer);
#endif

	[super dealloc];
}
@end


#ifndef DISABLE_SOUND
#ifndef ALUT
void *MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei *outSampleRate)
{
	OSStatus err = noErr;
	SInt64 theFileLengthInFrames = 0;
	AudioStreamBasicDescription theFileFormat;
	UInt32 thePropertySize = sizeof(theFileFormat);
	ExtAudioFileRef extRef = NULL;
	void *theData = NULL;
	AudioStreamBasicDescription theOutputFormat;

	// Open a file with ExtAudioFileOpen()
	err = ExtAudioFileOpenURL(inFileURL, &extRef);
	if (err)
	{
		printf("MyGetOpenALAudioData: ExtAudioFileOpenURL FAILED, Error = %ld\n", (long int) err);
		if (extRef) ExtAudioFileDispose(extRef);
		return theData;
	}

	// Get the audio data format
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat, &thePropertySize, &theFileFormat);
	if (err)
	{
		printf("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat) FAILED, Error = %ld\n", (long int) err);
		if (extRef) ExtAudioFileDispose(extRef);
		return theData;
	}
	if (theFileFormat.mChannelsPerFrame > 2)
	{
		printf("MyGetOpenALAudioData - Unsupported Format, channel count is greater than stereo\n");
		if (extRef) ExtAudioFileDispose(extRef);
		return theData;
	}
#ifdef TARGET_OS_MAC
#warning this code produces clicks at least on macos
#endif
	// Set the client format to 16 bit signed integer (native-endian) data
	// Maintain the channel count and sample rate of the original source format
	theOutputFormat.mSampleRate = theFileFormat.mSampleRate;
	theOutputFormat.mChannelsPerFrame = theFileFormat.mChannelsPerFrame;

	theOutputFormat.mFormatID = kAudioFormatLinearPCM;
	theOutputFormat.mBytesPerPacket = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mFramesPerPacket = 1;
	theOutputFormat.mBytesPerFrame = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mBitsPerChannel = 16;
	theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;

	// Set the desired client (output) data format
	err = ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, sizeof(theOutputFormat), &theOutputFormat);
	if (err)
	{
		printf("MyGetOpenALAudioData: ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat) FAILED, Error = %ld\n", (long int) err);
		if (extRef) ExtAudioFileDispose(extRef);
		return theData;
	}

	// Get the total frame count
	thePropertySize = sizeof(theFileLengthInFrames);
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &theFileLengthInFrames);
	if (err)
	{
		printf("MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %ld\n", (long int) err);
		if (extRef) ExtAudioFileDispose(extRef);
		return theData;
	}


	// Read all the data into memory
	UInt32 theFramesToRead = (UInt32) theFileLengthInFrames;
	UInt32 dataSize = theFramesToRead * theOutputFormat.mBytesPerFrame;
	theData = malloc(dataSize);
	if (theData)
	{
		AudioBufferList theDataBuffer;
		theDataBuffer.mNumberBuffers = 1;
		theDataBuffer.mBuffers[0].mDataByteSize = dataSize;
		theDataBuffer.mBuffers[0].mNumberChannels = theOutputFormat.mChannelsPerFrame;

		theDataBuffer.mBuffers[0].mData = theData;

		// Read the data into an AudioBufferList
		err = ExtAudioFileRead(extRef, &theFramesToRead, &theDataBuffer);
		if (err == noErr)
		{
			// success
			*outDataSize = (ALsizei) dataSize;
			*outDataFormat = (theOutputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
			*outSampleRate = (ALsizei) theOutputFormat.mSampleRate;
		}
		else
		{
			// failure
			free(theData);
			theData = NULL; // make sure to return NULL
			printf("MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %ld\n", (long int) err);

			if (extRef) ExtAudioFileDispose(extRef);
			return theData;
		}
	}

	// Dispose the ExtAudioFileRef, it is no longer needed
	if (extRef) ExtAudioFileDispose(extRef);
	return theData;
}
#endif
#endif