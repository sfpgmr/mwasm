(module
  (memory $memory 1 )
  (export "memory" (memory $memory))
  (export "test" (func $test))
  (func $test (result i32)
    i32.const 0
    i32.load
    (; 
      let offset = 4;
      // JSによるWASMソースコード生成
      let instructions = '';
      for(let i = 0;i < 16; ++ i ){
        instructions += `
    i32.const ${offset}
    i32.load 
    i32.add`;
        offset += 4;
      }
      return instructions;
     ;)
    i32.const 4
    i32.load 
    i32.add
    i32.const 8
    i32.load 
    i32.add
    i32.const 12
    i32.load 
    i32.add
    i32.const 16
    i32.load 
    i32.add
    i32.const 20
    i32.load 
    i32.add
    i32.const 24
    i32.load 
    i32.add
    i32.const 28
    i32.load 
    i32.add
    i32.const 32
    i32.load 
    i32.add
    i32.const 36
    i32.load 
    i32.add
    i32.const 40
    i32.load 
    i32.add
    i32.const 44
    i32.load 
    i32.add
    i32.const 48
    i32.load 
    i32.add
    i32.const 52
    i32.load 
    i32.add
    i32.const 56
    i32.load 
    i32.add
    i32.const 60
    i32.load 
    i32.add
    i32.const 64
    i32.load 
    i32.add
  )
)
