
(; // JS コードブロック
 // 定数値をコンテキスト・オブジェクトに定義する
 $.R = 2;
 $.Math = Math; // Mathをプロパティにセットする
 ;)
(module
  (memory $memory 1 )
  (export "memory" (memory $memory))
  (export "test" (func $test))
    (func $test (result f32)
      (f32.const 1.414213562373095 (; R * Math.sin(Math.PI/4) ;))
    )
)
