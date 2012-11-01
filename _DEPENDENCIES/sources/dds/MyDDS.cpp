
/* DDS loader written by Jon Watte 2002 */
/* Permission granted to use freely, as long as Jon Watte */
/* is held harmless for all possible damages resulting from */
/* your use or failure to use this code. */
/* No warranty is expressed or implied. Use at your own risk, */
/* or not at all. */

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include <algorithm>
#include "MyDDS.h"

#ifndef max
#define max(a, b) (a > b ? a : b)
#endif

DdsLoadInfo loadInfoDXT1 = {
	true, false, false, 4, 8, GL_COMPRESSED_RGBA_S3TC_DXT1_EXT, 0,0,0,0
};
DdsLoadInfo loadInfoDXT3 = {
	true, false, false, 4, 16, GL_COMPRESSED_RGBA_S3TC_DXT3_EXT, 0,0,0,0
};
DdsLoadInfo loadInfoDXT5 = {
	true, false, false, 4, 16, GL_COMPRESSED_RGBA_S3TC_DXT5_EXT, 0,0,0,0
};
DdsLoadInfo loadInfoBGRA8 = {
	false, false, false, 1, 4, GL_RGBA8, GL_BGRA, GL_UNSIGNED_BYTE, 0,0
};
DdsLoadInfo loadInfoBGR8 = {
	false, false, false, 1, 3, GL_RGB8, GL_BGR, GL_UNSIGNED_BYTE, 0,0
};
DdsLoadInfo loadInfoBGR5A1 = {
	false, true, false, 1, 2, GL_RGB5_A1, GL_BGRA, GL_UNSIGNED_SHORT_1_5_5_5_REV, 0,0
};
DdsLoadInfo loadInfoBGR565 = {
	false, true, false, 1, 2, GL_RGB5, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, 0,0
};
DdsLoadInfo loadInfoIndex8 = {
	false, false, true, 1, 1, GL_RGB8, GL_BGRA, GL_UNSIGNED_BYTE, 0,0
};

struct DdsLoadInfo loadDds( FILE * f, unsigned int skipHighestLevels )
{
	DDS_header hdr;
	// size_t s = 0;
	unsigned int x = 0;
	unsigned int y = 0;
	unsigned int mipMapCount = 0;
	//  DDS is so simple to read, too
	fread( &hdr, sizeof( hdr ), 1, f );
	assert( hdr.dwMagic == DDS_MAGIC );
	assert( hdr.dwSize == 124 );
  	int xSize = hdr.dwWidth;
	int ySize = hdr.dwHeight;
	
	if( hdr.dwMagic != DDS_MAGIC || hdr.dwSize != 124 ||
	   !(hdr.dwFlags & DDSD_PIXELFORMAT) || !(hdr.dwFlags & DDSD_CAPS) )
	{
		goto failure;
	}
	
	
//	if ( (xSize & (xSize-1)) )
//		printf("Warning:  DDS NPOT %i\n", xSize);
//	if ( (ySize & (ySize-1)) )
//		printf("Warning:  DDS NPOT %i\n", ySize);
	
	DdsLoadInfo * li;
	
	if( PF_IS_DXT1( hdr.sPixelFormat ) ) {
		li = &loadInfoDXT1;
	}
	else if( PF_IS_DXT3( hdr.sPixelFormat ) ) {
		li = &loadInfoDXT3;
	}
	else if( PF_IS_DXT5( hdr.sPixelFormat ) ) {
		li = &loadInfoDXT5;
	}
	else if( PF_IS_BGRA8( hdr.sPixelFormat ) ) {
		li = &loadInfoBGRA8;
	}
	else if( PF_IS_BGR8( hdr.sPixelFormat ) ) {
		li = &loadInfoBGR8;
	}
	else if( PF_IS_BGR5A1( hdr.sPixelFormat ) ) {
		li = &loadInfoBGR5A1;
	}
	else if( PF_IS_BGR565( hdr.sPixelFormat ) ) {
		li = &loadInfoBGR565;
	}
	else if( PF_IS_INDEX8( hdr.sPixelFormat ) ) {
		li = &loadInfoIndex8;
	}
	else {
		goto failure;
	}
	
	//fixme: do cube maps later
	//fixme: do 3d later
	x = xSize;
	y = ySize;
//	glTexParameteri( GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE );
	mipMapCount = (hdr.dwFlags & DDSD_MIPMAPCOUNT) ? hdr.dwMipMapCount : 1;
	
	if( mipMapCount <= 1 )
		printf("Warning: read DDS has no mipmaps\n");
	
	if( li->compressed ) {
		size_t size = max( li->divSize, x )/li->divSize * max( li->divSize, y )/li->divSize * li->blockBytes;
		assert( size == hdr.dwPitchOrLinearSize );
		assert( hdr.dwFlags & DDSD_LINEARSIZE );
		unsigned char * data = (unsigned char *)malloc( size );
		if( !data ) {
			goto failure;
		}
		
		for( unsigned int ix = 0; ix < mipMapCount; ++ix )
		{
			if ((x % 4 != 0) || (y % 4 != 0))
			{
				mipMapCount = ix;
				break;
			}
			if (ix >= skipHighestLevels)
			{
				fread( data, 1, size, f );
//				GLuint pbo;
				
//				glGenBuffers(1, &pbo);
//				glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);
//				glBufferData(GL_PIXEL_UNPACK_BUFFER, size, data, GL_STATIC_DRAW);
//				
//				glCompressedTexImage2D( GL_TEXTURE_2D, ix-skipHighestLevels, li->internalFormat, x, y, 0, size, 0);//data 
//				
//				glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
//				glDeleteBuffers(1, &pbo);
//				
				
				glCompressedTexImage2D( GL_TEXTURE_2D, ix-skipHighestLevels, li->internalFormat, x, y, 0, (int)size, data);
			}
			else
			{
				fseek(f, size, SEEK_CUR);
			}

			x = (x+1)>>1;
			y = (y+1)>>1;
			size = max( li->divSize, x )/li->divSize * max( li->divSize, y )/li->divSize * li->blockBytes;
		}
		free( data );
	}
	else if( li->palette ) {
//		//  currently, we unpack palette into BGRA
//		//  I'm not sure we always get pitch...
//		assert( hdr.dwFlags & DDSD_PITCH );
//		assert( hdr.sPixelFormat.dwRGBBitCount == 8 );
//		size_t size = hdr.dwPitchOrLinearSize * ySize;
//		//  And I'm even less sure we don't get padding on the smaller MIP levels...
//		assert( size == x * y * li->blockBytes );
//		
//		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
//		
//		unsigned char * data = (unsigned char *)malloc( size );
//		unsigned int palette[ 256 ];
//		unsigned int * unpacked = (unsigned int *)malloc( size*sizeof( unsigned int ) );
//		fread( palette, 4, 256, f );
//		for( unsigned int ix = 0; ix < mipMapCount; ++ix ) {
//			fread( data, 1, size, f );
//			for( unsigned int zz = 0; zz < size; ++zz ) {
//				unpacked[ zz ] = palette[ data[ zz ] ];
//			}
//			glPixelStorei( GL_UNPACK_ROW_LENGTH, y );
//			glTexImage2D( GL_TEXTURE_2D, ix, li->internalFormat, x, y, 0, li->externalFormat, li->type, unpacked );
//			
//			x = (x+1)>>1;
//			y = (y+1)>>1;
//			size = x * y * li->blockBytes;
//		}
//		free( data );
//		free( unpacked );
//		glPopClientAttrib();
        assert(0);
	}
	else {
//		glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT);
//		
//		if( li->swap ) {
//			glPixelStorei( GL_UNPACK_SWAP_BYTES, GL_TRUE );
//		}
//		size_t size = x * y * li->blockBytes;
//		
//		unsigned char * data = (unsigned char *)malloc( size );
//		//fixme: how are MIP maps stored for 24-bit if pitch != ySize*3 ?
//		for( unsigned int ix = 0; ix < mipMapCount; ++ix ) {
//			fread( data, 1, size, f );
//			glPixelStorei( GL_UNPACK_ROW_LENGTH, y );
//			glTexImage2D( GL_TEXTURE_2D, ix, li->internalFormat, x, y, 0, li->externalFormat, li->type, data );
//			
//			x = (x+1)>>1;
//			y = (y+1)>>1;
//			size = x * y * li->blockBytes;
//		}
//		free( data );
//		glPopClientAttrib();
        assert(0);
	}
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, ((mipMapCount-1-skipHighestLevels) > 0) ? (mipMapCount-1-skipHighestLevels): 0);
	
	
	DdsLoadInfo info;
	info.compressed = li->compressed;
	info.swap = li->swap;
	info.palette = li->palette;
	info.divSize = li->divSize;
	info.blockBytes = li->blockBytes;
	info.internalFormat = li->internalFormat;
	info.externalFormat = li->externalFormat;
	info.type = li->type;
	info.width = xSize;
	info.height = ySize;
	
	return info;
	
failure:
    printf("DDS file corrupt");
	exit(1);
}

