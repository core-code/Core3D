//
//  ShaderNode.h
//  Core3D
//
//  Created by CoreCode on 06.09.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//


@interface ShaderNode : SceneNode
{
@private
	Shader *shader;
}

- (id)initWithShader:(Shader *)_shader;

@end

@interface SceneNode (Sound)

- (void)attachSoundNamed:(NSString *)name;
- (void)updateSound;
- (void)setPitch:(float)inPitch;
- (void)setVolume:(float)inVolume;
- (void)setProperty:(int)property toValue:(float)value;
- (void)deallocSound;
- (void)setLooping:(BOOL)looping;
- (BOOL)isPlaying;
- (void)playSound;
- (void)stopSound;
- (void)rewindSound;
- (void)pauseSound;

@end