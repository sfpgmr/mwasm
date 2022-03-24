
(; // JS コードブロック

 // $には関数などもセットできる
 $.circleArea = r =>{
   return r * r * Math.PI;
 }
 
 // $には配列などもセットできる
 $.array = [0,1,2,3,4,5];

 // thisにはrequireメソッドあり
 // ファイルシステムを使ってみる
 const fs = this.require('fs');
 // ソースファイルを読み込んで$にセットしてみる
 $.data = fs.readFileSync("./test8_inc.wat","utf-8");

 ;)

(module
  (memory $memory 1 )
  (export "memory" (memory $memory))
  (export "test" (func $test))
  (func $test (result f32)
    (; 式の結果を定数として埋め込む ;)
    f32.const 7.141592653589793 (; circleArea(1) + array['4'] ;)
    (; fsによって読み込んだソースコードを展開する;)
    
  f32.const 3
  f32.add

 (; data ;) 
  )
)
