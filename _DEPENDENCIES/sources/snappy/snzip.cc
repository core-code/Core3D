// Copyright 2011 Kubo Takehiro <kubo@jiubao.org>
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


// The next line should be at the first because macros for large-file
// support is defined in config.h.
#include "snappy-stubs-internal.h"

#include <stdio.h>
#include <stdarg.h>
#include <errno.h>
#include <limits.h>
#include <sys/types.h>
#include <fcntl.h>
#ifdef WIN32
#undef ARRAYSIZE
#include <windows.h>
#include <io.h>
#ifndef PATH_MAX
#define PATH_MAX MAX_PATH
#endif
#define PATH_DELIMITER '\\'
#define OPTIMIZE_SEQUENTIAL "S" // flag to optimize sequential access
#else // WIN32
#include <sys/time.h>
#include <sys/stat.h>
#define PATH_DELIMITER '/'
#define OPTIMIZE_SEQUENTIAL ""
#endif // WIN32
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include "snappy.h"

#define SNZ_SUFFIX ".snz"
#define SNZ_SUFFIX_LEN 4

#define SNZ_MAGIC "SNZ"
#define SNZ_MAGIC_LEN 3
#define SNZ_FILE_VERSION 1

#define SNZ_DEFAULT_BLOCK_SIZE 16 // 64 Ki
#define SNZ_MAX_BLOCK_SIZE 27 // 128 Mi

#if defined HAVE_STRUCT_STAT_ST_MTIMENSEC
#define SNZ_ST_TIME_NSEC(sbuf, type) ((sbuf).st_##type##timensec)
#elif defined HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC
#define SNZ_ST_TIME_NSEC(sbuf, type) ((sbuf).st_##type##tim.tv_nsec)
#elif defined HAVE_STRUCT_STAT_ST_MTIMESPEC_TV_NSEC
#define SNZ_ST_TIME_NSEC(sbuf, type) ((sbuf).st_##type##timespec.tv_nsec)
#else
#define SNZ_ST_TIME_NSEC(sbuf, type) (0)
#endif

static bool trace_flag = false;

typedef struct {
  char magic[SNZ_MAGIC_LEN]; // SNZ_MAGIC
  char version;  // SNZ_FILE_VERSION
  unsigned char block_size; // nth power of two.
} snz_header_t;

static bool compress(FILE *infp, FILE *outfp, int block_size);
static bool uncompress(FILE *infp, FILE *outfp);
static void copy_file_attributes(int infd, int outfd, const char *outfile);
static void show_usage(const char *progname, int exit_code);

static int lineno;

#ifdef __GNUC__
static void print_error(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
static void trace(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
#endif

static void print_error(const char *fmt, ...)
{
  if (trace_flag) {
    fprintf(stderr, "%s:%3d: ", __FILE__, lineno);
  }
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}
#define print_error (lineno = __LINE__, print_error)

static void trace(const char *fmt, ...)
{
  if (!trace_flag) {
    return;
  }
  fprintf(stderr, "%s:%3d: ", __FILE__, lineno);
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}
#define trace (lineno = __LINE__, trace)

static int write_full(int fd, const void *buf, size_t count)
{
  const char *ptr = (const char *)buf;

  while (count > 0) {
    int rv = write(fd, ptr, count);
    if (rv == -1) {
      if (errno == EINTR) {
	continue;
      }
      return -1;
    }
    ptr += rv;
    count -= rv;
  }
  return (ptr - (const char *)buf);
}

class WorkMem {
public:
  WorkMem(int block_size) {
    uclen = (1 << block_size);
    uc = new char[uclen];
    clen = snappy::MaxCompressedLength(uclen);
    c = new char[clen];
    trace("max length of compressed data = %lu\n", clen);
    trace("max length of uncompressed data = %lu\n", uclen);
  }
  ~WorkMem() {
    delete[] c;
    delete[] uc;
  }
  size_t clen; // maximum length of compressed data
  size_t uclen; // maximum length of uncompressed data
  char *c; // buffer for compressed data
  char *uc; // buffer for uncompressed data
};

int main(int argc, char **argv)
{
  int opt;
  bool opt_uncompress = false;
  bool opt_stdout = false;
  int block_size = SNZ_DEFAULT_BLOCK_SIZE;
  size_t rsize = 0;
  size_t wsize = 0;

  char *progname = strrchr(argv[0], PATH_DELIMITER);
  if (progname != NULL) {
    progname++;
  } else {
    progname = argv[0];
  }

  trace("progname = %s\n", progname);
  if (strstr(progname, "un") != NULL) {
    trace("\"un\" is found in %s\n", progname);
    opt_uncompress = true;
  }
  if (strstr(progname, "cat") != NULL) {
    trace("\"cat\" is found in %s\n", progname);
    opt_stdout = true;
    opt_uncompress = true;
  }

  while ((opt = getopt(argc, argv, "cdhB:R:W:T")) != -1) {
    switch (opt) {
    case 'c':
      opt_stdout = true;
      break;
    case 'd':
      opt_uncompress = true;
      break;
    case 'h':
      show_usage(progname, 0);
      break;
    case 'B':
      block_size = atoi(optarg);
      if (block_size < 1 || block_size > SNZ_MAX_BLOCK_SIZE) {
        print_error("Invalid block size %d (max %d)\n", block_size, SNZ_MAX_BLOCK_SIZE);
        exit(1);
      }
      break;
    case 'R':
      rsize = strtoul(optarg, NULL, 10);
      break;
    case 'W':
      wsize = strtoul(optarg, NULL, 10);
      break;
    case 'T':
      trace_flag = true;
      break;
    case '?':
      show_usage(progname, 1);
      break;
    }
  }

#ifdef WIN32
  _setmode(0, _O_BINARY);
  _setmode(1, _O_BINARY);
#endif

  if (optind == argc) {
    trace("no arguments are set.\n");
    if (isatty(1)) {
      // stdout is a terminal
      fprintf(stderr, "I won't write compressed data to a terminal.\n");
      fprintf(stderr, "For help, type: '%s -h'.\n", progname);
      return 1;
    }

    if (opt_uncompress) {
      return uncompress(stdin, stdout);
    } else {
      return compress(stdin, stdout, block_size);
    }
  }

  while (optind < argc) {
    char *infile = argv[optind++];
    size_t infilelen = strlen(infile);
    char outfile[PATH_MAX];

    /* check suffix */
    const char *suffix = strrchr(infile, '.');
    if (suffix == NULL) {
      suffix = "";
    }
    int has_snp_suffix = (strcmp(suffix, SNZ_SUFFIX) == 0);

    if (opt_uncompress) {
      if (!has_snp_suffix) {
        print_error("%s has unknown suffix.\n", infile);
        continue;
      }
      if (opt_stdout) {
        strcpy(outfile, "-");
      } else {
        if (infilelen - SNZ_SUFFIX_LEN >= sizeof(outfile)) {
          print_error("%s has too long file name.\n", infile);
        }
        memcpy(outfile, infile, infilelen - SNZ_SUFFIX_LEN);
        outfile[infilelen - SNZ_SUFFIX_LEN] = '\0';
      }
    } else {
      if (has_snp_suffix) {
        print_error("%s already has %s suffix\n", infile, SNZ_SUFFIX);
        continue;
      }
      if (opt_stdout) {
        strcpy(outfile, "-");
      } else {
        if (infilelen + SNZ_SUFFIX_LEN >= sizeof(outfile)) {
          print_error("%s has too long file name.\n", infile);
        }
        strcpy(outfile, infile);
        strcat(outfile, SNZ_SUFFIX);
      }
    }

    FILE *infp = fopen(infile, "rb" OPTIMIZE_SEQUENTIAL);
    if (infp == NULL) {
      print_error("Failed to open %s for read\n", infile);
      exit(1);
    }
    if (rsize != 0) {
      trace("setvbuf(infp, NULL, _IOFBF, %ld)\n", (long)rsize);
      setvbuf(infp, NULL, _IOFBF, rsize);
    }
#ifdef HAVE_POSIX_FADVISE
    posix_fadvise(fileno(infp), 0, 0, POSIX_FADV_SEQUENTIAL);
#endif

    FILE *outfp;
    if (opt_stdout) {
      outfp = stdout;
    } else {
      outfp = fopen(outfile, "wb" OPTIMIZE_SEQUENTIAL);
      if (outfp == NULL) {
        print_error("Failed to open %s for write\n", outfile);
        exit(1);
      }
    }
    if (wsize != 0) {
      trace("setvbuf(outfp, NULL, _IOFBF, %ld)\n", (long)wsize);
      setvbuf(outfp, NULL, _IOFBF, wsize);
    }

    if (opt_uncompress) {
      trace("uncompress %s\n", infile);
      if (!uncompress(infp, outfp)) {
        if (outfp != stdout) {
          unlink(outfile);
        }
        return 1;
      }
    } else {
      trace("compress %s\n", infile);
      if (!compress(infp, outfp, block_size)) {
        if (outfp != stdout) {
          unlink(outfile);
        }
        return 1;
      }
    }

    if (!opt_stdout) {
      fflush(outfp);
      copy_file_attributes(fileno(infp), fileno(outfp), outfile);
    }

    fclose(infp);
    if (outfp != stdout) {
      fclose(outfp);
    }

    if (!opt_stdout) {
      int rv = unlink(infile);
      trace("unlink(\"%s\") => %d (errno = %d)\n",
            infile, rv, rv ? errno : 0);
    }
  }
  return 0;
}

static bool compress(FILE *infp, FILE *outfp, int block_size)
{
  // write header
  snz_header_t header;
  memcpy(header.magic, SNZ_MAGIC, SNZ_MAGIC_LEN);
  header.version = SNZ_FILE_VERSION;
  header.block_size = block_size;

  if (fwrite(&header, sizeof(header), 1, outfp) != 1) {
    print_error("Failed to write a file: %s\n", strerror(errno));
    return false;
  }

  // write body
  WorkMem wm(block_size);
  for (;;) {
    int uncompressed_length = fread(wm.uc, 1, wm.uclen, infp);
    trace("read %d bytes.\n", uncompressed_length);
    if (uncompressed_length < 0) {
      print_error("Failed to read a file: %s\n", strerror(errno));
      return false;
    }
    if (uncompressed_length == 0) {
      break;
    }

    // compress the block.
    size_t compressed_length = 0;
    snappy::RawCompress(wm.uc, uncompressed_length, wm.c, &compressed_length);
    trace("compressed_legnth is %ld.\n", (long)compressed_length);

    // write the compressed_length.
    char work[snappy::Varint::kMax32];
    size_t work_len = snappy::Varint::Encode32(work, compressed_length) - work;
    if (fwrite(work, work_len, 1, outfp) != 1) {
      print_error("Failed to write a file: %s\n", strerror(errno));
      return false;
    }

    if (fwrite(wm.c, compressed_length, 1, outfp) != 1) {
      print_error("Failed to write a file: %s\n", strerror(errno));
      return false;
    }
    trace("write %ld bytes\n", (long)(work_len + compressed_length));
  }
  fputc('\0', outfp);
  trace("write 1 byte\n");
  return true;
}

static bool uncompress(FILE *infp, FILE *outfp)
{
  snz_header_t header;

  // read header
  if (fread(&header, sizeof(header), 1, infp) != 1) {
    print_error("Failed to read a file: %s\n", strerror(errno));
    return false;
  }

  // check header
  if (memcmp(header.magic, SNZ_MAGIC, SNZ_MAGIC_LEN) != 0) {
    print_error("This is not a snz file.\n");
    return false;
  }
  if (header.version != SNZ_FILE_VERSION) {
    print_error("Unknown snz version %d\n", header.version);
    return false;
  }
  if (header.block_size > SNZ_MAX_BLOCK_SIZE) {
    print_error("Invalid block size %d (max %d)\n", header.block_size, SNZ_MAX_BLOCK_SIZE);
    return false;
  }

  // Use a file descriptor 'outfd' instead of the stdio file pointer 'outfp'
  // to reduce the number of write system calls.
  fflush(outfp);
  int outfd = fileno(outfp);

  // read body
  WorkMem wm(header.block_size);
  for (;;) {
    // read the compressed length in a block
    size_t compressed_length = 0;
    int idx;
    for (idx = 0; idx < snappy::Varint::kMax32; idx++) {
      int chr = fgetc(infp);
      if (chr == -1) {
        print_error("Unexpected end of file.\n");
        return false;
      }
      compressed_length |= ((chr & 127) << (idx * 7));
      if ((chr & 128) == 0) {
        break;
      }
    }
    trace("read %d bytes (compressed_length = %ld)\n", idx + 1, (long)compressed_length);
    if (idx == snappy::Varint::kMax32) {
      print_error("Invalid format.\n");
      return false;
    }
    if (compressed_length == 0) {
      // read all blocks
      return true;
    }
    if (compressed_length > wm.clen) {
      print_error("Invalid data: too long compressed length\n");
      return false;
    }

    // read the compressed data
    if (fread(wm.c, compressed_length, 1, infp) != 1) {
      if (feof(infp)) {
        print_error("Unexpected end of file\n");
      } else {
        print_error("Failed to read a file: %s\n", strerror(errno));
      }
      return false;
    }
    trace("read %ld bytes.\n", (long)(idx + compressed_length));

    // check the uncompressed length
    size_t uncompressed_length;
    if (!snappy::GetUncompressedLength(wm.c, compressed_length, &uncompressed_length)) {
      print_error("Invalid data: GetUncompressedLength failed\n");
      return false;
    }
    if (uncompressed_length > wm.uclen) {
      print_error("Invalid data: too long uncompressed length\n");
      return false;
    }

    // uncompress and write
    if (!snappy::RawUncompress(wm.c, compressed_length, wm.uc)) {
      print_error("Invalid data: RawUncompress failed\n");
      return false;
    }
    if (write_full(outfd, wm.uc, uncompressed_length) != uncompressed_length) {
      print_error("Failed to write a file: %s\n", strerror(errno));
      return false;
    }
    trace("write %ld bytes\n", (long)uncompressed_length);
  }
}

static void copy_file_attributes(int infd, int outfd, const char *outfile)
{
#ifdef WIN32
  BY_HANDLE_FILE_INFORMATION fi;
  BOOL bOk;

  bOk = GetFileInformationByHandle((HANDLE)_get_osfhandle(infd), &fi);
  trace("GetFileInformationByHandle(...) => %s\n", bOk ? "TRUE" : "FALSE");
  if (bOk) {
    bOk = SetFileTime((HANDLE)_get_osfhandle(outfd), NULL, &fi.ftLastAccessTime, &fi.ftLastWriteTime);
    trace("SetFileTime(...) => %s\n", bOk ? "TRUE" : "FALSE");
    bOk = SetFileAttributesA(outfile, fi.dwFileAttributes);
    trace("SetFileAttributesA(...) => %s\n", bOk ? "TRUE" : "FALSE");
  }
#else
  int rv;

  struct stat sbuf;
  if ((rv = fstat(infd, &sbuf)) != 0) {
    trace("fstat(%d, &sbuf) => %d (errno = %d)\n",
          infd, rv, errno);
    return;
  }

  // copy file times.
#ifdef HAVE_FUTIMENS
  struct timespec times[2];
  times[0].tv_sec = sbuf.st_atime;
  times[0].tv_nsec = SNZ_ST_TIME_NSEC(sbuf, a);
  times[1].tv_sec = sbuf.st_mtime;
  times[1].tv_nsec = SNZ_ST_TIME_NSEC(sbuf, m);
  rv = futimens(outfd, times);
  trace("futimens(%d, [{%ld, %ld}, {%ld, %ld}]) => %d\n",
        outfd, times[0].tv_sec, times[0].tv_nsec,
        times[1].tv_sec, times[1].tv_nsec, rv);
#else // HAVE_FUTIMENS
  struct timeval times[2];
  times[0].tv_sec = sbuf.st_atime;
  times[0].tv_usec = SNZ_ST_TIME_NSEC(sbuf, a) / 1000;
  times[1].tv_sec = sbuf.st_mtime;
  times[1].tv_usec = SNZ_ST_TIME_NSEC(sbuf, m) / 1000;
#ifdef HAVE_FUTIMES
  rv = futimes(outfd, times);
  trace("futimes(%d, [{%ld, %ld}, {%ld, %ld}]) => %d\n",
        outfd, times[0].tv_sec, times[0].tv_usec,
        times[1].tv_sec, times[1].tv_usec, rv);
#else // HAVE_FUTIMES
  rv = utimes(outfile, times);
  trace("utimes(\"%s\", [{%ld, %ld}, {%ld, %ld}]) => %d\n",
        outfile, times[0].tv_sec, times[0].tv_usec,
        times[1].tv_sec, times[1].tv_usec, rv);
#endif // HAVE_FUTIMES
#endif // HAVE_FUTIMENS

  // copy other attributes
  rv = fchown(outfd, sbuf.st_uid, sbuf.st_gid);
  trace("fchown(%d, %d, %d) => %d\n",
        outfd, sbuf.st_uid, sbuf.st_gid, rv);
  rv = fchmod(outfd, sbuf.st_mode);
  trace("fchmod(%d, 0%o) => %d\n",
        outfd, sbuf.st_mode, rv);
#endif
}

static void show_usage(const char *progname, int exit_code)
{
  fprintf(stderr,
          PACKAGE_STRING "\n"
          "\n"
          "  usage: %s [option ...] [file ...]\n"
          "\n"
          "  general options:\n"
          "   -c       output to standard output, keep original files unchanged\n"
          "   -d       decompress\n"
          "   -h       give this help\n"
          "\n"
          "  tuning options:\n"
          "   -B num   internal block size. 'num'-th power of two. (default is %d.)\n"
          "   -R num   size of read buffer in bytes\n"
          "   -W num   size of write buffer in bytes\n"
          "   -T       trace for debug\n",
          progname, SNZ_DEFAULT_BLOCK_SIZE);
  exit(exit_code);
}
