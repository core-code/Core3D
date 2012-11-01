//
//  SoundBuffer.h
//  Core3D
//
//  Created by CoreCode on 25.05.11
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

@interface SoundBuffer : NSObject
{

	NSString *name;
#ifndef DISABLE_SOUND
	ALuint buffer;
#endif
}

+ (SoundBuffer *)newSoundBufferNamed:(NSString *)_name;
- (SoundBuffer *)initWithContentsOfURL:(NSURL *)_url;
+ (NSArray *)allBuffers;

@property (nonatomic, copy) NSString *name;
#ifndef DISABLE_SOUND
@property (nonatomic, readonly) ALuint buffer;
#endif
@end
