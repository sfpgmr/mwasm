
//
// MWASM
// (C) Satoshi Fujiwara 2019
// ==================
//

import wabt from 'wabt';
import path from 'path';
import fs from 'fs';
//import mwasmParser from './mwasm-parser.js';
import preprocessParder from './preprocess-parser.js'

var isLittleEndian = !!new Uint8Array(new Uint16Array([1]).buffer)[0];

function error(message,token){
  if(token){
    throw new Error(`Error: line:${token.start.line} column:${token.start.column} :${message}:`)
  } else {
    throw new Error(message);    
  }
}

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

    class Context {
      constructor(preprocessParser,mwasmParser){
        this.preprocessParser = preprocessParser;
        this.mwasmParser = mwasmParser;
        this.includeFileTree = {parent:null,childs:{}};
        this.path = path;
        this.require = require;
        this.pathStack = [];
        this.context = {};
      }

      readSourceFile(srcPath){
        srcPath = path.normalize(srcPath);
        let src = fs.readFileSync(srcPath,'utf-8');
        return src;
      }

      checkIncludeLoop(baseName){
        let current = this.includeFileTree;
        function check(b){
          if(current.parent && current.parent.childs[b]){
            return false;
          } else if(current.parent){
            current = current.parent;
            return check(b);
          }
          return true;
        }
        return check(baseName);
      }


      preprocess(srcPath,srcToken,skip = true){

        const baseName = path.basename(srcPath);

        if(!this.checkIncludeLoop(baseName,srcToken)){
          error(`include Loop Detected:${srcToken.baseName}:'${baseName}'`,srcToken);
        }

        if(!(baseName in this.includeFileTree.childs)){
          const inode =  {name:baseName,parent:this.includeFileTree,childs:{}};
          inode.parent.childs[baseName] = inode;
          this.includeFileTree = inode;
        } else {
          const inode = this.includeFileTree.childs[baseName];
          this.includeFileTree = inode;
        }

        let srcStr = this.readSourceFile(srcPath);

        let tokens = this.preprocessParser.parse(srcStr);

        fs.writeFileSync(`./${baseName}.json`,JSON.stringify(tokens,null,2),'utf-8');

        const preprocessed = this.preprocessTokens(tokens,baseName,skip);

        this.includeFileTree = this.includeFileTree.parent;
        return preprocessed.join('');
      }

      preprocessTokens(tokens,baseName,skip){
        const preprocessed = [];
        for(const token of tokens){
          switch(token.type){
            case 'LineTerminator':
              !skip && preprocessed.push(token.value);
              break;
            case 'Identifier':
              preprocessed.push(token.name);
              break;
            case 'Parenthesis':
              preprocessed.push(token.kind);
              break;
            case 'StringLiteral':
              preprocessed.push(token.value);
              break;
            case 'Comment':
              !skip && preprocessed.push(token.value);
              break;
            case 'Condition':
              if(this.evalExpression(token.expression)){
                if(token.if){
                  preprocessed.push(...this.preprocessTokens(token.if,baseName,skip));
                } 
              } else {
                if(token.else){
                  preprocessed.push(...this.preprocessTokens(token.else,baseName,skip));
                }
              }
              break;
            case 'CodeExpression':
              preprocessed.push(this.evalExpression(token.code));
              break;
            case 'CodeWithoutReturnValue':
              this.eval(token.code);
              break;
            case 'Code':
              preprocessed.push(this.eval(token.code));
              break;
            case 'SourceInclude':
              let src = this.evalExpression(token.pathExpression);
              token.baseName = baseName;
              const includedSource = this.preprocess(src,token,skip);
              preprocessed.push(...includedSource);
              break;
            case 'PropertyGet':
              if(this.context[token.propertyName]){
                preprocessed.push(this.context[token.propertyName] + '');
              } else {
                error(`error:context property name '${token.propertyName}' is not found.`,token);
              }
              break;
            case 'WhiteSpace':
                preprocessed.push(skip ? ' ' : token.value);
              break;
            default:
              error(`unknown token type '${token.type}'`,token);
          }
        }
        return preprocessed;
      }

      parseMwat(srcText){

      }


      eval(code,options){
        let func = new Function('$','options',code);
        return func.bind(this)(this.context,options);
      }

      evalExpression(code,options){
        return this.eval('return ' + code,options);
      }

      makeMemoryMap(token){
        let initDataSource = '';
        const defines = token.defines;
        const memoryMap = this.memoryMap = {};
        let offset = 0;
        
        let buffer = [];


        for(const define of defines){
          if(define.id in memoryMap){
            error(`${define.id} is already deined.`,define);
          }
          memoryMap[define.id] = offset;
          const num = define.numExpression ? this.evalExpression(define.numExpression) : 1;
          const size = define.varType.size;
          const varSize = num * size;

          if(define.initExpression){
            const buffer = new ArrayBuffer(varSize);
            const dview = new DataView(buffer);
            let bufferOffset = 0;
            let initData = this.evalExpression(define.initExpression);
            if(define.varType.integer){
              if(define.varType.signed)
                dview.setInt
              } else {
              }
              dview.setUint8();
            }
            if(initData instanceof Uint8Array ){
              if(initData.byteLength > varSize){
                error(`size of init value is too long.${define}`,defines);
              }
              let datastring = '';
              initData.forEach(v=>{datastring += '\\' + ('0' + v.toString(16)).slice(-2)});
              initDataSource += `(data (i32.const ${offset}) "${datastring}")\n`;
            } else if(initData instanceof Int32Array ){

            }
          }
          offset += num * size;
        }
    }
    
    const mwasmParser = null;
    const context = new Context(preprocessParder,mwasmParser);

    let startInput = path.resolve(args.input);
    let chdir = path.dirname(startInput);
    let backup = path.resolve(process.cwd());
    process.chdir(chdir);

    const preprocessedSourceText = context.preprocess(startInput);
    await fs.promises.writeFile(path.basename(args.input,'.mwat') + '.wat',preprocessedSourceText,'utf-8');
    process.chdir(backup);

    let wasmModule = wabt_.parseWat(args.input,preprocessedSourceText);
    if(args.output){
       await fs.promises.writeFile(args.output,Buffer.from(wasmModule.toBinary({}).buffer));
    } else {
      console.info(wasmModule.toText({ foldExprs: false, inlineExport: false }));
    }

  } catch (e) {
    console.error(e.message,e.stack);
    process.exit();
  } 
};

