

import wabt from 'wabt';
import path from 'path';
import fs from 'fs';
import parser from './mwasm-parser.js';

export default async () => {

  try {

    const argv = process.argv.slice(2);
    const args = {};

    // パラメータの解析
    while (argv.length > 0) {
      const v = argv.shift();
      switch (v) {
        case '-o':
        case '--output':
          if (argv.length > 0) {
            const p = argv.shift(v);
            try {
              path.parse(p);
            } catch (e) {
              throw new Error('不正なpathを指定しています。');
            }
            args.output = p;
          } else {
            throw new Error('出力pathが指定されていません。');
          }
          break;
        default:
          {
            path.parse(v);
            try {
              path.parse(v);
            } catch (e) {
              throw new Error('不正なpathを指定しています。');
            }
            args.input = v;
          }
      }
    }

    // パラメータのチェック
    if (!args.input) {
      throw new Error('入力pathが指定されていません。');
    }
    // if(!args.output){
    //   throw new Error('出力pathが指定されていません。');
    // }


    const wabt_ = wabt();

    let src = await fs.promises.readFile(args.input, 'utf-8');
    let tokens = parser.parse(src);
    console.log(tokens);

    // let wasmModule = wabt_.parseWat(args.input,await fs.promises.readFile(args.input,'utf-8'));
    // if(args.output){
    //   await fs.promises.writeFile(args.output,Buffer.from(wasmModule.toBinary({}).buffer));
    // } else {
    //   console.log(wasmModule.toText());
    // }

  } catch (e) {
    console.error('error:', e.stack);
    process.exit();
  }
};

