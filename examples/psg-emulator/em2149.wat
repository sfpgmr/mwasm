;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mwasm サンプルコード
;; PSG エミュレータ
;;
;; 以下のコード参考にをWebAssembly化してみた
;; https://github.com/digital-sound-antiques/emu2149
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(; //;; 定数定義 ;;
  $.GETA_BITS = 24;
  $.EMU2149_VOL_YM2149 = 0;
  $.EMU2149_VOL_AY_3_8910 = 1;
  $.EMU2149_VOL_DEFAULT  =  $.EMU2149_VOL_AY_3_8910;
  $.SHIFT_BITS = 1 << $.GETA_BITS;
  $.SHIFT_BITS_MASK = (1 << $.GETA_BITS) - 1;
  $.REG_MAX = 16;
 ;)



(module
  (export "setQuality" (func $set_quality))
  (export "setRate" (func $set_rate))
  (export "init" (func $init))
  (export "setVolumeMode" (func $set_volume_mode))
  (export "setMask" (func $set_mask))
  (export "toggleMask" (func $toggle_mask))
  (export "readIo" (func $read_io))
  (export "readReg" (func $read_reg))
  (export "writeIo" (func $write_io))
  (export "updateOutput" (func $update_output))
  (export "mixOutput" (func $mix_output))
  (export "calc" (func $calc))
  (export "reset" (func $reset))
  (export "writeReg" (func $write_reg))
  (export "memory" (memory $memory))
  (memory $memory 1 )
  ;; 構造体 定義;;
  

  ;; リニアメモリ配置定義
  (data (i32.const 0) "\ff\00\00\00\0f\00\00\00\ff\00\00\00\0f\00\00\00\ff\00\00\00\0f\00\00\00\1f\00\00\00\3f\00\00\00\1f\00\00\00\1f\00\00\00\1f\00\00\00\ff\00\00\00\ff\00\00\00\0f\00\00\00\ff\00\00\00\ff\00\00\00")(data (i32.const 64) "\00\00\00\00\01\00\00\00\01\00\00\00\02\00\00\00\02\00\00\00\03\00\00\00\03\00\00\00\04\00\00\00\05\00\00\00\06\00\00\00\07\00\00\00\09\00\00\00\0b\00\00\00\0d\00\00\00\0f\00\00\00\12\00\00\00\16\00\00\00\1a\00\00\00\1f\00\00\00\25\00\00\00\2d\00\00\00\35\00\00\00\3f\00\00\00\4c\00\00\00\5a\00\00\00\6a\00\00\00\7f\00\00\00\97\00\00\00\b4\00\00\00\d6\00\00\00\ff\00\00\00\ff\00\00\00\00\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\02\00\00\00\02\00\00\00\03\00\00\00\03\00\00\00\05\00\00\00\05\00\00\00\07\00\00\00\07\00\00\00\0b\00\00\00\0b\00\00\00\0f\00\00\00\0f\00\00\00\16\00\00\00\16\00\00\00\1f\00\00\00\1f\00\00\00\2d\00\00\00\2d\00\00\00\3f\00\00\00\3f\00\00\00\5a\00\00\00\5a\00\00\00\7f\00\00\00\7f\00\00\00\b4\00\00\00\b4\00\00\00\ff\00\00\00\ff\00\00\00")

  (func $internal_refresh
     (i32.store (i32.const 0 ) (i32.load (i32.const 392 (; PSG.clk ;))))
     (if
      ;; condition
      (i32.load (i32.const 4500 (; psg.quality ;)))
      (then 
        (i32.store (i32.const 4496 (; psg.base_incr ;)) (i32.const (; 1 << $.GETA_BITS ;)16777216))
        (i32.store 
          (i32.const 4640 (; psg.realstep ;))
          (i32.div_u 
            (i32.const (; 1 << 31 ;)-2147483648)
            (i32.load (i32.const 4492 (; psg.rate ;)))
          ) 
        )
        (i32.store
          (i32.const 4648 (; psg.psgstep ;))
          (i32.div_u
            (i32.const (; 1 << 31 ;)-2147483648)
            (i32.shr_u (i32.load (i32.const 4488 (; psg.clk ;))) (i32.const 4))
          )
        )
        (i32.store (i32.const 4644 (; psg.psgtime ;)) (i32.const 0))
      )
      (else
        (i32.store
          (i32.const 4496 (; psg.base_incr ;))
          (i32.trunc_f64_u 
            (f64.div 
              (f64.mul 
                (f64.convert_i32_u (i32.load (i32.const 4488 (; psg.clk ;))))
                (f64.const (; 1 << $.GETA_BITS ;)16777216)
              )
              (f64.mul
                (f64.convert_i32_u (i32.load (i32.const 4492 (; psg.rate ;))))
                (f64.const 16)
              )
            )
          )
        )
      )

    )
  )

  (func $set_rate (param $r i32) 
    (i32.store (i32.const 4492 (; psg.rate ;)) 
     (select (local.get $r) (i32.const 44100) (local.get $r))
    )
    (call $internal_refresh)
  )

  
  (func $set_quality (param $q i32)
    (i32.store 
      (i32.const 4500 (; psg.quality ;))
      (local.get $q)
    )
    (call $internal_refresh)
  )

  (func $init (param $c i32) (param $r i32)
    (call $set_volume_mode (i32.const (; $.EMU2149_VOL_DEFAULT ;)1))
    (i32.store (i32.const 4488 (; psg.clk ;)) (local.get $c))
    (i32.store 
      (i32.const 4492 (; psg.rate ;))
      (select
        (i32.const 44100)
        (local.get $r)
        (i32.eqz (local.get $r))
      )
    )
    (call $set_quality (i32.const 0))
  )
  
  (func $set_volume_mode (param $type i32)
    (i32.store 
      (i32.const 4480 (; psg.voltbl ;)) 
      (i32.add 
        (i32.const 4160 (; psg.voltbl_ ;)) 
        (i32.shl (local.get $type) (i32.const 7 (; psg.voltbl + 5 ;)))
      )
    )
  )

  (func $set_mask (param $mask i32) (result i32)
    (i32.load (i32.const 4576 (; psg.mask ;)))
    (i32.store (i32.const 4576 (; psg.mask ;)) (local.get $mask))
  )

  (func $toggle_mask (param $mask i32) (result i32)
    (i32.load (i32.const 4576 (; psg.mask ;)))
    (i32.store (i32.const 4576 (; psg.mask ;))
      (i32.xor (i32.load (i32.const 4576 (; psg.mask ;))) (i32.const 0xffff_ffff))
    )
  )

  (func $reset
    (local $c i32)
    (local $work i32)
    (local $size i32)
    (local $count i32)
    (local $freq i32)
    (local $edge i32)
    (local $volume i32)
    (local $ch_out i32)

    (local.set $count (i32.const 4504 (; psg.count ;)))
    (local.set $freq (i32.const 4528 (; psg.freq ;)))
    (local.set $edge (i32.const 4540 (; psg.edge ;)))
    (local.set $volume (i32.const 4516 (; psg.volume ;)))
    (local.set $ch_out (i32.const 4656 (; psg.ch_out ;)))

    (i32.store (i32.const 4580 (; psg.base_count ;)) (i32.const 0))
    (local.set $c (i32.const 3))

    (block $exit
      (loop $loop
        (br_if $exit (i32.eqz (local.get $c)))
        (local.set $c (i32.sub (local.get $c) (i32.const 1)))
        (i32.store (local.get $count) (i32.const 0x1000))
        (i32.store (local.get $freq) (i32.const 0))
        (i32.store (local.get $edge) (i32.const 0))
        (i32.store (local.get $volume) (i32.const 0))
        (i32.store (local.get $ch_out) (i32.const 0))
        (local.set $count (i32.add (local.get $count) (i32.const 4 (; psg.count ;))))
        (local.set $freq (i32.add (local.get $freq) (i32.const 4 (; psg.freq ;))))
        (local.set $edge (i32.add (local.get $edge) (i32.const 4 (; psg.edge ;))))
        (local.set $volume (i32.add (local.get $volume) (i32.const 4 (; psg.volume ;))))
        (local.set $ch_out (i32.add (local.get $ch_out) (i32.const 4 (; psg.ch_out ;))))
        (br $loop)
      )
    )
    
    (i32.store (i32.const 4576 (; psg.mask ;)) (i32.const 0))

    ;; レジスタの初期化
    (local.set $c (i32.const 16))
    (local.set $work (i32.const 4416 (; psg.reg ;)))
    (block $exit_reg
      (loop $loop_reg
        (br_if $exit_reg (i32.eqz(local.get $c) ))
        (local.set $c (i32.sub (local.get $c) (i32.const 1)))
        (i32.store (local.get $work) (i32.const 0))
        (local.set $work (i32.add (local.get $work) (i32.const 4 (; psg.reg ;))) )
        (br $loop_reg)
      )
    )

    (i32.store (i32.const 4652 (; psg.adr ;)) (i32.const 0))
    (i32.store (i32.const 4628 (; psg.noise_seed ;)) (i32.const 0xffff))
    (i32.store (i32.const 4632 (; psg.noise_count ;)) (i32.const 0x40))
    (i32.store (i32.const 4636 (; psg.noise_freq ;)) (i32.const 0))

    (i32.store (i32.const 4584 (; psg.env_volume ;)) (i32.const 0))
    (i32.store (i32.const 4588 (; psg.env_ptr ;)) (i32.const 0))
    (i32.store (i32.const 4620 (; psg.env_freq ;)) (i32.const 0))
    (i32.store (i32.const 4624 (; psg.env_count ;)) (i32.const 0))
    (i32.store (i32.const 4612 (; psg.env_pause ;)) (i32.const 1))

    (i32.store (i32.const 4484 (; psg.out ;)) (i32.const 0))

  )

  (func $read_io (result i32)
    (i32.load
      (i32.add 
        (i32.const 4416 (; psg.reg ;))
        (i32.shl (i32.load (i32.const 4652 (; psg.adr ;))) (i32.const (; Math.log2($.psg.adr[$attributes].size) | 0  ;)2))
      ) 
    )
  )
  (func $read_reg (param $reg i32) (result i32)
    (i32.load
      (i32.add 
        (i32.const 4416 (; psg.reg ;))
        (i32.shl (local.get $reg) (i32.const 2 (; psg.reg ;)))      
      )
    )
  )
  
  (func $write_io (param $adr i32) (param $val i32)
    (if 
      (i32.and (local.get $adr) (i32.const 1))
      (then
        (call $write_reg (i32.load (i32.const 4652 (; psg.adr ;))) (local.get $val))
      )
      (else
        (i32.store (i32.const 4652 (; psg.adr ;)) (i32.and (local.get $val) (i32.const 0x1f))) 
      )
    )
  )

  (func $update_output 
    (local $incr i32)
    (local $noise i32)
    (local $i i32)
    (local $offset i32)

    (i32.store (i32.const 4580 (; psg.base_count ;)) 
      (i32.add 
        (i32.load (i32.const 4580 (; psg.base_count ;)))
        (i32.load (i32.const 4496 (; psg.base_incr ;)))
      )
    )
    (local.set $incr (i32.shr_u (i32.load (i32.const 4580 (; psg.base_count ;))) (i32.const (; $.GETA_BITS ;)24)))
    (i32.store 
      (i32.const 4580 (; psg.base_count ;))
      (i32.and 
        (i32.load(i32.const 4580 (; psg.base_count ;)))
        (i32.const (; $.SHIFT_BITS_MASK ;)16777215)
      )
    )

    ;; Envelope
    (i32.store 
      (i32.const 4624 (; psg.env_count ;))
      (i32.add 
        (i32.load (i32.const 4624 (; psg.env_count ;))) 
        (local.get $incr)
      )
    )
    
    (block $exit_envelope
      (loop $loop_envelope
        (br_if $exit_envelope
          (i32.or 
            (i32.lt_u (i32.load (i32.const 4624 (; psg.env_count ;))) (i32.const 0x10000))
            (i32.eqz (i32.load (i32.const 4620 (; psg.env_freq ;)) ))
          )
        )
        (if (i32.eqz (i32.load (i32.const 4612 (; psg.env_pause ;))))
          (then
            (if (i32.load (i32.const 4592 (; psg.env_face ;)))
              (then
                (i32.store 
                  (i32.const 4588 (; psg.env_ptr ;))
                  (i32.and 
                    (i32.add
                      (i32.load (i32.const 4588 (; psg.env_ptr ;)))
                      (i32.const 1)
                    )
                    (i32.const 0x3f)
                  )
                )
              )
              (else
                (i32.store 
                  (i32.const 4588 (; psg.env_ptr ;))
                  (i32.and 
                    (i32.add
                      (i32.load (i32.const 4588 (; psg.env_ptr ;)))
                      (i32.const 0x3f)
                    )
                    (i32.const 0x3f)
                  )
                )
              
              )
            )
          )
        )

        (if
          (i32.and (i32.load (i32.const 4588 (; psg.env_ptr ;))) (i32.const 0x20))
          (then
            (if 
              (i32.load (i32.const 4596 (; psg.env_continue ;)))
              (then
                (if
                  (i32.xor 
                    (i32.load (i32.const 4604 (; psg.env_alternate ;)))
                    (i32.load (i32.const 4608 (; psg.env_hold ;)))
                  )
                  (then
                    (i32.store (i32.const 4592 (; psg.env_face ;))
                      (i32.xor
                        (i32.load (i32.const 4592 (; psg.env_face ;)))
                        (i32.const 1)
                      )
                    )
                  )
                )
                (if
                  (i32.load (i32.const 4608 (; psg.env_hold ;)))
                  (then
                    (i32.store (i32.const 4612 (; psg.env_pause ;)) (i32.const 1))
                  )
                )
                (i32.store 
                  (i32.const 4588 (; psg.env_ptr ;))
                  (select
                    (i32.const 0)
                    (i32.const 0x1f)
                    (i32.load (i32.const 4592 (; psg.env_face ;)))
                  )
                )
              )
              (else
                (i32.store (i32.const 4612 (; psg.env_pause ;)) (i32.const 1))
                (i32.store (i32.const 4588 (; psg.env_ptr ;)) (i32.const 0))
              )
            )
          )
        )
        (i32.store
          (i32.const 4624 (; psg.env_count ;))
          (i32.sub
            (i32.load (i32.const 4624 (; psg.env_count ;))) 
            (i32.load (i32.const 4620 (; psg.env_freq ;))) 
          ) 
        ) 
        (br $loop_envelope)
      )
    )

    ;; Noise
    (i32.store 
      (i32.const 4632 (; psg.noise_count ;))
      (i32.add
        (i32.load (i32.const 4632 (; psg.noise_count ;)))
        (local.get $incr)
      )
    )
    (if
      (i32.and (i32.load (i32.const 4632 (; psg.noise_count ;))) (i32.const 0x40))
      (then
        (if
          (i32.and 
            (i32.load (i32.const 4628 (; psg.noise_seed ;)))
            (i32.const 1)
          )
          (then
            (i32.store
              (i32.const 4628 (; psg.noise_seed ;))
              (i32.xor 
                (i32.load (i32.const 4628 (; psg.noise_seed ;)))
                (i32.const 0x24000)
              )
            )
          )
        )
        (i32.store 
            (i32.const 4628 (; psg.noise_seed ;))
            (i32.shr_u 
              (i32.load (i32.const 4628 (; psg.noise_seed ;)))
              (i32.const 1)
            )
        )
        (i32.store
          (i32.const 4632 (; psg.noise_count ;))
          (i32.sub 
            (i32.load (i32.const 4632 (; psg.noise_count ;)))
            (select 
              (i32.load (i32.const 4636 (; psg.noise_freq ;)))
              (i32.const 2)
              (i32.load (i32.const 4636 (; psg.noise_freq ;)))
            )
          )
        )
      )
    )
    
    (local.set $noise
      (i32.and 
        (i32.load (i32.const 4628 (; psg.noise_seed ;)))
        (i32.const 1)
      )
    )

    ;; Tone
    (local.set $i (i32.const 3))
    (block $tone_exit
      (loop $tone_loop
        (br_if $tone_exit (i32.eqz (local.get $i)))
        (local.set $i
          (i32.sub (local.get $i) (i32.const 1))
        )

        (local.set $offset
            (i32.shl
              (local.get $i)
              (i32.const 2)
            )
        )
       (i32.store 
          (i32.add 
            (i32.const 4504 (; psg.count ;))
            (local.get $offset)
          )
          (i32.add
            (i32.load
              (i32.add 
                (i32.const 4504 (; psg.count ;))
                (local.get $offset)
              ) 
            )
            (local.get $incr)
          )
        )
        (if
          (i32.and 
            (i32.load
              (i32.add 
                (i32.const 4504 (; psg.count ;))
                (local.get $offset)
              )
            )
            (i32.const 0x1000)
          )
          (then
            (if
              (i32.gt_u
                (i32.load
                  (i32.add 
                    (i32.const 4528 (; psg.freq ;))
                    (local.get $offset)
                  )
                )
                (i32.const 1)
              )
              (then
                (i32.store
                  (i32.add 
                    (i32.const 4540 (; psg.edge ;))
                    (local.get $offset)
                  )
                  (i32.xor
                    (i32.load
                      (i32.add 
                        (i32.const 4540 (; psg.edge ;))
                        (local.get $offset)
                      )
                    )
                    (i32.const 0x1 )
                  )
                )
                (i32.store
                  (i32.add 
                    (i32.const 4504 (; psg.count ;))
                    (local.get $offset)
                  )
                  (i32.sub
                    (i32.load
                      (i32.add 
                        (i32.const 4504 (; psg.count ;))
                        (local.get $offset)
                      )
                    )
                    (i32.load
                      (i32.add 
                        (i32.const 4528 (; psg.freq ;))
                        (local.get $offset)
                      )
                    )
                  )
                )
              )
              (else
                (i32.store
                  (i32.add 
                    (i32.const 4540 (; psg.edge ;))
                    (local.get $offset)
                  )
                  (i32.const 1)

                )
              )
            )
          )
        )


        
       
        (if
          (i32.and
            (select (i32.const 1) (i32.const 0) 
              (i32.or
                (i32.load (i32.add (i32.const 4552 (; psg.tmask ;)) (local.get $offset)))
                (i32.load (i32.add (i32.const 4540 (; psg.edge ;)) (local.get $offset)))
              )
            )
            (select (i32.const 1) (i32.const 0)
              (i32.or
                (i32.load (i32.add (i32.const 4564 (; psg.nmask ;)) (local.get $offset)))
                (local.get $noise)
              )
            )
          )
          (then
            (if
              (i32.eqz 
                (i32.and
                  (i32.load
                    (i32.add 
                      (i32.const 4516 (; psg.volume ;))
                      (local.get $offset)
                    )
                  )
                  (i32.const 32)
                )
              )
              (then
                (i32.store
                  (i32.add
                    (i32.const 4656 (; psg.ch_out ;))
                    (local.get $offset)
                  )
                  (i32.add
                    (i32.load 
                      (i32.add
                        (i32.const 4656 (; psg.ch_out ;))
                        (local.get $offset)
                      )
                    )
                    (i32.shl
                      (i32.load
                        (i32.add
                          (i32.load (i32.const 4480 (; psg.voltbl ;)))
                          (i32.shl
                            (i32.and 
                              (i32.load
                                (i32.add
                                  (i32.const 4516 (; psg.volume ;))
                                  (local.get $offset)
                                )
                              )
                              (i32.const 31)
                            )
                            (i32.const 2 (; psg.voltbl ;))
                          )
                        )
                      )
                      (i32.const 4)
                    )
                  )
                )  
              )
              (else
                (i32.store
                  (i32.add
                    (i32.const 4656 (; psg.ch_out ;))
                    (local.get $offset)
                  )
                  (i32.add
                    (i32.load
                      (i32.add
                        (i32.const 4656 (; psg.ch_out ;))
                        (local.get $offset)
                      )
                    )
                    (i32.shl
                      (i32.load
                        (i32.add 
                          (i32.load (i32.const 4480 (; psg.voltbl ;)))
                          (i32.shl 
                            (i32.load (i32.const 4588 (; psg.env_ptr ;)))
                            (i32.const 2 (; psg.voltbl_ ;))
                          )
                        )
                      )
                      (i32.const 4)
                    )
                  )
                )
              )
            )
          )

        )

        (i32.store 
          (i32.add
            (i32.const 4656 (; psg.ch_out ;))
            (local.get $offset)
          )
          (i32.shr_u
            (i32.load
              (i32.add
                (i32.const 4656 (; psg.ch_out ;))
                (local.get $offset)
              )
            )
            (i32.const 1)
          )
        )
        (br $tone_loop)
      )
    )
  )

  (func $mix_output (result i32)
    (i32.store
      (i32.const 4484 (; psg.out ;))
      (i32.add
        (i32.load (i32.const 4656 (; psg.ch_out ;)))
        (i32.add
          (i32.load (i32.const 4660 (; psg.ch_out ;)))
          (i32.load (i32.const 4664 (; psg.ch_out ;)))
        )
      )
    )
    (i32.load (i32.const 4484 (; psg.out ;)))
  )

  (func $calc (result i32)
    (if (i32.eqz (i32.load (i32.const 4500 (; psg.quality ;))))
      (then
        call $update_output
        call $mix_output
        return
      )
    )
    (block $rate_loop_exit
      (loop $rate_loop
        (br_if $rate_loop_exit 
          (i32.le_u (i32.load(i32.const 4640 (; psg.realstep ;))) (i32.load(i32.const 4644 (; psg.psgtime ;))))
        )
        (i32.store
          (i32.const 4644 (; psg.psgtime ;))
          (i32.add
            (i32.load(i32.const 4644 (; psg.psgtime ;)))
            (i32.load(i32.const 4648 (; psg.psgstep ;)))
          )
        )
        call $update_output
        (br $rate_loop)
      )
    )
    (i32.store
      (i32.const 4644 (; psg.psgtime ;))
      (i32.sub
        (i32.load(i32.const 4644 (; psg.psgtime ;)))
        (i32.load(i32.const 4640 (; psg.realstep ;)))
      )
    )

    call $mix_output
  )



  (func $write_reg (param $reg i32) (param $val i32) (local $c i32) (local $w i32)
    (if (i32.gt_u (local.get $reg) (i32.const 15))
      (then
        return
      )
    )
    (local.set $val
      (i32.and
        (local.get $val)
        (i32.load 
          (i32.add 
            (i32.const 4096 (; psg.regmsk ;))
            (i32.shl 
              (local.get $reg)
              (i32.const 2 (; psg.regmsk ;))
            )
          )
        )
      ) 
    )

    (i32.store
      (i32.add 
        (i32.const 4416 (; psg.reg ;))
        (i32.shl 
          (local.get $reg)
          (i32.const 2 (; psg.reg ;))
        )
      )
      (local.get $val)
    )
    
    (block $default
      (br_if $default (i32.gt_u (local.get $reg) (i32.const 13))) 
      (block $reg0_5
        (block $reg6
          (block $reg7
            (block $reg8_10
              (block $reg11_12
                (block $reg13
                  (br_table 
                    $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg6 $reg7 
                    $reg8_10 $reg8_10 $reg8_10 $reg11_12 $reg11_12 $reg13
                    (local.get $reg)
                  )
                )
                ;; reg 13
                (i32.store
                  (i32.const 4596 (; psg.env_continue ;)) 
                  (i32.and
                    (i32.shr_u (local.get $val) (i32.const 3))
                    (i32.const 1)
                  )
                )
                (i32.store
                  (i32.const 4600 (; psg.env_attack ;)) 
                  (i32.and
                    (i32.shr_u (local.get $val) (i32.const 2))
                    (i32.const 1)
                  )
                )
                (i32.store
                  (i32.const 4604 (; psg.env_alternate ;)) 
                  (i32.and
                    (i32.shr_u (local.get $val) (i32.const 1))
                    (i32.const 1)
                  )
                )
                (i32.store
                  (i32.const 4608 (; psg.env_hold ;)) 
                  (i32.and
                    (local.get $val)
                    (i32.const 1)
                  )
                )
                (i32.store
                  (i32.const 4592 (; psg.env_face ;)) 
                  (i32.load (i32.const 4600 (; psg.env_attack ;))) 
                )
                (i32.store
                  (i32.const 4612 (; psg.env_pause ;)) 
                  (i32.const 0) 
                )
                (i32.store
                  (i32.const 4624 (; psg.env_count ;)) 
                  (i32.sub 
                    (i32.const 0x10000)
                    (i32.load (i32.const 4620 (; psg.env_freq ;)))
                  )
                )
                (i32.store
                  (i32.const 4588 (; psg.env_ptr ;))
                  (select
                    (i32.const 0)
                    (i32.const 0x1f)
                    (i32.load (i32.const 4592 (; psg.env_face ;)))
                  )
                )
                return
              )
              ;; reg11-12
              (i32.store
                (i32.const 4620 (; psg.env_freq ;))
                (i32.add 
                  (i32.shl
                    (i32.load (i32.const 4464 (; psg.reg ;)))
                    (i32.const 8)
                  )
                  (i32.load(i32.const 4460 (; psg.reg ;)))
                )
              )
              return
            )
            ;; reg 8-10
            (i32.store
              (i32.add 
                (i32.const 4516 (; psg.volume ;))
                (i32.shl 
                  (i32.sub (local.get $reg) (i32.const 8)) 
                  (i32.const 2 (; psg.volume ;))
                )
              )
              (i32.shl
                (local.get $val)
                (i32.const 1)
              )
            )
            return
          )
          ;; reg 7
          ;;(local.set $val (i32.xor (i32.const 0xff) (local.get $val)))
          (i32.store (i32.const 4552 (; psg.tmask ;)) (i32.and (local.get $val) (i32.const 1)))
          (i32.store (i32.const 4556 (; psg.tmask ;)) (i32.and (local.get $val) (i32.const 2)))
          (i32.store (i32.const 4560 (; psg.tmask ;)) (i32.and (local.get $val) (i32.const 4)))

          (i32.store (i32.const 4564 (; psg.nmask ;)) (i32.and (local.get $val) (i32.const 8)))
          (i32.store (i32.const 4568 (; psg.nmask ;)) (i32.and (local.get $val) (i32.const 16)))
          (i32.store (i32.const 4572 (; psg.nmask ;)) (i32.and (local.get $val) (i32.const 32)))

          return
        )
        ;; reg 6
        (i32.store 
          (i32.const 4636 (; psg.noise_freq ;))
          (i32.shl
            (i32.and
              (local.get $val)
              (i32.const 31)
            )
            (i32.const 1)
          )
        )
        return
      ) 
      ;; reg 0-5
      (local.set $c 
        (i32.shr_u
          (local.get $reg)
          (i32.const 1)
        )
      )

      (i32.store
        (i32.add
          (i32.const 4528 (; psg.freq ;))
          (i32.shl (local.get $c) (i32.const 2 (; psg.freq ;)))
        )
        (i32.add
          (i32.shl 
            (i32.and 
              (i32.load
                (i32.add 
                  (i32.const 4416 (; psg.reg ;))
                  (i32.shl
                    (i32.add
                      (i32.shl
                        (local.get $c)
                        (i32.const 1)
                      )
                      (i32.const 1)
                    )
                    (i32.const 2 (; psg.reg ;))
                  )
                )
              )
              (i32.const 15)
            )
            (i32.const 8)
          )
          (i32.load
            (i32.add
              (i32.const 4416 (; psg.reg ;))
              (i32.shl
                (i32.shl 
                  (local.get $c)
                  (i32.const 1)
                )
                (i32.const 2 (; psg.reg ;))
              )
            )
          )
        )
      )
      return
    )
  )
)
