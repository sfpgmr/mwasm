
SRC  = ./lib/
OBJS = $(SRC)mwasm-parser.js $(SRC)preprocessor.js $(SRC)index.mjs
TRACE = 
PEG := pegjs $(TRACE) -o $@ $< 

index.js: $(OBJS) ;
	rollup -c

$(SRC)mwasm-parser.js: $(SRC)mwasm-parser.pegjs
	$(PEG)

$(SRC)preprocessor.js: $(SRC)preprocessor.pegjs
	$(PEG)

.PHONY: test
test: index.js
	bin/mwasm

.PHONY: t
t:

	

.PHONY: trace
trace:   

