-include Makefile.user

DXROOT ?= $(USERPROFILE)/sdks/directx/dx81

RELEASE ?= 1

ifeq (0,$(RELEASE))
 OPTLEVEL=-Og
else
 OPTLEVEL=-O2
endif

CC?=gcc
AR?=ar
CFLAGS=-g $(OPTLEVEL) -Wall
CPPFLAGS=-Iinclude -Isrc

SOURCES=src/drivers.c \
        src/fx_man.c \
        src/cd.c \
        src/multivoc.c \
        src/mix.c \
        src/mixst.c \
        src/pitch.c \
        src/vorbis.c \
        src/music.c \
        src/midi.c \
        src/driver_nosound.c \
        src/asssys.c

include Makefile.shared

ifeq (mingw32,$(findstring mingw32,$(machine)))
 CPPFLAGS+= -I$(DXROOT)/include -Ithird-party/mingw32/include
 SOURCES+= src/driver_directsound.c src/driver_winmm.c

 CPPFLAGS+= -DHAVE_VORBIS
else ifeq ($(PLATFORM),AOS4)
 CPPFLAGS+= -DHAVE_SDL=2 -DHAVE_VORBIS -I/sdk/local/common/include -DB_BIG_ENDIAN -D__POWERPC__
 SOURCES+= src/driver_sdl.c
else
 ifneq (0,$(JFAUDIOLIB_HAVE_SDL))
  CPPFLAGS+= -DHAVE_SDL=2 $(shell $(SDL2CONFIG) --cflags)
  ifeq (1,$(JFAUDIOLIB_USE_SDLMIXER))
   CPPFLAGS+= -DUSE_SDLMIXER
   SOURCES+= src/driver_sdlmixer.c
  else
   SOURCES+= src/driver_sdl.c
  endif
 endif
 ifeq (1,$(JFAUDIOLIB_HAVE_ALSA))
  CPPFLAGS+= -DHAVE_ALSA $(shell $(PKGCONFIG) --cflags alsa)
  SOURCES+= src/driver_alsa.c
 endif
 ifeq (1,$(JFAUDIOLIB_HAVE_FLUIDSYNTH))
  CPPFLAGS+= -DHAVE_FLUIDSYNTH $(shell $(PKGCONFIG) --cflags fluidsynth)
  SOURCES+= src/driver_fluidsynth.c
 endif
 ifeq (1,$(JFAUDIOLIB_HAVE_VORBIS))
  CPPFLAGS+= -DHAVE_VORBIS $(shell $(PKGCONFIG) --cflags vorbisfile)
 endif
endif

OBJECTS=$(SOURCES:%.c=%.o)

$(JFAUDIOLIB): $(OBJECTS)
	$(AR) cr $@ $^

$(OBJECTS): %.o: %.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

test: src/test.o $(JFAUDIOLIB);
	$(CC) $(CPPFLAGS) $(CFLAGS) $^ -o $@ $(JFAUDIOLIB_LDFLAGS) -lm

.PHONY: clean
clean:
	-rm -f $(OBJECTS) $(JFAUDIOLIB)
