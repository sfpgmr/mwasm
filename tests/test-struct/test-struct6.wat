(module
  (memory 0)
  ;; 構造体の定義
  
  ;; メモリーマップ
  

  (export "test" (func $test))
  (func $test (result i32)
    (i32.add 
      (i32.load (i32.const 0 (; a.a ;))) ;;メンバはドット演算子で指定
      (i32.load (i32.const 4 (; a.b ;)))
    )
  )
)
