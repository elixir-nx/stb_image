#include <erl_nif.h>
#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>
#include <string>
#include "nif_utils.hpp"

#ifdef __GNUC__
#  pragma GCC diagnostic ignored "-Wunused-parameter"
#  pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#  pragma GCC diagnostic ignored "-Wunused-variable"
#  pragma GCC diagnostic ignored "-Wunused-function"
#endif

static ERL_NIF_TERM pack_data(ErlNifEnv *env, unsigned char * data, int x, int y, int n, int bytes_per_channel, const char * type) {
    if (data != nullptr) {
        ErlNifBinary result;
        if (enif_alloc_binary(x * y * n * bytes_per_channel, &result)) {
            memcpy(result.data, data, result.size);
            const char * channel_types[] = {"l", "la", "rgb", "rgba"};
            const char * channels = "unknown";
            if (n >= 1 && n <= 4) {
                channels = channel_types[n - 1];
            }
            return enif_make_tuple5(env,
                                     enif_make_atom(env, "ok"),
                                     enif_make_binary(env, &result),
                                     enif_make_tuple3(env,
                                                       enif_make_int(env, y),
                                                       enif_make_int(env, x),
                                                       enif_make_int(env, n)
                                     ),
                                     enif_make_atom(env, type),
                                     enif_make_atom(env, channels)
            );
        } else {
            return enif_make_tuple2(env,
                                     enif_make_atom(env, "error"),
                                     enif_make_string(env, "out of memory", ERL_NIF_LATIN1)
            );
        }
    } else {
        return enif_make_tuple2(env,
                                 enif_make_atom(env, "error"),
                                 enif_make_string(env, "cannot decode image", ERL_NIF_LATIN1)
        );
    }
}

static ERL_NIF_TERM from_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 3) {
        return erlang::nif::error(env, "expecting 3 arguments: filename, desired_channels, type");
    }
    std::string filename;
    int desired_channels = 0;
    std::string type;
    if (erlang::nif::get(env, argv[0], filename) &&
        erlang::nif::get(env, argv[1], &desired_channels) &&
        erlang::nif::get_atom(env, argv[2], type)) {

        int bytes_per_channel;
        unsigned char* (*load_func)(const char *, int *, int *, int *, int) = nullptr;
        if (type == "u8") {
            load_func = (decltype(load_func))stbi_load;
            bytes_per_channel = sizeof(unsigned char);
        }
        else if (type == "u16") {
            load_func = (decltype(load_func))stbi_load_16;
            bytes_per_channel = sizeof(unsigned short);
        }
        else if (type == "f32") {
            load_func = (decltype(load_func))stbi_loadf;
            bytes_per_channel = sizeof(float);
        }
        else return enif_make_badarg(env);

        int x, y, n;
        unsigned char *data = load_func(filename.c_str(), &x, &y, &n, desired_channels);
        ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_channel, type.c_str());
        free((void *)data);
        return ret;
    } else {
        return enif_make_badarg(env);
    }
}

static ERL_NIF_TERM from_memory(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 3) {
        return erlang::nif::error(env, "expecting 3 arguments: buffer, desired_channels, type");
    }
    ErlNifBinary result;
    int desired_channels = 0;
    std::string type;
    if (enif_inspect_binary(env, argv[0], &result) &&
        erlang::nif::get(env, argv[1], &desired_channels) &&
        erlang::nif::get_atom(env, argv[2], type)) {

        int bytes_per_channel;
        unsigned char* (*load_func)(void *, int, int *, int *, int *, int) = nullptr;
        if (type == "u8") {
            load_func = (decltype(load_func))stbi_load_from_memory;
            bytes_per_channel = sizeof(unsigned char);
        }
        else if (type == "u16") {
            load_func = (decltype(load_func))stbi_load_16_from_memory;
            bytes_per_channel = sizeof(unsigned short);
        }
        else if (type == "f32") {
            load_func = (decltype(load_func))stbi_loadf_from_memory;
            bytes_per_channel = sizeof(float);
        }
        else return enif_make_badarg(env);

        int x, y, n;
        unsigned char *data = load_func(result.data, (int)result.size, &x, &y, &n, desired_channels);
        ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_channel, type.c_str());
        free((void *)data);
        return ret;
    } else {
        return enif_make_badarg(env);
    }
}

static ERL_NIF_TERM gif_from_memory(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 1) {
        return erlang::nif::error(env, "expecting 1 argument: buffer");
    }
    ErlNifBinary result;
    if (enif_inspect_binary(env, argv[0], &result)) {
        int x, y, z, comp;
        int * delays = nullptr;
        unsigned char * data = nullptr;
        // the parameter req_comp (the last one) seems to be not in use, see stb_image.h:6706
        data = stbi_load_gif_from_memory(result.data, (int)result.size, &delays, &x, &y, &z, &comp, 0);
        if (!data) {
            return enif_make_tuple2(env,
                                    enif_make_atom(env, "error"),
                                    enif_make_string(env, "cannot decode the given GIF file", ERL_NIF_LATIN1)
            );
        }

        ERL_NIF_TERM * delays_term = (ERL_NIF_TERM *)malloc(sizeof(ERL_NIF_TERM) * z);
        ERL_NIF_TERM * frames_term = (ERL_NIF_TERM *)malloc(sizeof(ERL_NIF_TERM) * z);
        ErlNifBinary * frames_result = (ErlNifBinary *)malloc(sizeof(ErlNifBinary) * z);;
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
                                    enif_make_string(env, "out of memory", ERL_NIF_LATIN1)
            );
        }

        ERL_NIF_TERM frames_ret = enif_make_list_from_array(env, frames_term, z);
        ERL_NIF_TERM delays_ret = enif_make_list_from_array(env, delays_term, z);
        ERL_NIF_TERM ret_val = enif_make_tuple4(env,
                                               enif_make_atom(env, "ok"),
                                               frames_ret,
                                               enif_make_tuple3(env,
                                                               enif_make_int(env, y),
                                                               enif_make_int(env, x),
                                                               enif_make_int(env, 3)
                                               ),
                                               delays_ret
                                               );
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

static int on_load(ErlNifEnv* env, void**, ERL_NIF_TERM)
{
    return 0;
}

static int on_reload(ErlNifEnv*, void**, ERL_NIF_TERM)
{
    return 0;
}

static int on_upgrade(ErlNifEnv*, void**, void**, ERL_NIF_TERM)
{
    return 0;
}

static ErlNifFunc nif_functions[] = {
    {"from_file", 3, from_file, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"from_memory", 3, from_memory, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"gif_from_memory", 1, gif_from_memory, ERL_NIF_DIRTY_JOB_CPU_BOUND},
};

ERL_NIF_INIT(Elixir.StbImage.Nif, nif_functions, on_load, on_reload, on_upgrade, NULL);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#endif

