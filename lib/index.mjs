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

// ディープコピーメソッド(clone)
// https://qiita.com/ttatsf/items/68de3795ae3bf35c0228
const mapForMap = f => a => 
  new Map( [...a].map( ([key, value]) =>[key, f(value)] ) );  
const mapForSet = f => a => new Set( [...a].map( f ) );
const entriesMapIntoObj = f => xs => 
  xs.reduce(
    (acc, [key, value]) => ({ ...acc, [key]:f(value) })
    , {} 
  );
const mapForObj = f => a =>
  entriesMapIntoObj( f )( Object.entries( a ) );
const getType = a => Object.prototype.toString.call(a);

const clone = a => {
  const type = getType( a );
  return (type === "[object Array]")?  a.map( clone )
        :(type === "[object Map]")?    mapForMap( clone )( a )
        :(type === "[object Set]")?    mapForSet( clone )( a )
        :(type === "[object Object]")? mapForObj( clone )( a )
        :(type === "[object Date]")?   new Date( a )
        : a;
}

const dataToStrings = new Map(
  [
    ['i32',i32ToStr],
    ['i64',i64ToStr],
    ['u32',u32ToStr],
    ['u64',u64ToStr],
    ['f32',f32ToStr],
    ['f64',f64ToStr]
  ]
);



const workBuffer = new ArrayBuffer(8);
const workView = new DataView(workBuffer);

function i32ToStr(v){
  workView.setInt32(0,v,true);
  return byteToString(4);
}

function i64ToStr(l,h){
  workView.setUint32(0,l,true);
  workView.setUint32(4,h,true);
  return byteToString(8);
}

function u32ToStr(v){
  workView.setUint32(0,v,true);
  return byteToString(4);
}

function u64ToStr(l,h){
  workView.setUint32(0,l,true);
  workView.setUint32(4,h,true);
  return byteToString(8);
}

function f32ToStr(v){
  workView.setFloat32(0,v,true);
  return byteToString(4);
}

function f64ToStr(v){
  workView.setFloat64(0,v,true);
  return byteToString(8);
}

function byteToString(size){
  let result = '';
  for(let i = 0;i < size;++i){
    result += `\\` + workView.getUint8(i).toString(16).padStart(2,'0');
  }
  return result;
}

 // 整数は文字列の形で指定
  //let numString = '-9223372036854775807';
  //let numString = '9223372036854775809';
  function decimalToHex(numString) {
    let numArray = [];
    let minus = false;
    // 数値文字列を分割して配列に保存する
    {
      let i = 0;
      for (const c of numString) {
        if (c == '-') {
          if (i == 0) {
            minus = true;
          } else {
            throw new Error(`不正な文字:${c}`);
          }
        } else {
          if (isNaN(c)) {
            throw new Error(`不正な文字:${c}`);
          }
          numArray.push(parseInt(c, 10));
        }
        ++i;
      }
    }

    // 変換結果を収める
    let hex = [];
    let b = 0;
    let ans = [];
    let remind = 0;

    while (numArray.length > 0 || b > 15) {
      b = 0;
      ans = [];
      remind = 0;
      numArray.forEach(num => {
        b = b * 10 + num;
        if (b > 15) {
          remind = b & 0b1111;
          ans.push(b >> 4);
          b = remind;
        } else {
          ans.push(0 | 0);
          remind = b;
        }
      })

      // 頭の0をとる
      let i = 0;
      while (ans[i] == 0) {
        ++i;
      }
      numArray = ans.slice(i);
      hex.unshift(remind);
    }

    if (hex.length > 16) {
      throw new Error('64bit整数の範囲を超えています。');
    }

    // 桁揃え（16桁に）
    if (hex.length < 16) {
      let l = 16 - hex.length;
      while (l > 0) {
        hex.unshift(0);
        --l;
      }
    }

    // マイナス値の処理
    if (minus) {
      hex = hex.map(d => d ^ 0xf);
      hex[15] += 1;
      if (hex[15] > 15) {
        hex[15] = 0;
        for (let i = 14; i >= 0; --i) {
          hex[i] += 1;
          if (hex[i] < 16) {
            break;
          } else {
            hex[i] = 0;
          }
        }
      }
      hex[0] |= 0b1000;//sign bitを立てる 
    }
    return hex.map(d => d.toString(16)).join('').padStart(16, '0');
  }

  function parseInt64(kind,value, minus = false) {
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
    return {low:low,high:high};
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
            case 'PropertyExpression':
              preprocessed.push(
                this.parsePropertyExpression(token.expression, baseName, skip)
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
                this.defineMember(token.defines, context, { type:token.type,structName: token.id});
                //console.info(context);
              }
              break;

            case 'MemoryMap':
              {
                this.context[$attributes] = { type: token.type, size: 0 };
                this.defineMember(token.defines, this.context,{type:token.type,preprocessed:preprocessed});
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
                default:
                  propName = '$.' + propName;
              }
              console.log(propName);
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
        console.info(jsSource);
        let v = this.evalExpression(jsSource);
        console.info(v);
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
                    if (def.varType.type == "PrimitiveType") {
                      // Native Type
                      const initData = def.initData ? this.makeDataString(def) : null;
                      c = currentContext[def.id.id] = {
                        [$attributes]: Object.assign(clone(def.varType), { offset: offset,initData:initData})
                      }
                      
                      if(!structDefinition && initData){
                        opts.preprocessed(`(data (i32 const ${offset}) '${initData}')`)
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
                        [$attributes]: Object.assign(clone(structType[$attributes]), { offset: offset,initData:initData })
                      });

                      if(!structDefinition && initData){

                      }

                      function calcStructMemberOffset(st,o){
                        for(const m in st){
                          if(m != $attributes){
                            let att = st[m][$attributes];
                            switch(att.type){
                              case "PrimitiveType":
                                console.log(att,m,att.offset,o);
                                att.offset += o;
                                break;
                              case "Struct":
                                att.offset += o;
                                console.log(att,m,att.offset,o);
                                calcStructMemberOffset(st[m],att.offset);
                                break;
                            }
                          }
                        }
                      }
                      calcStructMemberOffset(c,offset);
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
      
      makeDataString(def){
        let ArrayType;
        if(def.varType.type == 'PrimitiveType'){
          switch(def.varType.varType){
            case 'i32':
            case 'i32':
            case 'i32':
            case 'i32':
            case 'i32':
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
    await fs.promises.writeFile(path.basename(args.input, '.mwat') + '.context.json', JSON.stringify(context.context, null, 2), 'utf-8');
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

