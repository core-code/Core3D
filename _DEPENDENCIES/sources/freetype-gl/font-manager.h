/* ============================================================================
 * Freetype GL - A C OpenGL Freetype engine
 * Platform:    Any
 * WWW:         http://code.google.com/p/freetype-gl/
 * ----------------------------------------------------------------------------
 * Copyright 2011,2012 Nicolas P. Rougier. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY NICOLAS P. ROUGIER ''AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL NICOLAS P. ROUGIER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are
 * those of the authors and should not be interpreted as representing official
 * policies, either expressed or implied, of Nicolas P. Rougier.
 * ============================================================================
 */
#ifndef __FONT_MANAGER_H__
#define __FONT_MANAGER_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "vector.h"
#include "markup.h"
#include "texture-font.h"
#include "texture-atlas.h"



/**
 *
 */
typedef struct {
    /**
     *
     */
    texture_atlas_t * atlas;

    /**
     *
     */
    vector_t * fonts;

    /**
     *
     */
    wchar_t * cache;

} font_manager_t;



/**
 *
 */
  font_manager_t *
  font_manager_new( size_t width, size_t height, size_t depth );


/**
 *
 */
  void
  font_manager_delete( font_manager_t *self );


/**
 *
 */
  void
  font_manager_delete_font( font_manager_t * self,
                            texture_font_t * font );


/**
 *
 */
  texture_font_t *
  font_manager_get_from_filename( font_manager_t * self,
                                  const char * filename,
                                  const float size );


/**
 *
 */
  texture_font_t *
  font_manager_get_from_description( font_manager_t * self,
                                     const char * family,
                                     const float size,
                                     const int bold,
                                     const int italic );


/**
 *
 */
  texture_font_t *
  font_manager_get_from_markup( font_manager_t *self,
                                const markup_t *markup );


/**
 *
 */
  char *
  font_manager_match_description( font_manager_t * self,
                                  const char * family,
                                  const float size,
                                  const int bold,
                                  const int italic );


/**
 *
 */
  const wchar_t *
  font_manager_get_cache( font_manager_t * self );


/**
 *
 */
  void
  font_manager_set_cache( font_manager_t * self,
                          const wchar_t * cache );

#ifdef __cplusplus
}
#endif // ifdef __cplusplus

#endif /* __FONT_MANAGER_H__ */

