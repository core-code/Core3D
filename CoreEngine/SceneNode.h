//
//  SceneNode.h
//  Core3D
//
//  Created by CoreCode on 21.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//




@interface SceneNode : NSObject
{
	float scale;
	NSString *name;
	BOOL enabled;
	vector3f position, rotation;
	SceneNode *relativeModeTarget;
	axisConfigurationEnum relativeModeAxisConfiguration, axisConfiguration;
	MutableSceneNodeArray *children;

#ifndef DISABLE_SOUND
	SoundBuffer *buffer;
	ALuint source;
#endif
}

@property (assign, nonatomic) float scale;
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) BOOL enabled;
@property (assign, nonatomic) axisConfigurationEnum relativeModeAxisConfiguration;
@property (assign, nonatomic) axisConfigurationEnum axisConfiguration;
@property (assign, nonatomic) vector3f position;
@property (assign, nonatomic) vector3f rotation;
@property (assign, nonatomic) SceneNode *relativeModeTarget;
@property (retain, nonatomic) MutableSceneNodeArray *children;

CPPPROPERTYSUPPORT_V3_H(position)
CPPPROPERTYSUPPORT_V3_H(rotation)

- (void)setPositionByMovingForward:(float)amount;
- (void)setRotationFromLookAt:(vector3f)lookAt;
- (vector3f)getLookAt;
- (vector3f)getUp;
- (NSArray *)allocListOfAllChildren;
- (SceneNode *)childWithName:(NSString *)_name;
- (void)removeNode:(SceneNode *)node;

- (void)transform;

- (void)reshapeNode:(CGSize)size;
- (void)renderNode;
- (void)updateNode;

- (void)reshape:(CGSize)size;
- (void)render;
- (void)update;

//- (void)renderCenter;

- (vector3f)aggregatePosition;
//- (vector3f)aggregateRotation;

@end
