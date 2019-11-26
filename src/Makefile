BISON ?= bison
FLEX ?= flex

CFLAGS += -Wall -Wextra

# _GNU_SOURCE is for asprintf
CFLAGS += -D_GNU_SOURCE

OBJS = nerves_initramfs.o util.o crc32.o uboot_env.o lex.yy.o parser.tab.o script.o linenoise.o

ifeq ($(shell uname),Darwin)
CFLAGS += -Icompat
OBJS += compat/compat.o
else
BISONFLAGS += -Wno-conflicts-sr
endif

init: $(OBJS)
	$(CC) $(CFLAGS)  -o $@ $^

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d $(BISONFLAS) $<

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) $<

clean:
	$(RM) init $(OBJS) parser.tab.c parser.tab.h lex.yy.c

format: script.c
	astyle --style=kr --indent=spaces=4 --align-pointer=name --align-reference=name --convert-tabs --attach-namespaces --max-code-length=100 --max-instatement-indent=120 --pad-header --pad-oper $^

.PHONY: all clean format
