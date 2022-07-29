PRIV_DIR = $(MIX_APP_PATH)/priv
STB_IMAGE_NIF_SO = $(PRIV_DIR)/stb_image_nif.so

C_SRC = $(shell pwd)/c_src
LIB_SRC = $(shell pwd)/lib
THIRD_PARTY = $(shell pwd)/3rd_party
STB_INCLUDE_DIR = $(THIRD_PARTY)/stb
CPPFLAGS += -shared -std=c11 -O3 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -fPIC
CPPFLAGS += -I$(ERTS_INCLUDE_DIR) -I$(STB_INCLUDE_DIR)

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	CPPFLAGS += -undefined dynamic_lookup -flat_namespace -undefined suppress
endif

.DEFAULT_GLOBAL := build

build: $(STB_IMAGE_NIF_SO)

$(STB_IMAGE_NIF_SO):
	@ mkdir -p $(PRIV_DIR)
	$(CC) $(CPPFLAGS) $(C_SRC)/stb_image_nif.c -o $(STB_IMAGE_NIF_SO)
