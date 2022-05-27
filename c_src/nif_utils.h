#pragma once

#include "erl_nif.h"

static ERL_NIF_TERM error(ErlNifEnv *env, const char *msg)
{
  ERL_NIF_TERM atom = enif_make_atom(env, "error");
  ERL_NIF_TERM msg_term = enif_make_string(env, msg, ERL_NIF_LATIN1);
  return enif_make_tuple2(env, atom, msg_term);
}
