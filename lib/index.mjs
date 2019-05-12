
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

const $attributes = '_attributes_';//Symbol('attributes');
const $offsets = '_offsets_';//Symbol('offsets')

function error(message, token) {
  if (token) {
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
      constructor(preprocessParser, mwasmParser) {
        this.preprocessParser = preprocessParser;
        this.mwasmParser = mwasmParser;
        this.includeFileTree = { parent: null, childs: {} };
        this.path = path;
        this.require = require;
        this.pathStack = [];
        this.context = {};
      }

      readSourceFile(srcPath) {
        srcPath = path.normalize(srcPath);
        let src = fs.readFileSync(srcPath, 'utf-8');
        return src;
      }

      checkIncludeLoop(baseName) {
        let current = this.includeFileTree;
        function check(b) {
          if (current.parent && current.parent.childs[b]) {
            return false;
          } else if (current.parent) {
            current = current.parent;
            return check(b);
          }
          return true;
        }
        return check(baseName);
      }


      preprocess(srcPath, srcToken, skip = true) {

        const baseName = path.basename(srcPath);

        if (!this.checkIncludeLoop(baseName, srcToken)) {
          error(`include Loop Detected:${srcToken.baseName}:'${baseName}'`, srcToken);
        }

        if (!(baseName in this.includeFileTree.childs)) {
          const inode = { name: baseName, parent: this.includeFileTree, childs: {} };
          inode.parent.childs[baseName] = inode;
          this.includeFileTree = inode;
        } else {
          const inode = this.includeFileTree.childs[baseName];
          this.includeFileTree = inode;
        }

        let srcStr = this.readSourceFile(srcPath);

        let tokens = this.preprocessParser.parse(srcStr);

        fs.writeFileSync(`./${baseName}.json`, JSON.stringify(tokens, null, 2), 'utf-8');

        const preprocessed = this.preprocessTokens(tokens, baseName, skip);

        this.includeFileTree = this.includeFileTree.parent;
        return preprocessed.join('');
      }

      preprocessTokens(tokens, baseName, skip) {
        const preprocessed = [];
        const rootContext = this.context;
        for (const token of tokens) {
          switch (token.type) {
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
              if (this.evalExpression(token.expression)) {
                if (token.if) {
                  preprocessed.push(...this.preprocessTokens(token.if, baseName, skip));
                }
              } else {
                if (token.else) {
                  processed.push(...this.preprocessTokens(token.else, baseName, skip));
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
              const includedSource = this.preprocess(src, token, skip);
              preprocessed.push(...includedSource);
              break;
            case 'ConstExpression':
              preprocessed.push(...this.parseConstExpression(token,skip));
              break;
            case 'WhiteSpace':
              preprocessed.push(skip ? ' ' : token.value);
              break;
            case 'StructDefinition':
              if (token.id in this.context) {
                error(`error:Struct name '${token.id}' is already defined.`, token);
              } else {
                // 
                let context = this.context[token.id] =
                  {
                    [$attributes]:{
                      type: token.type,
                      size: 0
                    }
                  };
                this.defineMember(token.defines,context,{structName:token.id});
                //console.info(context);
              }
              break;
            case 'MemoryMap':
              {
                this.context[$attributes] = {type:token.type,size:0};
                this.defineMember(token.defines,this.context);
              }
              break;
            default:
              error(`unknown token type '${token.type}'`, token);
          }
        }
        return preprocessed;
      }


      parseConstExpression(t,skip){
        const preprocessed = [];
        const expressions = t.expression.expression;
        for(const expression of expressions){
          switch(expression.type){
            case 'Property':
              if(expression.child && expression.child.type == 'JSPropertyName'){
                const jsprop = expression.child;
                const parsed = '';
                const propName = jsprop.name;
                if(jsprop.child){

                } else {
                  switch(jsprop.prefix){
                    case '&':
                      parsed = '$[$attributes]["' + propName + '"].offset';
                      break;
                    case '#':
                      parsed = '$[$attributes]["' + propName + '"].size';
                      break;
                    default:
                      parsed = '$["' + jsprop + '"]'; 
                  }
                }
              }
              preprocessed.push(parsed);
              break;
            case 'WhiteSpace':
              !skip && preprocessed.push(' ');
              break;
            case 'JSNumber':
              preprocessed.push(expression.value);
            case 'JSOperator':
              preprocessed.push(expression.value);
              break;
            case 'Identifier':
              preprocessed.push(expression.name);
              break;
            default:
              error("illegal const expression",expression);
              break;
          }
        }
        return preprocessed;
      }

      eval(code, options) {
        let func = new Function('$', 'options', code);
        return func.bind(this)(this.context, options);
      }

      evalExpression(code, options) {
        return this.eval('return ' + code, options);
      }

      defineMember(defines, currentContext,opts) {
        let offset = 0;
        const rootContext = this.context;
        for (const def of defines) {
          switch (def.type) {
            case "MemoryLabel":
              switch (def.varType.type) {
                case "Struct":

                  if(opts && opts.structName == def.varType.id){
                    error(`error:struct loop detected.`,def);
                  }

                case "PrimitiveType":

                  if (def.id.id in currentContext) {
                    error(`error:struct member name '${def.id.id}' is already defined.`, def);
                  } else {
                    let c;
                    if (def.varType.type == "PrimitiveType") {
                      c = currentContext[def.id.id] = {
                        [$attributes]:Object.assign({}, def.varType, { offset: offset})
                      }
                    } else {
                      if (!def.varType.id in rootContext) {
                        error(`error:Struct '${def.varType.id}' is not defined.`, def);
                      }
                      let structType = rootContext[def.varType.id];
                      if (structType[$attributes].type != 'StructDefinition') {
                        error(`error:Struct '${def.varType.id}' is not struct type.`, def);
                      }
                      c = currentContext[def.id.id] = Object.assign({},structType,{
                        [$attributes]:Object.assign({},structType[$attributes],{offset:offset})
                      });
                    }
                    let num;
                    if (def.id.numExpression) {
                      num = this.evalExpression(def.id.numExpression);
                      if (isNaN(num)) {
                        error(`error:number suffix is illegal.`, def);
                      }
                    } else {
                      num = 1;
                    }
                    c[$attributes].num = num;
                    offset += c[$attributes].size * num;
                    currentContext[$attributes].size += c[$attributes].size * num;
                    // 初期値の設定
                  }
                  //console.log(currentContext);
                  break;
              }
              break;
            case "WhiteSpace":
            case "Comment":
              // skip
              break;
            default:
              error(`error: '${def.type}' is unrecogniezed.`);
          }

        }
      }
    }

    const mwasmParser = null;
    const context = new Context(preprocessParder, mwasmParser);

    let startInput = path.resolve(args.input);
    let chdir = path.dirname(startInput);
    let backup = path.resolve(process.cwd());
    process.chdir(chdir);

    const preprocessedSourceText = context.preprocess(startInput);
    await fs.promises.writeFile(path.basename(args.input, '.mwat') + '.context.json',JSON.stringify(context.context,null,2),'utf-8');
    await fs.promises.writeFile(path.basename(args.input, '.mwat') + '.wat', preprocessedSourceText, 'utf-8');
    process.chdir(backup);

    let wasmModule = wabt_.parseWat(args.input, preprocessedSourceText);
    if (args.output) {
      await fs.promises.writeFile(args.output, Buffer.from(wasmModule.toBinary({}).buffer));
    } else {
      console.info(wasmModule.toText({ foldExprs: false, inlineExport: false }));
    }

  } catch (e) {
    console.error(e.message, e.stack);
    process.exit();
  }
};

