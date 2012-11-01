//
//  MusicManager.h
//  Core3D
//
//  Created by CoreCode on 08.09.11
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#ifndef __BLOCKS__
#define StringInBlock id
#endif


#ifdef TARGET_OS_IPHONE
#import <AVFoundation/AVAudioPlayer.h>


#elif defined(TARGET_OS_MAC)
#import <QTKit/QTMovie.h>
#endif

@interface MusicManager : NSObject
#ifdef TARGET_OS_IPHONE
		<AVAudioPlayerDelegate>
#endif
{
#ifndef DISABLE_SOUND
	StringInBlock songChangeBlock;
	NSMutableArray *songs;


#if defined(SDL)
    Mix_Music               *music;
//#elif defined(GNUSTEP)
//    NSSound                 *currentSong;
//#elif defined(__COCOTRON__)
#elif defined(TARGET_OS_MAC)
    QTMovie                 *currentSong;
#elif defined(TARGET_OS_IPHONE)
	AVAudioPlayer *currentSong;
#endif
#endif
}

- (id)initWithSongs:(NSArray *)_songs andSongChangeBlock:(StringInBlock)_songChangeBlock;
- (void)startPlayingWithDelay:(float)delay;
- (void)playSongInBackground;
- (void)pauseMusic;
- (void)unpauseMusic;

@end
