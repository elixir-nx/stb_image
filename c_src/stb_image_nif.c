#include <erl_nif.h>
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb_image.h>
#include <stb_image_write.h>
#include <stdbool.h>
#include <stdio.h>

#define MAX_NAME_LENGTH 2048
#define MAX_TYPE_LENGTH 4
#define MAX_EXTNAME_LENGTH 4

#include "nif_utils.h"

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#pragma GCC diagnostic ignored "-Wunused-variable"
#pragma GCC diagnostic ignored "-Wunused-function"
#endif

static ERL_NIF_TERM pack_data(ErlNifEnv *env, unsigned char *data, int x, int y, int n, int bytes_per_channel, const char *type) {
    if (data != NULL) {
        ErlNifBinary result;
        if (enif_alloc_binary(x * y * n * bytes_per_channel, &result)) {
            memcpy(result.data, data, result.size);
            const char *channel_types[] = {"l", "la", "rgb", "rgba"};
            const char *channels = "unknown";
            if (n >= 1 && n <= 4) {
                channels = channel_types[n - 1];
            }
            return enif_make_tuple5(env,
                                    enif_make_atom(env, "ok"),
                                    enif_make_binary(env, &result),
                                    enif_make_tuple3(env,
                                                     enif_make_int(env, y),
                                                     enif_make_int(env, x),
                                                     enif_make_int(env, n)),
                                    enif_make_atom(env, type),
                                    enif_make_atom(env, channels));
        } else {
            return enif_make_tuple2(env,
                                    enif_make_atom(env, "error"),
                                    enif_make_string(env, "out of memory", ERL_NIF_LATIN1));
        }
    } else {
        return enif_make_tuple2(env,
                                enif_make_atom(env, "error"),
                                enif_make_string(env, "cannot decode image", ERL_NIF_LATIN1));
    }
}

static ERL_NIF_TERM from_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 3) {
        return error(env, "expecting 3 arguments: filename, desired_channels, type");
    }
    char type[MAX_TYPE_LENGTH];
    char filename[MAX_NAME_LENGTH];
    int desired_channels = 0;

    if (!enif_get_string(env, argv[0], filename, sizeof(filename), ERL_NIF_LATIN1)) {
        return error(env, "invalid filename");
    }

    if(!enif_get_int(env, argv[1], &desired_channels)) {
        return error(env, "invalid channels");
    }

    if(!enif_get_atom(env, argv[2], type, sizeof(type), ERL_NIF_LATIN1)) {
        return error(env, "invalid type");
    }

    int bytes_per_channel;
    int x, y, n;
    unsigned char *data;
    if (strcmp(type, "u8") == 0) {
        data = (unsigned char *)stbi_load(filename, &x, &y, &n, desired_channels);
        bytes_per_channel = sizeof(unsigned char);
    } else if (strcmp(type, "u16") == 0) {
        data = (unsigned char *)stbi_load_16(filename, &x, &y, &n, desired_channels);
        bytes_per_channel = sizeof(unsigned char);
    } else if (strcmp(type, "f32") == 0) {
        data = (unsigned char *)stbi_loadf(filename, &x, &y, &n, desired_channels);
        bytes_per_channel = sizeof(float);
    } else
        return error(env, "invalid type");

    ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_channel, type);
    free((void *)data);
    return ret;
}

static ERL_NIF_TERM from_memory(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 3) {
        return error(env, "expecting 3 arguments: buffer, desired_channels, type");
    }
    ErlNifBinary result;
    int desired_channels = 0;
    char type[MAX_NAME_LENGTH];
    int x, y, n;
    unsigned char *data;

    if (!enif_inspect_binary(env, argv[0], &result)) {
        return error(env, "invalid buffer");
    }

    if(!enif_get_int(env, argv[1], &desired_channels)) {
        return error(env, "invalid channels");
    }

    if(!enif_get_atom(env, argv[2], type, sizeof(type), ERL_NIF_LATIN1)) {
        return error(env, "invalid type");
    }

    int bytes_per_channel;

    if (strcmp(type, "u8") == 0) {
        data = (unsigned char *)stbi_load_from_memory(result.data, (int)result.size, &x, &y, &n, desired_channels);
        bytes_per_channel = sizeof(unsigned char);
    } else if (strcmp(type, "u16") == 0) {
        data = (unsigned char *)stbi_load_16_from_memory(result.data, (int)result.size, &x, &y, &n, desired_channels);
        bytes_per_channel = sizeof(unsigned char);
    } else if (strcmp(type, "f32") == 0) {
        data = (unsigned char *)stbi_loadf_from_memory(result.data, (int)result.size, &x, &y, &n, desired_channels);
        bytes_per_channel = sizeof(float);
    } else
        return error(env, "invalid type");

    ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_channel, type);
    free((void *)data);
    return ret;
}

static ERL_NIF_TERM gif_from_memory(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 1) {
        return error(env, "expecting 1 argument: buffer");
    }
    ErlNifBinary result;
    if (enif_inspect_binary(env, argv[0], &result)) {
        int x, y, z, comp;
        int *delays = NULL;
        unsigned char *data = NULL;
        // the parameter req_comp (the last one) seems to be not in use, see stb_image.h:6706
        data = stbi_load_gif_from_memory(result.data, (int)result.size, &delays, &x, &y, &z, &comp, 0);
        if (!data) {
            return enif_make_tuple2(env,
                                    enif_make_atom(env, "error"),
                                    enif_make_string(env, "cannot decode the given GIF file", ERL_NIF_LATIN1));
        }

        ERL_NIF_TERM *delays_term = (ERL_NIF_TERM *)malloc(sizeof(ERL_NIF_TERM) * z);
        ERL_NIF_TERM *frames_term = (ERL_NIF_TERM *)malloc(sizeof(ERL_NIF_TERM) * z);
        ErlNifBinary *frames_result = (ErlNifBinary *)malloc(sizeof(ErlNifBinary) * z);
        ;
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
            free((void *)data);
            free((void *)frames_term);
            free((void *)delays_term);
            free((void *)frames_result);
            free((void *)delays);
            return enif_make_tuple2(env,
                                    enif_make_atom(env, "error"),
                                    enif_make_string(env, "out of memory", ERL_NIF_LATIN1));
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
        free((void *)data);
        free((void *)frames_term);
        free((void *)delays_term);
        free((void *)frames_result);
        free((void *)delays);
        return ret_val;
    } else {
        return enif_make_badarg(env);
    }
}

static ERL_NIF_TERM to_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 6) {
        return error(env, "expecting 6 arguments: filename, extension, data, height, width, and number of channels");
    }
    char filename[MAX_NAME_LENGTH], extension[MAX_EXTNAME_LENGTH];
    ErlNifBinary result;
    int w = 0, h = 0, comp = 0;
    if (!enif_get_string(env, argv[0], filename, sizeof(filename), ERL_NIF_LATIN1)) {
        return error(env, "invalid filename");
    }
    if (!enif_get_atom(env, argv[1], extension, sizeof(extension), ERL_NIF_LATIN1)) {
        return error(env, "invalid extension");
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

    if (strcmp(extension, "png") == 0) {
        int stride_in_bytes = 0;
        int status = stbi_write_png(filename, w, h, comp, result.data, stride_in_bytes);
        if (!status) {
            return error(env, "Unsuccesful attempt to write to png");
        }
    } else if (strcmp(extension, "bmp") == 0) {
        int status = stbi_write_bmp(filename, w, h, comp, result.data);
        if (!status) {
            return error(env, "unsuccesful attempt to write to bmp");
        }
    } else if (strcmp(extension, "tga") == 0) {
        int status = stbi_write_tga(filename, w, h, comp, result.data);
        if (!status) {
            return error(env, "unsuccesful attempt to write to tga");
        }
    } else if (strcmp(extension, "jpg") == 0) {
        int quality = 100;
        int status = stbi_write_jpg(filename, w, h, comp, result.data, quality);
        if (!status) {
            return error(env, "unsuccesful attempt to write to jpg");
        }
    } else {
        return error(env, "wrong extension");
    }

    return enif_make_atom(env, "ok");
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
    {"from_file", 3, from_file, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"from_memory", 3, from_memory, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"gif_from_memory", 1, gif_from_memory, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"to_file", 6, to_file, ERL_NIF_DIRTY_JOB_IO_BOUND}};

ERL_NIF_INIT(Elixir.StbImage.Nif, nif_functions, on_load, on_reload, on_upgrade, NULL);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#endif
