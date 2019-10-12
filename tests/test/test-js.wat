(; $.X = 1;
  $.Y = 2;
 ;)
(module
  (func $test2 (result i32)
    i32.const (; $.X ;)1 ;; comment
    i32.const (; $.X + $.Y  ;)3
    i32.add
    (; 
      // JSによるWASMソースコード生成
      let instructions = '';
      for(let i = 0;i < 4; ++ i ){
        ++$.X; 
        instructions += `
  i32.const ${$.X + $.Y}
  i32.add`;
      }
      return instructions;
     ;)
  i32.const 4
  i32.add
  i32.const 5
  i32.add
  i32.const 6
  i32.add
  i32.const 7
  i32.add
  )
)