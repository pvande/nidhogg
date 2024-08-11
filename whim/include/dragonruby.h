#ifndef DRAGONRUBY_DRAGONRUBY_H
#define DRAGONRUBY_DRAGONRUBY_H

// clang-format off
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/class.h>
#include <mruby/data.h>
#include <mruby/irep.h>
#include <mruby/debug.h>
#include <mruby/dump.h>
#include <mruby/error.h>
#include <mruby/hash.h>
#include <mruby/numeric.h>
#include <mruby/proc.h>
#include <mruby/range.h>
#include <mruby/string.h>
#include <mruby/variable.h>
#include <stdlib.h>
// clang-format on
#if defined(_WIN32)
#include <windows.h>
#endif

#if defined(_WIN32)
#define DRB_FFI_EXPORT __declspec(dllexport)
#elif defined(__GNUC__) || defined(__clang__)
#define DRB_FFI_EXPORT __attribute__((visibility("default")))
#else
#define DRB_FFI_EXPORT
#endif

#ifndef __DRB_ANNOTATE
#define __DRB_ANNOTATE(key, value) __attribute__((annotate(key #value)))
#endif

#ifndef DRB_FFI_NAME
#define DRB_FFI_NAME(name) __DRB_ANNOTATE("drb_ffi:", name)
#endif

#ifndef DRB_FFI
#define DRB_FFI __DRB_ANNOTATE("drb_ffi:", )
#endif

typedef enum drb_foreign_object_kind {
  drb_foreign_object_kind_struct,
  drb_foreign_object_kind_pointer
} drb_foreign_object_kind;

typedef struct drb_foreign_object {
  drb_foreign_object_kind kind;
} drb_foreign_object;

// SDL defines these, this is just here if SDL.h wasn't included.
#ifndef SDL_stdinc_h_
typedef int8_t Sint8;
typedef int16_t Sint16;
typedef int32_t Sint32;
typedef int64_t Sint64;
typedef uint8_t Uint8;
typedef uint16_t Uint16;
typedef uint32_t Uint32;
typedef uint64_t Uint64;
typedef struct _SDL_iconv_t *SDL_iconv_t;
#endif

// PhysicsFS defines these, this is just here if physfs.h wasn't included.
#ifndef _INCLUDE_PHYSFS_H_
typedef int8_t PHYSFS_sint8;
typedef int16_t PHYSFS_sint16;
typedef int32_t PHYSFS_sint32;
typedef int64_t PHYSFS_sint64;
typedef uint8_t PHYSFS_uint8;
typedef uint16_t PHYSFS_uint16;
typedef uint32_t PHYSFS_uint32;
typedef uint64_t PHYSFS_uint64;

typedef struct PHYSFS_File PHYSFS_File;

typedef enum PHYSFS_ErrorCode
{
    PHYSFS_ERR_OK,               /**< Success; no error.                    */
    PHYSFS_ERR_OTHER_ERROR,      /**< Error not otherwise covered here.     */
    PHYSFS_ERR_OUT_OF_MEMORY,    /**< Memory allocation failed.             */
    PHYSFS_ERR_NOT_INITIALIZED,  /**< PhysicsFS is not initialized.         */
    PHYSFS_ERR_IS_INITIALIZED,   /**< PhysicsFS is already initialized.     */
    PHYSFS_ERR_ARGV0_IS_NULL,    /**< Needed argv[0], but it is NULL.       */
    PHYSFS_ERR_UNSUPPORTED,      /**< Operation or feature unsupported.     */
    PHYSFS_ERR_PAST_EOF,         /**< Attempted to access past end of file. */
    PHYSFS_ERR_FILES_STILL_OPEN, /**< Files still open.                     */
    PHYSFS_ERR_INVALID_ARGUMENT, /**< Bad parameter passed to an function.  */
    PHYSFS_ERR_NOT_MOUNTED,      /**< Requested archive/dir not mounted.    */
    PHYSFS_ERR_NOT_FOUND,        /**< File (or whatever) not found.         */
    PHYSFS_ERR_SYMLINK_FORBIDDEN,/**< Symlink seen when not permitted.      */
    PHYSFS_ERR_NO_WRITE_DIR,     /**< No write dir has been specified.      */
    PHYSFS_ERR_OPEN_FOR_READING, /**< Wrote to a file opened for reading.   */
    PHYSFS_ERR_OPEN_FOR_WRITING, /**< Read from a file opened for writing.  */
    PHYSFS_ERR_NOT_A_FILE,       /**< Needed a file, got a directory (etc). */
    PHYSFS_ERR_READ_ONLY,        /**< Wrote to a read-only filesystem.      */
    PHYSFS_ERR_CORRUPT,          /**< Corrupted data encountered.           */
    PHYSFS_ERR_SYMLINK_LOOP,     /**< Infinite symbolic link loop.          */
    PHYSFS_ERR_IO,               /**< i/o error (hardware failure, etc).    */
    PHYSFS_ERR_PERMISSION,       /**< Permission denied.                    */
    PHYSFS_ERR_NO_SPACE,         /**< No space (disk full, over quota, etc) */
    PHYSFS_ERR_BAD_FILENAME,     /**< Filename is bogus/insecure.           */
    PHYSFS_ERR_BUSY,             /**< Tried to modify a file the OS needs.  */
    PHYSFS_ERR_DIR_NOT_EMPTY,    /**< Tried to delete dir with files in it. */
    PHYSFS_ERR_OS_ERROR,         /**< Unspecified OS-level error.           */
    PHYSFS_ERR_DUPLICATE,        /**< Duplicate entry.                      */
    PHYSFS_ERR_BAD_PASSWORD,     /**< Bad password.                         */
    PHYSFS_ERR_APP_CALLBACK      /**< Application callback reported error.  */
} PHYSFS_ErrorCode;

typedef enum PHYSFS_FileType
{
    PHYSFS_FILETYPE_REGULAR, /**< a normal file */
    PHYSFS_FILETYPE_DIRECTORY, /**< a directory */
    PHYSFS_FILETYPE_SYMLINK, /**< a symlink */
    PHYSFS_FILETYPE_OTHER /**< something completely different like a device */
} PHYSFS_FileType;

typedef struct PHYSFS_Stat
{
    PHYSFS_sint64 filesize; /**< size in bytes, -1 for non-files and unknown */
    PHYSFS_sint64 modtime;  /**< last modification time */
    PHYSFS_sint64 createtime; /**< like modtime, but for file creation time */
    PHYSFS_sint64 accesstime; /**< like modtime, but for file access time */
    PHYSFS_FileType filetype; /**< File? Directory? Symlink? */
    int readonly; /**< non-zero if read only, zero if writable. */
} PHYSFS_Stat;
#endif

// These are conflicting with typedefs
#undef mrb_int
#undef mrb_bool
#undef mrb_float

typedef struct drb_api_t {
#define DRB_FFI_EXPOSE(type, name) type;
#include <dragonruby.h.inc>
#undef DRB_FFI_EXPOSE
} drb_api_t;

// Restoring macros
#define mrb_int(mrb, val) mrb_integer(mrb_to_int(mrb, val))
#define mrb_bool(o) (((o).w & ~(uintptr_t)MRB_Qfalse) != 0)
#define mrb_float(o) mrb_val_union(o).fp->f

#endif // DRAGONRUBY_DRAGONRUBY_H
