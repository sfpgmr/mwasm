(module
(memory 0)
(data (i32.const 0) "\00\00\00\00\c2\c5\47\3e\15\ef\c3\3e\da\39\0e\3f\f3\04\35\3f\31\db\54\3f\5e\83\6c\3f\be\14\7b\3f\00\00\80\3f\be\14\7b\3f\5e\83\6c\3f\31\db\54\3f\f3\04\35\3f\da\39\0e\3f\15\ef\c3\3e\c2\c5\47\3e\32\31\0d\25\c2\c5\47\be\15\ef\c3\be\da\39\0e\bf\f3\04\35\bf\31\db\54\bf\5e\83\6c\bf\be\14\7b\bf\00\00\80\bf\be\14\7b\bf\5e\83\6c\bf\31\db\54\bf\f3\04\35\bf\da\39\0e\bf\15\ef\c3\be\c2\c5\47\be")
(export "sin_table" (func $sin_table))
(func $sin_table (param $a i32) (result f32)
  (f32.load
    (i32.load 
      (i32.add
        (i32.const 0 (; sin_table ;))
        (local.get $a)
      )
    )
  )
)
)
