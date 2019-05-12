
VPATH = ./lib/:./:./bin

# PARSERS = ./lib/mwasm-parser.js ./lib/preprocess-parser.js
PARSERS = ./lib/preprocess-parser.js
SRC_FILES = ./lib/index.mjs

TARGET = index.js
TRACE = 
PEG = pegjs $(TRACE) -o $@ $<
MWASM = mwasm $@ $<

$(TARGET): $(PARSERS) $(SRC_FILES)
	rollup -c

$(PARSERS): %.js : %.pegjs
	$(PEG)

.PHONY: run
run: $(TARGET)
	mwasm ./examples/psg-emulator/em2149.mwat -o ./examples/psg-emulator/em2149.wasm

.PHONY: test
#test: run
test: $(TARGET)
#	mwasm ./tests/test/test.mwat -o ./tests/test/test.wasm
	mwasm ./tests/test-map/test-map.mwat -o ./tests/test-map/test-map.wasm
	mwasm ./tests/test-struct/test-struct.mwat -o ./tests/test-struct/test-struct.mwasm
	mwasm ./examples/psg-emulator/em2149.mwat -o ./examples/psg-emulator/em2149.wasm

.PHONY: clean
clean:
	rm $(TARGET) $(PARSERS)

.PHONY: trace 
trace: TRACE = --trace
trace: test


