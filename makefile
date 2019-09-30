
VPATH = ./lib/:./:./bin

# PARSERS = ./lib/mwasm-parser.js ./lib/preprocess-parser.js
PARSERS = ./lib/preprocess-parser.js
SRC_FILES = ./lib/index.mjs
MWASM_LIB = ./lib/mwasm-lib.wasm

TARGET = index.js
TRACE = 
PEG = pegjs $(TRACE) -o $@ $<
MWASM = mwasm $@ $<

$(TARGET): $(PARSERS) $(SRC_FILES) $(MWASM_LIB)
	rollup -c

$(PARSERS): %.js : %.pegjs
	$(PEG)

$(MWASM_LIB): %.wasm : %.wat
	wat2wasm $< -o $@

.PHONY: run
run: $(TARGET)
	mwasm ./examples/psg-emulator/em2149.mwat -o ./examples/psg-emulator/em2149.wasm

.PHONY: test
#test: run
test: $(TARGET)
#	mwasm ./tests/test/test.mwat -o ./tests/test/test.wasm
#	mwasm ./tests/test-map/test-map.mwat -o ./tests/test-map/test-map.wasm
#	mwasm ./tests/test/test-js.mwat -o ./tests/test/test-js.wasm
#	mwasm ./tests/test-struct/test-struct.mwat -o ./tests/test-struct/test-struct.mwasm
	mwasm ./tests/test-macro/test-macro.mwat -o ./tests/test-macro/test-macro.mwasm
#	mwasm ./examples/psg-emulator/em2149.mwat -o ./examples/psg-emulator/em2149.wasm

.PHONY: clean
clean:
	rm $(TARGET) $(PARSERS)

.PHONY: trace 
trace: TRACE = --trace
trace: test


