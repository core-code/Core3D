//
//  MusicManager.mm
//  Core3D
//
//  Created by CoreCode on 08.09.11
//  Copyright 2011 - 2012 CoreCode. Licensed under the MIT License, see LICENSE.txt
//

#import "Core3D.h"


MusicManager *mm = NULL;

void musicDone();

@implementation MusicManager

- (id)initWithSongs:(NSArray *)_songs andSongChangeBlock:(StringInBlock)_songChangeBlock
{
	if ((self = [super init]))
	{
		mm = self;
		songs = [[NSMutableArray alloc] initWithArray:_songs];
		songChangeBlock = [_songChangeBlock copy];

#ifdef TARGET_OS_MAC
        [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playSongInBackground) name:QTMovieDidEndNotification object:nil];
#endif

		[self startPlayingWithDelay:3.0];
	}

	return self;
}

- (NSString *)cleanFilename:(NSString *)filename
{
	NSString *ret = [filename stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	ret = [ret stringByReplacingOccurrencesOfString:@"*" withString:@"_"];
	ret = [ret stringByReplacingOccurrencesOfString:@"'" withString:@"_"];
	ret = [ret stringByReplacingOccurrencesOfString:@"(" withString:@"_"];
	ret = [ret stringByReplacingOccurrencesOfString:@")" withString:@"_"];

	return ret;
}

#ifdef SDL

- (void)playSongInBackground
{

    if (music)
    {
        //NSLog(@"music, halting and freeing");

        Mix_HaltMusic();
        Mix_FreeMusic(music);
        music = NULL;
    }

    if ([songs count])
    {

        NSString *song = [songs objectAtIndex:cml::random_integer(0, [songs count]-1)];


        //NSLog(@"Info: playing song %@ %s", song, [[[NSBundle mainBundle] pathForResource:[self cleanFilename:song] ofType:@"ogg"] fileSystemRepresentation]);


        /* Actually loads up the music */
        music = Mix_LoadMUS([[[NSBundle mainBundle] pathForResource:[self cleanFilename:song] ofType:@"ogg"] fileSystemRepresentation]);

        /* This begins playing the music - the first argument is a
         pointer to Mix_Music structure, and the second is how many
         times you want it to loop (use -1 for infinite, and 0 to
         have it just play once) */
        Mix_PlayMusic(music, 0);

        /* We want to know when our music has stopped playing so we
         can free it up and set 'music' back to NULL.  SDL_Mixer
         provides us with a callback routine we can use to do
         exactly that */
        Mix_HookMusicFinished(musicDone);

        Mix_VolumeMusic(MIX_MAX_VOLUME * $defaultf(kMusicVolumeKey));
       // NSLog(@"Setting music volume to %i %f %i", MIX_MAX_VOLUME, $defaultf(kMusicVolumeKey), MIX_MAX_VOLUME * $defaultf(kMusicVolumeKey));



        [songs removeObject:song];



        songChangeBlock(song);
    }

}

- (void)pauseMusic
{
    Mix_PauseMusic();
}

- (void)unpauseMusic
{
    Mix_ResumeMusic();
}

//#elif defined(GNUSTEP)
//
//- (void)playSongInBackground
//{
//    [currentSong setDelegate:nil];
//    [currentSong release];
//    currentSong = nil;
//
//
//    if ([songs count])
//    {
//
//        NSString *song = [songs objectAtIndex:cml::random_integer(0, [songs count]-1)];
//
//                NSLog(@"playing song %@", song);
//        currentSong = [[NSSound alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[self cleanFilename:song] withExtension:@"ogg"] byReference: NO];
//
//
//        [currentSong setVolume:$defaultf(kMusicVolumeKey)];
//        [currentSong play];
//        [songs removeObject:song];
//
//        [currentSong setDelegate:self];
//
//
//
//        songChangeBlock(song);
//    }
//
//}
//
//- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying
//{
//    [self playSongInBackground];
//}
//
//- (void)pauseMusic
//{
//    [currentSong pause];
//}
//
//- (void)unpauseMusic
//{
//    [currentSong play];
//}
//
//#elif defined(__COCOTRON__)

#elif defined(TARGET_OS_IPHONE)

- (void)playSong
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//  NSLog(@"waiting to playSong");
	@synchronized (scene)
	{
		//    NSLog(@"playSong");
		[currentSong release];
		currentSong = nil;


		if ([songs count])
		{

			NSString *song = [songs objectAtIndex:(NSUInteger) cml::random_integer(0, [songs count] - 1)];

			//        NSLog(@"playing song %@", song);
			currentSong = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:[self cleanFilename:song] withExtension:@"aac"] error:nil];
			[currentSong setVolume:$defaultf(kMusicVolumeKey)];
			[currentSong play];
			[currentSong setDelegate:self];
			[songs removeObject:song];



			songChangeBlock(song);
		}
		//    else
		//        NSLog(@"no song anymore");

		// TODO: test memory

	}
	// NSLog(@"end song sync");

	[pool release];
}

- (void)playSongInBackground
{
	// NSLog(@"playSongInBackground");
	//   [self performSelectorInBackground:@selector(playSongReal) withObject:nil];

	dispatch_async(dispatch_get_global_queue(0, 0), ^
	{[self playSong];});
}

- (void)pauseMusic
{
	[currentSong pause];
}

- (void)unpauseMusic
{
	[currentSong play];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	[self playSongInBackground];
}

#elif defined(TARGET_OS_MAC)



- (void)playSong
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //  NSLog(@"waiting to playSong");
    @synchronized(scene)
    {
        //    NSLog(@"playSong");
        [currentSong release];
        currentSong = nil;
        
        
        if ([songs count])
        {
            
            NSString *song = [songs objectAtIndex:cml::random_integer(0, [songs count]-1)];
            
            //        NSLog(@"playing song %@", song);
            currentSong = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:[self cleanFilename:song] withExtension:@"aac"] error:nil];
            [currentSong setVolume:$defaultf(kMusicVolumeKey)];
            [currentSong play];
            [songs removeObject:song];
            NSTimeInterval timeInterval;
            QTGetTimeInterval([currentSong duration], &timeInterval);
            //      NSLog(@"scheduling next song for %f", timeInterval);
            
            
            
            songChangeBlock(song);
        }
        //    else
        //        NSLog(@"no song anymore");
        
        // TODO: test memory
        
    }
    // NSLog(@"end song sync");
    
    [pool release];
}

- (void)playSongInBackground
{
    // NSLog(@"playSongInBackground");
    //   [self performSelectorInBackground:@selector(playSongReal) withObject:nil];
    
	dispatch_async(dispatch_get_global_queue(0, 0), ^{    [self playSong];    });
}

- (void)pauseMusic
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [currentSong stop];
}

- (void)unpauseMusic
{
    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playSongInBackground) name:QTMovieDidEndNotification object:nil];
    [currentSong play];
}

#endif


- (void)startPlayingWithDelay:(float)delay
{
#ifdef __BLOCKS__
	[[scene simulator] performBlockAfterDelay:delay block:^
	{[self playSongInBackground];}];
#endif
}

- (void)dealloc
{
	//NSLog(@"music manager dealloc");
	[songs release];

#ifdef TARGET_OS_MAC
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif

	@synchronized (scene)
	{
#ifdef SDL
        Mix_HaltMusic();
        Mix_FreeMusic(music);
        music = NULL;
#else
		[currentSong release];
		currentSong = nil;
#endif
	}
	[super dealloc];
	mm = NULL;
}
@end

#ifdef SDL
void musicDone()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [mm startPlayingWithDelay:0.1f];
    
    [pool release];
}
#endif