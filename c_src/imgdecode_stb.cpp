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

static ERL_NIF_TERM pack_data(ErlNifEnv *env, unsigned char * data, int x, int y, int n, int bytes_per_pixel, const char * type) {
    if (data != nullptr) {
        ErlNifBinary result;
        if (enif_alloc_binary(x * y * n * bytes_per_pixel, &result)) {
            memcpy(result.data, data, result.size);

            return enif_make_tuple4(env,
                                     enif_make_atom(env, "ok"),
                                     enif_make_binary(env, &result),
                                     enif_make_tuple3(env,
                                                       enif_make_int(env, y),
                                                       enif_make_int(env, x),
                                                       enif_make_int(env, n)
                                     ),
                                     enif_make_atom(env, type)
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

        int bytes_per_pixel;
        unsigned char* (*load_func)(const char *, int *, int *, int *, int) = nullptr;
        if (type == "u8") {
            load_func = (decltype(load_func))stbi_load;
            bytes_per_pixel = sizeof(unsigned char);
        }
        else if (type == "u16") {
            load_func = (decltype(load_func))stbi_load_16;
            bytes_per_pixel = sizeof(unsigned short);
        }
        else if (type == "f32") {
            load_func = (decltype(load_func))stbi_loadf;
            bytes_per_pixel = sizeof(float);
        }
        else return enif_make_badarg(env);

        int x, y, n;
        unsigned char *data = load_func(filename.c_str(), &x, &y, &n, desired_channels);
        ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_pixel, type.c_str());
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

        int bytes_per_pixel;
        unsigned char* (*load_func)(void *, int, int *, int *, int *, int) = nullptr;
        if (type == "u8") {
            load_func = (decltype(load_func))stbi_load_from_memory;
            bytes_per_pixel = sizeof(unsigned char);
        }
        else if (type == "u16") {
            load_func = (decltype(load_func))stbi_load_16_from_memory;
            bytes_per_pixel = sizeof(unsigned short);
        }
        else if (type == "f32") {
            load_func = (decltype(load_func))stbi_loadf_from_memory;
            bytes_per_pixel = sizeof(float);
        }
        else return enif_make_badarg(env);

        int x, y, n;
        unsigned char *data = load_func(result.data, (int)result.size, &x, &y, &n, desired_channels);
        ERL_NIF_TERM ret = pack_data(env, data, x, y, n, bytes_per_pixel, type.c_str());
        free((void *)data);
        return ret;
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
};

ERL_NIF_INIT(Elixir.ImgDecode.Nif, nif_functions, on_load, on_reload, on_upgrade, NULL);

#if defined(__GNUC__)
#pragma GCC visibility push(default)
#endif
