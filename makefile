
VPATH = ./lib/:./:./bin
PARSERS = ./lib/mwasm-parser.js ./lib/preprocess-parser.js
SRC_FILES = index.mjs
TARGET = index.js
TRACE = 
PEG = pegjs $(TRACE) -o $@ $<

$(TARGET): $(PARSERS) $(SRC_FILES)
	rollup -c

$(PARSERS): %.js : %.pegjs
	$(PEG)

.PHONY: run
run: $(TARGET)
	mwasm ./examples/psg-emulator/em2149.mwat -o ./examples/psg-emulator/em2149.wasm

.PHONY: test
test:run

.PHONY: clean
clean:
	rm $(TARGET) $(PARSERS)

.PHONY: trace 
trace: TRACE = --trace
trace: test


