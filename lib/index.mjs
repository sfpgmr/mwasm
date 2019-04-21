

import wabt from 'wabt';
import path from 'path';
import fs from 'fs';
import parser from './mwasm-parser.js';


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
      constructor(parser){
        this.parser = parser;
        this.includeFileTree = {parent:null,childs:{}};
        this.path = path;
        this.require = require;
        this.pathStack = [];
      }

      readSourceFile(srcPath){
        srcPath = path.normalize(srcPath);
        let src = fs.readFileSync(srcPath,'utf-8');
        return src;
      }

      checkIncludeLoop(baseName){
        let current = this.includeFileTree;
        function check(b){
          if(current.parent && current.parent[b]){
            return false;
          } else if(current.parent){
            current = current.parent;
            return check(b);
          }
          return true;
        }
        return check(baseName);
      }


      preprocess(srcPath,srcToken){

        const baseName = path.basename(srcPath);

        if(!this.checkIncludeLoop(baseName)){
          error(`include Loop Detected:${baseName}`,srcToken);
        }

        if(!(baseName in this.includeFileTree.childs)){
          const inode =  {parent:this.includeFileTree,childs:{}};
          inode.parent.childs[baseName] = inode;
          this.includeFileTree = inode;
        } else {
          const inode = this.includeFileTree.childs[baseName];
          this.includeFileTree = inode;
        }

        let srcStr = this.readSourceFile(srcPath);

        let tokens = this.parser.parse(srcStr);

        const preprocessed = [];
        
        for(const token of tokens){
          switch(token.type){
            case 'LineTerminator':
              preprocessed.push('\n');
              break;
            case 'Identifier':
              preprocessed.push(token.name);
              break;
            case 'Separator':
              preprocessed.push(token.kind);
              break;
            case 'StringLiteral':
              preprocessed.push(token.value);
              break;
            case 'Comment':
              preprocessed.push(token.value);
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
              console.log(token.pathExpression);
              let src = this.evalExpression(token.pathExpression);
              this.preprocess(src,token);
              break;
            case 'PropertyGet':
              break;
            default:
          }
        }

        this.includeFileTree = this.includeFileTree.parent;
        return preprocessed.join(' ');
      }


      eval(code){
        let func = new Function('$',code);
        return func.bind(this)(this);
      }

      evalExpression(code){
        return this.eval('return ' + code);
      }
    }
    
    const context = new Context(parser);
    console.log(args);
    context.preprocess(args.input);
    // let tokens = parser.parse(await fs.promises.readFile(args.input,'utf-8'));
    console.log(tokens);
   
    // let preprocessedSource = tokens.join(' ');

    // let wasmModule = wabt_.parseWat(args.input,preprocessedSource);
    // console.log(wasmModule.toText({ foldExprs: false, inlineExport: false }));
    // if(args.output){
    //    await fs.promises.writeFile(args.output,Buffer.from(wasmModule.toBinary({}).buffer));
    // }


  } catch (e) {
    console.error('error:',e.message, e.stack);
    process.exit();
  }
};

