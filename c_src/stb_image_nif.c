#include <erl_nif.h>
#define STBI_NO_FAILURE_STRINGS
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#define STBI_MALLOC enif_alloc
#define STBI_REALLOC enif_realloc
#define STBI_FREE enif_free
#include <stb_image.h>
#include <stb_image_write.h>
#include <stb_image_resize.h>
#include <stdbool.h>
#include <stdio.h>

#define MAX_NAME_LENGTH 2048
#define MAX_EXTNAME_LENGTH 4

#include "nif_utils.h"

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-function"
#endif

static ERL_NIF_TERM pack_data(ErlNifEnv *env, unsigned char *data, int x, int y, int n, int bytes_per_channel) {
    if (data != NULL) {
        ErlNifBinary result;
        if (enif_alloc_binary(x * y * n * bytes_per_channel, &result)) {
            memcpy(result.data, data, result.size);

            return enif_make_tuple4(env,
                                    enif_make_atom(env, "ok"),
                                    enif_make_binary(env, &result),
                                    enif_make_tuple3(env,
                                                     enif_make_int(env, y),
                                                     enif_make_int(env, x),
                                                     enif_make_int(env, n)),
                                    enif_make_int(env, bytes_per_channel));
        } else {
            return error(env, "out of memory");
        }
    } else {
        return error(env, "cannot decode image");
    }
}

static ERL_NIF_TERM read_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 2) {
        return error(env, "expecting 2 arguments: path and desired_channels");
    }

    char path[MAX_NAME_LENGTH];
    int desired_channels, bytes_per_channel;

    if (!enif_get_string(env, argv[0], path, sizeof(path), ERL_NIF_LATIN1)) {
        return error(env, "invalid path");
    }
    if(!enif_get_int(env, argv[1], &desired_channels)) {
        return error(env, "invalid channels");
    }

    int x, y, n;
    unsigned char *data;

    FILE *f = stbi__fopen(path, "rb");
    if (!f) { return error(env, "could not open file"); }

    if (stbi_is_hdr_from_file(f)) {
        data = (unsigned char *)stbi_loadf_from_file(f, &x, &y, &n, desired_channels);
        bytes_per_channel = 4;
    } else {
        data = (unsigned char *)stbi_load_from_file(f, &x, &y, &n, desired_channels);
        bytes_per_channel = 1;
    }

    ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_channel);
    STBI_FREE((void *)data);
    fclose(f);
    return ret;
}

static ERL_NIF_TERM read_binary(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 2) {
        return error(env, "expecting 2 arguments: binary and desired_channels");
    }

    ErlNifBinary binary;
    int desired_channels, bytes_per_channel;
    int x, y, n;
    unsigned char *data;

    if (!enif_inspect_binary(env, argv[0], &binary)) {
        return error(env, "invalid binary");
    }
    if(!enif_get_int(env, argv[1], &desired_channels)) {
        return error(env, "invalid channels");
    }

    if (stbi_is_hdr_from_memory(binary.data, (int)binary.size)) {
        data = (unsigned char *)stbi_loadf_from_memory(binary.data, (int)binary.size, &x, &y, &n, desired_channels);
        bytes_per_channel = 4;
    } else {
        data = (unsigned char *)stbi_load_from_memory(binary.data, (int)binary.size, &x, &y, &n, desired_channels);
        bytes_per_channel = 1;
    }

    ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_channel);
    STBI_FREE((void *)data);
    return ret;
}

static ERL_NIF_TERM read_gif_binary(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 1) {
        return error(env, "expecting 1 argument: binary");
    }

    ErlNifBinary binary;

    if (enif_inspect_binary(env, argv[0], &binary)) {
        int x, y, z, comp;
        int *delays = NULL;
        unsigned char *data = NULL;
        // the parameter req_comp (the last one) seems to be not in use, see stb_image.h:6706
        data = stbi_load_gif_from_memory(binary.data, (int)binary.size, &delays, &x, &y, &z, &comp, 0);
        if (!data) {
            return error(env, "cannot decode the given GIF file");
        }

        ERL_NIF_TERM *delays_term = (ERL_NIF_TERM *)enif_alloc(sizeof(ERL_NIF_TERM) * z);
        ERL_NIF_TERM *frames_term = (ERL_NIF_TERM *)enif_alloc(sizeof(ERL_NIF_TERM) * z);
        ErlNifBinary *frames_result = (ErlNifBinary *)enif_alloc(sizeof(ErlNifBinary) * z);
        bool ok = true;
        unsigned char *start = data;
        size_t offset = x * y * sizeof(unsigned char);
        for (int i = 0; i < z; ++i) {
            if (enif_alloc_binary(x * y * sizeof(unsigned char), &frames_result[i])) {
                memcpy(frames_result[i].data, start, frames_result[i].size);
                frames_term[i] = enif_make_binary(env, &frames_result[i]);
                if (delays) {
                    delays_term[i] = enif_make_int(env, delays[i]);
                } else {
                    delays_term[i] = enif_make_int(env, -1);
                }

                start += offset;
            } else {
                ok = false;
                break;
            }
        }

        if (!ok) {
            STBI_FREE((void *)data);
            STBI_FREE((void *)delays);
            enif_free((void *)frames_term);
            enif_free((void *)delays_term);
            enif_free((void *)frames_result);
            return error(env, "out of memory");
        }

        ERL_NIF_TERM frames_ret = enif_make_list_from_array(env, frames_term, z);
        ERL_NIF_TERM delays_ret = enif_make_list_from_array(env, delays_term, z);
        ERL_NIF_TERM ret_val = enif_make_tuple4(env,
                                                enif_make_atom(env, "ok"),
                                                frames_ret,
                                                enif_make_tuple3(env,
                                                                 enif_make_int(env, y),
                                                                 enif_make_int(env, x),
                                                                 enif_make_int(env, 3)),
                                                delays_ret);
        STBI_FREE((void *)data);
        STBI_FREE((void *)delays);
        enif_free((void *)frames_term);
        enif_free((void *)delays_term);
        enif_free((void *)frames_result);
        return ret_val;
    } else {
        return enif_make_badarg(env);
    }
}

static ERL_NIF_TERM write_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 6) {
        return error(env, "expecting 6 arguments: path, format, data, height, width, and number of channels");
    }

    char path[MAX_NAME_LENGTH], format[MAX_EXTNAME_LENGTH];
    ErlNifBinary result;
    int w, h, comp;

    if (!enif_get_string(env, argv[0], path, sizeof(path), ERL_NIF_LATIN1)) {
        return error(env, "invalid path");
    }
    if (!enif_get_atom(env, argv[1], format, sizeof(format), ERL_NIF_LATIN1)) {
        return error(env, "invalid format");
    }
    if (!enif_inspect_binary(env, argv[2], &result)) {
        return error(env, "invalid binary data");
    }
    if (!enif_get_int(env, argv[3], &h)) {
        return error(env, "invalid height");
    }
    if (!enif_get_int(env, argv[4], &w)) {
        return error(env, "invalid width");
    }
    if (!enif_get_int(env, argv[5], &comp)) {
        return error(env, "invalid number of channels");
    }

    if (strcmp(format, "png") == 0) {
        int stride_in_bytes = 0;
        int status = stbi_write_png(path, w, h, comp, result.data, stride_in_bytes);
        if (!status) {
            return error(env, "failed to write png");
        }
    } else if (strcmp(format, "bmp") == 0) {
        int status = stbi_write_bmp(path, w, h, comp, result.data);
        if (!status) {
            return error(env, "failed to write bmp");
        }
    } else if (strcmp(format, "tga") == 0) {
        int status = stbi_write_tga(path, w, h, comp, result.data);
        if (!status) {
            return error(env, "failed to write tga");
        }
    } else if (strcmp(format, "jpg") == 0) {
        int quality = 100;
        int status = stbi_write_jpg(path, w, h, comp, result.data, quality);
        if (!status) {
            return error(env, "failed to write jpg");
        }
    } else if (strcmp(format, "hdr") == 0) {
        int status = stbi_write_hdr(path, w, h, comp, (float*)result.data);
        if (!status) {
            return error(env, "failed to write hdr");
        }
    } else {
        return error(env, "wrong format");
    }

    return enif_make_atom(env, "ok");
}

typedef struct WriteChunk {
    struct WriteChunk *next;
    void *data;
    size_t size;
} WriteChunk;

typedef struct {
    WriteChunk *head;
    WriteChunk *last;
    size_t size;
    bool out_of_memory;
} WriteContext;

static void write_chunk(void *context_, void *data, int size) {
    WriteContext *context = (WriteContext *) context_;

    if (context->out_of_memory) {
        return;
    }

    WriteChunk *chunk = enif_alloc(sizeof(WriteChunk));
    void *chunk_data = enif_alloc(size);

    if (chunk == NULL || chunk_data == NULL) {
        enif_free(chunk);
        enif_free(chunk_data);
        context->out_of_memory = true;
        return;
    }

    memcpy(chunk_data, data, size);

    chunk->next = NULL;
    chunk->data = chunk_data;
    chunk->size = size;

    if (context->head == NULL) {
        context->head = context->last = chunk;
    } else {
        context->last->next = chunk;
        context->last = chunk;
    }

    context->size += size;
}

static void finalize_write(WriteContext *context, ErlNifEnv *env, ERL_NIF_TERM *binary) {
    if (!context->out_of_memory) {
        char *buffer = (char *)enif_make_new_binary(env, context->size, binary);

        if (buffer == NULL) {
            context->out_of_memory = true;
        } else {
            for (WriteChunk *chunk = context->head; chunk != NULL; chunk = chunk->next) {
                memcpy(buffer, chunk->data, chunk->size);
                buffer += chunk->size;
            }
        }
    }

    WriteChunk *chunk = context->head;
    WriteChunk *next = NULL;

    while (chunk != NULL) {
        next = chunk->next;
        enif_free(chunk->data);
        enif_free(chunk);
        chunk = next;
    }
}

static ERL_NIF_TERM to_binary(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 5) {
        return error(env, "expecting 5 arguments: format, data, height, width, and number of channels");
    }

    char format[MAX_EXTNAME_LENGTH];
    ErlNifBinary img;
    int w, h, comp;

    if (!enif_get_atom(env, argv[0], format, sizeof(format), ERL_NIF_LATIN1)) {
        return error(env, "invalid format");
    }
    if (!enif_inspect_binary(env, argv[1], &img)) {
        return error(env, "invalid binary data");
    }
    if (!enif_get_int(env, argv[2], &h)) {
        return error(env, "invalid height");
    }
    if (!enif_get_int(env, argv[3], &w)) {
        return error(env, "invalid width");
    }
    if (!enif_get_int(env, argv[4], &comp)) {
        return error(env, "invalid number of channels");
    }

    // The write_chunk function is called multiple times with subsequent
    // data chunks, we create a list of those and join afterwards
    WriteContext context = { .head = NULL, .last = NULL, .size = 0, .out_of_memory = false };
    ERL_NIF_TERM binary;

    if (strcmp(format, "png") == 0) {
        int stride_in_bytes = 0;
        int status = stbi_write_png_to_func(write_chunk, (void*) &context, w, h, comp, img.data, stride_in_bytes);
        finalize_write(&context, env, &binary);
        if (!status) {
            return error(env, "failed to write png");
        }
    } else if (strcmp(format, "bmp") == 0) {
        int status = stbi_write_bmp_to_func(write_chunk, (void*) &context, w, h, comp, img.data);
        finalize_write(&context, env, &binary);
        if (!status) {
            return error(env, "failed to write bmp");
        }
    } else if (strcmp(format, "tga") == 0) {
        int status = stbi_write_tga_to_func(write_chunk, (void*) &context, w, h, comp, img.data);
        finalize_write(&context, env, &binary);
        if (!status) {
            return error(env, "failed to write tga");
        }
    } else if (strcmp(format, "jpg") == 0) {
        int quality = 100;
        int status = stbi_write_jpg_to_func(write_chunk, (void*) &context, w, h, comp, img.data, quality);
        finalize_write(&context, env, &binary);
        if (!status) {
            return error(env, "failed to write jpg");
        }
    } else if (strcmp(format, "hdr") == 0) {
        int status = stbi_write_hdr_to_func(write_chunk, (void*) &context, w, h, comp, (float*)img.data);
        finalize_write(&context, env, &binary);
        if (!status) {
            return error(env, "failed to write hdr");
        }
    } else {
        return error(env, "wrong format");
    }

    if (context.out_of_memory) {
        return error(env, "out of memory");
    }

    return enif_make_tuple2(env, enif_make_atom(env, "ok"), binary);
}

static ERL_NIF_TERM resize(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]){
    if (argc != 7) {
        return error(env, "expecting 7 arguments: input pixels, input height, input width, number of channels, output height, output width, and bytes per channel");
    }

    ErlNifBinary input_pixels;
    int input_h, input_w, output_h, output_w, num_channels, bytes_per_channel;
    int stride_in_bytes = 0;

    if (!enif_inspect_binary(env, argv[0], &input_pixels)) {
        return error(env, "invalid image");
    }
    if(!enif_get_int(env, argv[1], &input_h)) {
        return error(env, "invalid input height");
    }
    if(!enif_get_int(env, argv[2], &input_w)) {
        return error(env, "invalid input width");
    }
    if(!enif_get_int(env, argv[3], &num_channels)) {
        return error(env, "invalid number of channels");
    }
    if(!enif_get_int(env, argv[4], &output_h)) {
        return error(env, "invalid output height");
    }
    if(!enif_get_int(env, argv[5], &output_w)) {
        return error(env, "invalid output width");
    }
    if(!enif_get_int(env, argv[6], &bytes_per_channel)) {
        return error(env, "invalid bytes per channel");
    }

    int status;
    ErlNifBinary result;

    if (enif_alloc_binary(output_w * output_h * num_channels * bytes_per_channel, &result)) {
        if (bytes_per_channel == 1) {
            status = stbir_resize_uint8(input_pixels.data, input_w, input_h, stride_in_bytes, result.data, output_w, output_h, stride_in_bytes, num_channels);
        } else if (bytes_per_channel == 4) {
            status = stbir_resize_float((float *)input_pixels.data, input_w, input_h, stride_in_bytes, (float *)result.data, output_w, output_h, stride_in_bytes, num_channels);
        } else {
            return error(env, "invalid type");
        }

        if (!status) {
            return error(env, "failed to resize");
        }

        return enif_make_tuple2(env, enif_make_atom(env, "ok"), enif_make_binary(env, &result));
    } else {
        return error(env, "out of memory");
    }
}

static int on_load(ErlNifEnv *env, void **_sth1, ERL_NIF_TERM _sth2) {
    return 0;
}

static int on_reload(ErlNifEnv *_sth0, void **_sth1, ERL_NIF_TERM _sth2) {
    return 0;
}

static int on_upgrade(ErlNifEnv *_sth0, void **_sth1, void **_sth2, ERL_NIF_TERM _sth3) {
    return 0;
}

static ErlNifFunc nif_functions[] = {
    {"read_file", 2, read_file, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"read_binary", 2, read_binary, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"read_gif_binary", 1, read_gif_binary, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"write_file", 6, write_file, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"to_binary", 5, to_binary, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"resize", 7, resize, ERL_NIF_DIRTY_JOB_CPU_BOUND}};

ERL_NIF_INIT(Elixir.StbImage.Nif, nif_functions, on_load, on_reload, on_upgrade, NULL);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#endif
