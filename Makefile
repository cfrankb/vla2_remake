CXX=g++
INC=
LIBS=-lSDL2 -lz
CXXFLAGS=-O3
PARGS=
BPATH=build
BNAME=vlamits2-sdl
TARGET=$(BPATH)/$(BNAME)
DEPS=$(BPATH)/main$(EXT) $(BPATH)/imswrap$(EXT)
EXT=.o

all: $(TARGET)

$(BPATH)/main$(EXT): src/main.cpp
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/imswrap$(EXT): src/imswrap.cpp src/imswrap.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(TARGET): $(DEPS)
	$(CXX) $(CXXFLAGS) $(DEPS) $(LIBS) $(PARGS) -o $@

clean:
	rm -f $(BPATH)/*