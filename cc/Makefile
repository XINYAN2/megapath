CXXFLAGS = -g -O2 -Wall -std=c++0x -fopenmp -lz

%: %.cpp %.h $(DEPS)
	$(CXX) $< -o $@ $(CXXFLAGS) 