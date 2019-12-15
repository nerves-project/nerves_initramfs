
LDFLAGS += -fPIC -shared -pedantic -ldl
CFLAGS ?= -fPIC -O2 -Wall -Wextra -Wno-unused-parameter

TARGET=init_fixture.so

ifeq ($(shell uname),Darwin)
CFLAGS += -I../../src/compat
OBJS += ../../src/compat/compat.o
endif

SRC=$(wildcard *.c)
OBJ=$(SRC:.c=.o)

all: $(TARGET)

$(OBJ): $(wildcard *.h)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(TARGET): $(OBJ)
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	$(RM) $(TARGET) $(OBJ)

.PHONY: all clean
