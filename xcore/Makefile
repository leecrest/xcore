TOPDIR = .

THIRDPATH = $(TOPDIR)/deps
LUA = $(THIRDPATH)/lua
LUV = $(THIRDPATH)/libuv


CFLAGS := -ggdb -Wall -Wextra -Wl,-E -pipe -fPIC -O3
BASE_INC := -I$(LUV)/include \
			-I$(LUA) \
			-I$(TOPDIR)/luv \
			-I$(TOPDIR)/src

LDFLAGS := $(LUA)/liblua.a $(LUV)/.libs/libuv.a -lpthread -lz

#eachsuffix = $(foreach sub,$2,$(addsuffix $(sub),$1))
#rwildcard = $(wildcard $(call eachsuffix,$1,$2)) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

SRC_INC := $(wildcard luv/*.c src/*.c)
LUA_SRC = $(shell ls $(LUA)/*.c | grep -v lua.c | grep -v luac.c)

INCLUDES = $(BASE_INC) $(SRC_INC) $(LUA_SRC)
OBJS = $(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(SRC)))

CC = gcc
CXX = g++
LD = ld
GMAKE = make

%.o:%.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ -c $<

depend:
	@$(CXX) -MM $(CFLAGS) $(INCLUDES) $(SRC) > .dep

replace:
	$(foreach fo, $(OBJ), $(shell $(SEDARG) 's#$(notdir $(fo))#$(fo)#' .dep))

clean:
	rm -rf $(OBJS) .dep


OUTAPP = xcore

all:$(OUTAPP)
	$(warning 'hello')

$(OUTAPP):$(OBJS)
	$(CXX) $(CFLAGS) $(INCLUDES) -o $@ $+ $(LDFLAGS) -ldl -lrt
	rm -rf $(OBJS)
	rm -rf .dep

