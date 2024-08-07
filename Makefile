CXX=emcc
INC=
LIBS=
CXXFLAGS=-sUSE_SDL=2 -sUSE_ZLIB=1 -O2
PARGS=--preload-file data --emrun -O2 -sWASM=1
BPATH=build
BNAME=vlamits2.html
TARGET=$(BPATH)/$(BNAME)
DEPS=$(BPATH)/script$(EXT) $(BPATH)/runtime$(EXT) $(BPATH)/main$(EXT) $(BPATH)/framemap$(EXT) $(BPATH)/game$(EXT) $(BPATH)/debug$(EXT) $(BPATH)/imswrap$(EXT) $(BPATH)/actor$(EXT) $(BPATH)/scriptarch$(EXT) $(BPATH)/mapentry$(EXT) $(BPATH)/FrameSet$(EXT) $(BPATH)/Frame$(EXT) $(BPATH)/DotArray$(EXT) $(BPATH)/helper$(EXT) $(BPATH)/PngMagic$(EXT) $(BPATH)/FileWrap$(EXT)
EXT=.o

all: $(TARGET)

$(BPATH)/script$(EXT): src/script.cpp src/script.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/runtime$(EXT): src/runtime.cpp src/runtime.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/main$(EXT): src/main.cpp
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/framemap$(EXT): src/framemap.cpp src/framemap.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/game$(EXT): src/game.cpp src/game.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/debug$(EXT): src/debug.cpp src/debug.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/imswrap$(EXT): src/imswrap.cpp src/imswrap.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/actor$(EXT): src/actor.cpp src/actor.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/scriptarch$(EXT): src/scriptarch.cpp src/scriptarch.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/mapentry$(EXT): src/mapentry.cpp src/mapentry.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/FrameSet$(EXT): src/shared/FrameSet.cpp src/shared/FrameSet.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/Frame$(EXT): src/shared/Frame.cpp src/shared/Frame.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/DotArray$(EXT): src/shared/DotArray.cpp src/shared/DotArray.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/helper$(EXT): src/shared/helper.cpp src/shared/helper.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/PngMagic$(EXT): src/shared/PngMagic.cpp src/shared/PngMagic.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(BPATH)/FileWrap$(EXT): src/shared/FileWrap.cpp src/shared/FileWrap.h
	$(CXX) $(CXXFLAGS) -c $< $(INC) -o $@

$(TARGET): $(DEPS)
	$(CXX) $(CXXFLAGS) $(DEPS) $(LIBS) $(PARGS) -o $@

clean:
	rm -rf $(BPATH)/*