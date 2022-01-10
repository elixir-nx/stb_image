PRIV_DIR = $(MIX_APP_PATH)/priv
IMG_DECODE_STB_SO = $(PRIV_DIR)/img_decode_stb.so

C_SRC = $(shell pwd)/c_src
LIB_SRC = $(shell pwd)/lib
THIRD_PARTY = $(shell pwd)/3rd_party
STB_INCLUDE_DIR = $(THIRD_PARTY)/stb
CPPFLAGS += -shared -std=c++14 -O3 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -fPIC
CPPFLAGS += -I$(ERTS_INCLUDE_DIR) -I$(STB_INCLUDE_DIR)

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	CPPFLAGS += -shared -undefined dynamic_lookup -flat_namespace -undefined suppress
endif

.DEFAULT_GLOBAL := build

build: $(IMG_DECODE_STB_SO)

$(IMG_DECODE_STB_SO):
	@ git submodule update --init --recursive
	@ mkdir -p $(PRIV_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(C_SRC)/imgdecode_stb.cpp -o $(IMG_DECODE_STB_SO)
