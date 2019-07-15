//
// MWASM
// (C) Satoshi Fujiwara 2019
// ==================
//

import wabt from 'wabt';
import path from 'path';
import fs from 'fs';
//import binaryen from 'binaryen';
//import mwasmParser from './mwasm-parser.js';
import preprocessParder from './preprocess-parser.js'

var isLittleEndian = !!new Uint8Array(new Uint16Array([1]).buffer)[0];

const $attributes = '_attributes_';//Symbol('attributes');
const $offsets = '_offsets_';//Symbol('offsets')
const $startOffset = '_startOffset_';


function getInstance(obj, imports = {}) {
  const bin = new WebAssembly.Module(obj);
  const inst = new WebAssembly.Instance(bin, imports);
  return inst;
}

function error(message, token) {
  if (token) {
    throw new Error(`Error: line:${token.start.line} column:${token.start.column} :${message}:`)
  } else {
    throw new Error(message);
  }
}

// ディープコピーメソッド(clone)
// https://qiita.com/ttatsf/items/68de3795ae3bf35c0228
const mapForMap = f => a =>
  new Map([...a].map(([key, value]) => [key, f(value)]));
const mapForSet = f => a => new Set([...a].map(f));
const entriesMapIntoObj = f => xs =>
  xs.reduce(
    (acc, [key, value]) => ({ ...acc, [key]: f(value) })
    , {}
  );
const mapForObj = f => a =>
  entriesMapIntoObj(f)(Object.entries(a));
const getType = a => Object.prototype.toString.call(a);

const clone = a => {
  const type = getType(a);
  return (type === "[object Array]") ? a.map(clone)
    : (type === "[object Map]") ? mapForMap(clone)(a)
      : (type === "[object Set]") ? mapForSet(clone)(a)
        : (type === "[object Object]") ? mapForObj(clone)(a)
          : (type === "[object Date]") ? new Date(a)
            : a;
}


class LiteralUtil {
  constructor(lib) {
    this.lib = lib;
    this.view = new DataView(lib.memory.buffer);
    this.workBuffer = new ArrayBuffer(8);
    this.workView = new DataView(this.workBuffer);
    this.i32 = {
      decimalIntegerStrToDataStr:this.decimalIntegerStrToi32DataStr.bind(this),
      binaryIntegerStrToDataStr:this.binaryIntegerStrToi32DataStr.bind(this),
      octalIntegerStrToDataStr:this.octalIntegerStrToi32DataStr.bind(this),
      hexIntegerStrToDataStr:this.hexIntegerStrToi32DataStr.bind(this)
    };
    this.i64 = {
      decimalIntegerStrToDataStr:this.decimalIntegerStrToi64DataStr.bind(this),
      binaryIntegerStrToDataStr:this.binaryIntegerStrToi64DataStr.bind(this),
      octalIntegerStrToDataStr:this.octalIntegerStrToi64DataStr.bind(this),
      hexIntegerStrToDataStr:this.hexIntegerStrToi64DataStr.bind(this)
    };
    this.f32 = {
      floatStrToDataStr:this.floatStrTof32DataStr.bind(this)
    };

    this.f64 = {
      floatStrToDataStr:this.floatStrTof64DataStr.bind(this)
    };
  }

  decimalIntegerStrToi32DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.decimalArrayToi32(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  binaryIntegerStrToi32DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.binaryArrayToi32(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  octalIntegerStrToi32DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.octalArrayToi32(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  hexIntegerStrToi32DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.hexArrayToi32(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  decimalIntegerStrToi64DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.decimalArrayToi64(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  binaryIntegerStrToi64DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.binaryArrayToi64(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  octalIntegerStrToi64DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.octalArrayToi64(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  hexIntegerStrToi64DataStr(str, sign) {
    this.strToBuffer(str, this.view);
    this.lib.hexArrayToi64(str.length, str.length * 2, sign == '+' ? 0 : 1);
    return this.byteToString(4, this.view, str.length * 2);
  }

  floatStrTof32DataStr(sign, number, flac, expsign, e) {
    let value = parseFloat((sign ? sign : '') + (number ? number : '') + '.' + (flac ? flac : '') + (e ? 'e' + (expsign ? expsign : '+') + e : ''));
    this.workView.setFloat32(0, value);
    return this.byteToString(4);
  }

  floatStrTof64DataStr(sign, number, flac, expsign, e) {
    let value = parseFloat((sign ? sign : '') + (number ? number : '') + '.' + (flac ? flac : '') + (e ? 'e' + (expsign ? expsign : '+') + e : ''));
    this.workView.setFloat64(0, value);
    return this.byteToString(8);
  }

  byteToString(size, view = this.workView, offset = 0) {
    let result = '';
    for (let i = 0; i < size; ++i) {
      result += '\\' + view.getUint8(offset).toString(16).padStart(2, '0');
      ++offset;
    }
    return result;
  }

  strToBuffer(str, view = this.workView) {
    //console.log(str);
    // 文字列から ArrayBuffer への変換
    for (let i = 0, e = str.length; i < e; ++i) {
      view.setUint16(i * 2, str.charCodeAt(i), true);
    }
  }

}

let literalUtil;

function parseInt64(kind, value, minus = false) {
  let low, high;
  switch (kind) {
    case 'hex':
      {
        const hex = value.substr(2).padStart(16, '0');
        high = parseInt(hex.substr(0, 8), 16);
        low = parseInt(hex.slice(-8), 16);
      }
      break;
    case 'binary':
      {
        const bin = value.substr(2).padStart(64, '0');
        high = parseInt(bin.substr(0, 32), 2);
        low = parseInt(bin.slice(-32), 2);
      }
      break;
    default:
      {
        const hex = decimalToHex(value, minus);
        high = parseInt(hex.substr(0, 8), 16);
        low = parseInt(hex.slice(-8), 16);
      }
  }
  if (minus) {
    low = ((low ^ 0xffffffff) + 1) & 0xffffffff;
    high = ((high ^ 0xffffffff) + ((low == 0) ? 1 : 0));
  }
  return { low: low, high: high };
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
        this.startOffset = 0;
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
            case 'PropertyExpression':
              preprocessed.push(
                `i32.const ${this.parsePropertyExpression(token.expression, baseName, skip)}`
              );
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
                    [$attributes]: {
                      type: token.type,
                      size: 0
                    }
                  };
                this.defineMember(token.defines, context, { type: token.type, structName: token.id });
                //console.info(context);
              }
              break;

            case 'MemoryMap':
              {
                this.context[$attributes] = { type: token.type, size: 0 };
                this.defineMember(token.defines, this.context, { type: token.type, preprocessed: preprocessed });
              }
              break;
            default:
              error(`unknown token type '${token.type}'`, token);
          }
        }
        return preprocessed;
      }


      parsePropertyExpression(expressions, baseName, skip) {
        const parsed = [];
        for (const expression of expressions) {
          switch (expression.type) {
            case 'JSPropertyName':
              let propName = expression.name;
              let self = this;
              let relativeOffsets = [];
              function buildPropName(token) {
                if (token.child) {
                  switch (token.child.type) {
                    case 'IndexExpression':
                      let p = new Number(self.parsePropertyExpression(token.child.expression, baseName, skip));
                      switch (expression.prefix) {
                        case '&':
                          relativeOffsets.push(`$.${propName}[$attributes].size * ${p}`);
                          break;
                        case '#':
                        default:
                          propName += "['" + p + "']";
                      }

                      // 
                      break;
                    case 'JSPropertyName':
                      propName += '.' + token.child.name;
                      return buildPropName(token.child);
                    default:
                      error('unknown token type', token.child);
                      break;
                  }
                } else {
                  return;
                }
              }
              buildPropName(expression);
              switch (expression.prefix) {
                case '&':
                  propName = '$.' + propName + '[$attributes].offset'
                  relativeOffsets.length && (propName += '+' + relativeOffsets.join('+'));
                  break;
                case '#':
                  propName = '$.' + propName + '[$attributes].size';
                  break;
                case '@':
                  propName = '$.' + propName + '[$attributes].log2';
                  break;
                default:
                  propName = '$.' + propName;
              }
              //console.log(propName);
              parsed.push(propName);
              break;
            case 'WhiteSpace':
              !skip && parsed.push(' ');
              break;
            case 'JSNumber':
              parsed.push(expression.value);
              break;
            case 'JSOperator':
              parsed.push(expression.value);
              break;
            case 'Identifier':
              parsed.push(expression.name);
              break;
            default:
              error("illegal Property Expression", expression);
              break;
          }
        }
        let jsSource = parsed.join('');
         //console.info(jsSource);
        let v = this.evalExpression(jsSource);
        // console.info(v);
        return v;
      }

      eval(code, options) {
        let func = new Function('$', '$attributes', 'options', code);
        return func.bind(this)(this.context, $attributes, options);
      }

      evalExpression(code, options) {
        return this.eval('return ' + code, options);
      }

      defineMember(defines, currentContext, opts) {
        let offset = 0;
        const rootContext = this.context;
        const structDefinition = opts.type == 'StructDefinition';
        for (const def of defines) {
          switch (def.type) {
            case "MemoryLabel":
              switch (def.varType.type) {
                case "Struct":

                  if (opts && opts.structName == def.varType.id) {
                    error(`error:struct loop detected.`, def);
                  }

                case "PrimitiveType":

                  if (def.id.id in currentContext) {
                    error(`error:struct member name '${def.id.id}' is already defined.`, def);
                  } else {
                    let c;
                    let num;
                    if (def.id.numExpression) {
                      num = this.evalExpression(def.id.numExpression);
                      if (isNaN(num)) {
                        error(`error:number suffix is illegal.`, def);
                      }
                    } else {
                      num = 1;
                    }
                    if (def.varType.type == "PrimitiveType") {
                      // Native Type
                      const initData = def.initData ? this.makeDataString(def, num) : null;
                      c = currentContext[def.id.id] = {
                        [$attributes]: Object.assign(clone(def.varType), { offset: offset + this.startOffset, initData: initData })
                      }
                      if (!structDefinition && initData) {
                        opts.preprocessed.push(`(data (i32.const ${offset + this.startOffset}) "${initData}")`);
                      }

                    } else {
                      // Struct Type
                      if (!def.varType.id in rootContext) {
                        error(`error:Struct '${def.varType.id}' is not defined.`, def);
                      }
                      let structType = rootContext[def.varType.id];
                      if (structType[$attributes].type != 'StructDefinition') {
                        error(`error:Struct '${def.varType.id}' is not struct type.`, def);
                      }
                      const initData = def.initData ? this.makeDataString(def) : null;
                      c = currentContext[def.id.id] = Object.assign(clone(structType), {
                        [$attributes]: Object.assign(clone(structType[$attributes]), { offset: offset + this.startOffset, initData: initData })
                      });

                      function calcStructMemberOffset(st, o) {
                        for (const m in st) {
                          if (m != $attributes) {
                            let att = st[m][$attributes];
                            switch (att.type) {
                              case "PrimitiveType":
                                // console.log(att,m,att.offset,o);
                                att.offset += o;
                                if(att.initData){
                                  opts.preprocessed.push(`(data (i32.const ${att.offset}) "${att.initData}")`);
                                }
                                break;
                              case "Struct":
                                att.offset += o;
                                // console.log(att,m,att.offset,o);
                                calcStructMemberOffset(st[m], att.offset);
                                break;
                            }
                          }
                        }
                      }
                      calcStructMemberOffset(c, offset + this.startOffset);
                    }

                    c[$attributes].num = num;
                    offset += c[$attributes].size * num ;
                    currentContext[$attributes].size += c[$attributes].size * num;
                    c[$attributes].log2 = Math.log2(c[$attributes].size) | 0;


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
            case "Offset":
//                console.log(def.type,def.offset);
                this.startOffset = this.parseOffset(def.offset);
              break;
            case 'CodeExpression':
              {
                const result = this.this.evalExpression(def.code);
                result && opts.preprocessed.push(result);
              }
              return ;
            case 'CodeWithoutReturnValue':
              this.evalExpression(def.code);
              break;
            case 'Code':
              {
                const result = this.eval(def.code);
                result && opts.preprocessed.push(result);
              }
              break;
            default:
              error(`error: '${def.type}' is unrecogniezed.`);
          }

        }
      }

      parseOffset(token){
        switch(token.type){
          case 'CodeExpression':
              return this.evalExpression(token.code);
          case 'CodeWithoutReturnValue':
            this.evalExpression(token.code);
            return 0;
          case 'Code':
            return this.eval(token.code);
          case 'JSNumber':
            return this.evalExpression(token.value);
        }
        error(`error: '${token.type}' is unrecogniezed.`);
      }

      makeDataString(def, num) {
        const initData = def.initData;
        const varType = def.varType.varType;
        const lib = literalUtil[varType];

        function makeDataString_(data) {
          //console.logconsole.log(data.type);
          switch (data.type) {
            case 'MwasmArray':
              let result = '';
              initData.value.forEach(d=>{
                result += makeDataString_(d);
              });
              return result;
            case 'IntegerLiteral':
              return lib.decimalIntegerStrToDataStr(data.value,data.sign);
            case 'BinaryIntegerLiteral':
              return lib.binaryIntegerStrToDataStr(data.value,data.sign);
            case 'OctalIntegerLiteral':
              return lib.octalIntegerStrToDataStr(data.value,data.sign);
            case 'HexIntegerLiteral':
              return lib.hexIntegerStrToDataStr(data.value,data.sign);
            case 'FloatLiteral':
              return lib.floatStrToDataStr(data.sign,data.number,data.flac,data.expsign,deta.e);
            case 'HexFloatLiteral':
            case 'BinaryFloatLiteral':
              error('not implemented');
              break;
            default:
              error(`illegal data type ${data.type}`,data);
              break;
            }
        }
        return makeDataString_(initData);
      }
    }

    const lib = getInstance(await fs.promises.readFile(__dirname + '/lib/mwasm-lib.wasm')).exports;
    
    literalUtil = new LiteralUtil(lib);

    const mwasmParser = null;
    const context = new Context(preprocessParder, mwasmParser);

    let startInput = path.resolve(args.input);
    let chdir = path.dirname(startInput);
    let backup = path.resolve(process.cwd());
    process.chdir(chdir);

    const preprocessedSourceText = context.preprocess(startInput);

    const contextJson =  JSON.stringify(context.context,
       (k,v)=>{
         if(k === $attributes){
          delete v.start;
          delete v.end;
         } 
         return v;
      }
    , 2);
    await fs.promises.writeFile(path.basename(args.input, '.mwat') + '.context.json', contextJson, 'utf-8');
    await fs.promises.writeFile(path.basename(args.input, '.mwat') + '.wat', preprocessedSourceText, 'utf-8');
    process.chdir(backup);

    let wasmModule = wabt_.parseWat(path.basename(args.input, '.mwat') + '.wat', preprocessedSourceText);
    wasmModule.resolveNames();
    wasmModule.validate();
    //let wasmModule = binaryen.parseText(preprocessedSourceText);
    if (args.output) {
      let bin = wasmModule.toBinary({log:true,write_debug_names:true});
      await fs.promises.writeFile(args.output, Buffer.from(bin.buffer));
      //console.info(bin.log);
    } else {
      console.info(wasmModule.toText({ foldExprs: false, inlineExport: false }));
    }

  } catch (e) {
    console.error(e.message, e.stack);
    process.exit();
  }
};

