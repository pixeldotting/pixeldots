# pixeldots installer. `make` needs SDL2 (pkg-config sdl2); `make headless` needs only a C++17 compiler.
CXX      ?= g++
CXXFLAGS ?= -O2
CXXFLAGS += -std=c++17 -Wall -Wextra -Isrc
SRC      := src/app.cpp

all: pixeldots-installer

pixeldots-installer: $(SRC) src/main_sdl.cpp $(wildcard src/*.hpp)
	$(CXX) $(CXXFLAGS) $$(pkg-config --cflags sdl2) $(SRC) src/main_sdl.cpp -o $@ $$(pkg-config --libs sdl2)

headless: pixeldots-installer-headless
pixeldots-installer-headless: $(SRC) src/main_headless.cpp $(wildcard src/*.hpp)
	$(CXX) $(CXXFLAGS) $(SRC) src/main_headless.cpp -o $@

clean:
	rm -f pixeldots-installer pixeldots-installer-headless

.PHONY: all headless clean
