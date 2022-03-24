
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

.PHONY: test-all
#test: run
test-all: $(TARGET)
	mwasm ./tests/test/test.mwat -o ./tests/test/test.wasm
	mwasm ./tests/test/test1.mwat -o ./tests/test/test1.wasm
	mwasm ./tests/test/test2.mwat -o ./tests/test/test2.wasm
	mwasm ./tests/test/test3.mwat -o ./tests/test/test3.wasm
	mwasm ./tests/test/test4.mwat -o ./tests/test/test4.wasm
	mwasm ./tests/test/test5.mwat -o ./tests/test/test5.wasm
	mwasm ./tests/test/test6.mwat -o ./tests/test/test6.wasm
	mwasm ./tests/test/test7.mwat -o ./tests/test/test7.wasm
	mwasm ./tests/test/test8.mwat -o ./tests/test/test8.wasm
	mwasm ./tests/test/test9.mwat -o ./tests/test/test9.wasm
	mwasm ./tests/test/test10.mwat -o ./tests/test/test10.wasm
	mwasm ./tests/test/test11.mwat -o ./tests/test/test11.wasm
	mwasm ./tests/test/test12.mwat -o ./tests/test/test12.wasm
	mwasm ./tests/test-map/test-map.mwat -o ./tests/test-map/test-map.wasm
	mwasm ./tests/test-map/test-map2.mwat -o ./tests/test-map/test-map2.wasm
	mwasm ./tests/test-map/test-map3.mwat -o ./tests/test-map/test-map3.wasm
	mwasm ./tests/test-map/test-map4.mwat -o ./tests/test-map/test-map4.wasm
	mwasm ./tests/test-map/test-map5.mwat -o ./tests/test-map/test-map5.wasm
	mwasm ./tests/test/test-js.mwat -o ./tests/test/test-js.wasm
	mwasm ./tests/test-struct/test-struct.mwat -o ./tests/test-struct/test-struct.mwasm
	mwasm ./tests/test-struct/test-struct2.mwat -o ./tests/test-struct/test-struct2.mwasm
	mwasm ./tests/test-struct/test-struct3.mwat -o ./tests/test-struct/test-struct3.mwasm
	mwasm ./tests/test-struct/test-struct4.mwat -o ./tests/test-struct/test-struct4.mwasm
	mwasm ./tests/test-struct/test-struct5.mwat -o ./tests/test-struct/test-struct5.mwasm
	mwasm ./tests/test-struct/test-struct6.mwat -o ./tests/test-struct/test-struct6.mwasm
	mwasm ./tests/test-struct/test-struct7.mwat -o ./tests/test-struct/test-struct7.mwasm
	mwasm ./tests/test-macro/test-macro.mwat -o ./tests/test-macro/test-macro.mwasm
	mwasm ./examples/psg-emulator/em2149.mwat -o ./examples/psg-emulator/em2149.wasm


.PHONY: test 
test: $(TARGET)
	mwasm ./tests/test-struct/test-struct7.mwat -o ./tests/test-struct/test-struct7.mwasm

.PHONY: clean
clean:
	rm $(TARGET) $(PARSERS)

.PHONY: trace 
trace: TRACE = --trace
trace: test


