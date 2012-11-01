//
//  QCNode.h
//  CoreBreach
//
//  Created by CoreCode on 15.11.10.
//  Copyright 2007 - 2012 CoreCode. Licensed under the MIT License, see _MIT_LICENSE.txt
//

#import <QuartzComposer/QCRenderer.h>


@interface QCNode : SceneNode
{
	QCRenderer *renderer;
}

- (id)initWithCompositionNamed:(NSString *)_name;

@end
