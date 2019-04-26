
SRC  = ./lib/
OBJS = $(SRC)mwasm-parser.js $(SRC)preprocessor.js $(SRC)index.mjs

./index.js: $(OBJS) ;
	rollup -c

$(SRC)mwasm-parser.js: $(SRC)mwasm-parser.pegjs
	pegjs -o $@ $<

$(SRC)preprocessor.js: $(SRC)preprocessor.pegjs
	pegjs -o .$@ $<

