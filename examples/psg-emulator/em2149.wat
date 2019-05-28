   (module (memory $memory 1 ) (export "memory" (memory $memory)) (data (i32.const 4096) "\ff\00\00\00\0f\00\00\00\ff\00\00\00\0f\00\00\00\ff\00\00\00\0f\00\00\00\1f\00\00\00\3f\00\00\00\1f\00\00\00\1f\00\00\00\1f\00\00\00\ff\00\00\00\ff\00\00\00\0f\00\00\00\ff\00\00\00\ff\00\00\00")(data (i32.const 4160) "\00\00\00\00\00\00\00\00\01\00\00\00\02\00\00\00\02\00\00\00\03\00\00\00\03\00\00\00\04\00\00\00\05\00\00\00\06\00\00\00\07\00\00\00\09\00\00\00\1f\00\00\00\21\00\00\00\23\00\00\00\12\00\00\00\16\00\00\00\2e\00\00\00\33\00\00\00\25\00\00\00\41\00\00\00\35\00\00\00\53\00\00\00\60\00\00\00\6e\00\00\00\7e\00\00\00\93\00\00\00\97\00\00\00\f4\01\00\00\16\02\00\00\53\02\00\00\53\02\00\00\00\00\00\00\00\00\00\00\01\00\00\00\01\00\00\00\02\00\00\00\02\00\00\00\03\00\00\00\03\00\00\00\05\00\00\00\05\00\00\00\07\00\00\00\07\00\00\00\1f\00\00\00\1f\00\00\00\23\00\00\00\23\00\00\00\16\00\00\00\16\00\00\00\33\00\00\00\33\00\00\00\41\00\00\00\41\00\00\00\53\00\00\00\53\00\00\00\6e\00\00\00\6e\00\00\00\93\00\00\00\93\00\00\00\f4\01\00\00\f4\01\00\00\53\02\00\00\53\02\00\00") (data $dt (i32.const 6400) ) (func $internal_refresh (if  (i32.eqz (i32.load (i32.const 4564))) (then (i32.store (i32.const 4560) (i32.wrap_i64 (i64.div_u (i64.mul (i64.extend_i32_u (i32.load (i32.const 4552))) (i64.const 16777216) ) (i64.shl (i64.extend_i32_u (i32.load (i32.const 4556))) (i32.const 4) ) ) ) ) ) (else (i32.store (i32.const 4560) (i32.const 16777216)) (i32.store (i32.const 4704) (i32.div_u (i32.const -2147483648)  (i32.load (local.get $dt)) ) ) (i32.store (i32.const 4712) (i32.div_u (i32.const -2147483648) (i32.shr_u (i32.load (i32.const 4552)) (i32.const 4)) ) ) (i32.store (i32.const 4708) (i32.const 0)) ) ) ) (func $set_rate (param $r i32) (i32.store (i32.const 4556) (local.get $r)) (call $internal_refresh) ) (func $set_quality (param $q i32) (i32.store (i32.const 4564) (local.get $q)) (call $internal_refresh) ) (func $init (param $c i32) (param $r i32) (call $set_volume_mode (i32.const 1)) (i32.store (i32.const 4552) (i32.const 0)) (i32.store (i32.const 4556) (select (local.get $r) (i32.const 44100) (i32.eqz (local.get $r)) ) ) (call $set_quality (i32.const 0)) ) (func $set_volume_mode (param $type i32) (i32.store (i32.const 4544) (i32.add (i32.const 4160) (i32.shl (local.get $type) (i32.const 5)))) ) (func $set_mask (param $mask i32) (result i32) (i32.load (i32.const 4640)) (i32.store (i32.const 4640) (local.get $mask)) ) (func $toggle_mask (param $mask i32) (result i32) (i32.load (i32.const 4640)) (i32.store (i32.const 4640) (i32.xor (i32.load (i32.const 4640)) (i32.const 0xffff_ffff)) ) ) (func $reset (local $c i32) (local $work i32) (local $size i32) (local $count i32) (local $freq i32) (local $edge i32) (local $volume i32) (local $ch_out i32) (local.set $count (i32.const 4568)) (local.set $freq (i32.const 4592)) (local.set $edge (i32.const 4604)) (local.set $volume (i32.const 4580)) (local.set $ch_out (i32.const 4732)) (i32.store (i32.const 4644) (i32.const 0)) (local.tee $c (i32.const 3)) (block $exit (loop $loop (br_if $exit (i32.eqz)) (local.tee $c (i32.sub (local.get $c) (i32.const 1))) (i32.store (local.get $count) (i32.const 0x1000)) (i32.store (local.get $freq) (i32.const 0)) (i32.store (local.get $edge) (i32.const 0)) (i32.store (local.get $volume) (i32.const 0)) (i32.store (local.get $ch_out) (i32.const 0)) (local.set $count (i32.add (local.get $count) (i32.const 4))) (local.set $freq (i32.add (local.get $freq) (i32.const 4))) (local.set $edge (i32.add (local.get $edge) (i32.const 4))) (local.set $volume (i32.add (local.get $volume) (i32.const 4))) (local.set $ch_out (i32.add (local.get $ch_out) (i32.const 4))) (br $loop) ) ) (i32.store (i32.const 4640) (i32.const 0))  (local.tee $c (i32.const 16)) (local.set $work (i32.const 4416)) (block $exit_reg (loop $loop_reg (br_if $exit_reg (i32.eqz )) (local.tee $c (i32.sub (local.get $c) (i32.const 1))) (i32.store (local.get $work) (i32.const 0)) (local.set $work (i32.add (local.get $work) (i32.const 4640)) ) (br $loop) ) ) (i32.store (i32.const 4728) (i32.const 0)) (i32.store (i32.const 4696) (i32.const 0x40)) (i32.store (i32.const 4700) (i32.const 0)) (i32.store (i32.const 4648) (i32.const 0)) (i32.store (i32.const 4652) (i32.const 0)) (i32.store (i32.const 4684) (i32.const 0)) (i32.store (i32.const 4688) (i32.const 0)) (i32.store (i32.const 4676) (i32.const 0)) (i32.store (i32.const 4548) (i32.const 0)) ) (func $read_io (result i32) (i32.load (i32.add (i32.const 4416) (i32.shl (i32.load (i32.const 4728)) (i32.const 2)) ) ) ) (func $read_reg (param $reg i32) (result i32) (i32.load (i32.add (i32.const 4416) (i32.shl (local.get $reg) (i32.const 2)) ) ) ) (func $write_io (param $adr i32) (param $val i32) (if (i32.and (local.get $adr) (i32.const 1)) (then (call $write_reg (i32.load (i32.const 4728)) (local.get $val)) ) (else (i32.store (i32.const 4728) (i32.and (local.get $val) (i32.const 0x1f))) ) ) ) (func $update_output (local $incr i32) (local $noise i32) (local $i i32) (local $offset i32) (i32.store (i32.const 4644) (i32.add (i32.load (i32.const 4644)) (i32.load (i32.const 4560)) ) ) (local.set $incr (i32.shr_u (i32.load (i32.const 4644)) (i32.const 24))) (i32.store (i32.const 4644) (i32.and (i32.load(i32.const 4644)) (i32.const 8388608) ) )  (i32.store (i32.const 4688) (i32.add (i32.load (i32.const 4688)) (local.get $incr) ) ) (block $exit_envelope (loop $loop_envelope (br_if $exit_envelope (i32.or (i32.lt_u (i32.load (i32.const 4688)) (i32.const 0x10000)) (i32.eqz (i32.load (i32.const 4684) )) ) ) (if (i32.eqz (i32.load (i32.const 4676))) (then (if (i32.gt_u (i32.load (i32.const 4656)) (i32.const 0) ) (then (i32.store (i32.const 4652) (i32.and (i32.add (i32.load (i32.const 4652)) (i32.const 1) ) (i32.const 0x3f) ) ) ) (else (i32.store (i32.const 4652) (i32.and (i32.add (i32.load (i32.const 4652)) (i32.const 0x3f) ) (i32.const 0x3f) ) ) ) ) ) ) (if (i32.and (i32.load (i32.const 4652)) (i32.const 0x20)) (then (if (i32.or (i32.load (i32.const 4660)) (i32.const 0)) (then (if (i32.xor (i32.load (i32.const 4668)) (i32.load (i32.const 4672)) ) (then (i32.store (i32.const 4656) (i32.xor (i32.load (i32.const 4656)) (i32.const 1) ) ) ) ) (if (i32.or (i32.load (i32.const 4672)) (i32.const 0)) (then (i32.store (i32.const 4676) (i32.const 1)) ) ) (i32.store (i32.const 4652) (select (i32.const 0) (i32.const 0x1f) (i32.or (i32.load (i32.const 4656)) (i32.const 0)) ) ) ) (else (i32.store (i32.const 4676) (i32.const 1)) (i32.store (i32.const 4652) (i32.const 0)) ) ) ) ) (i32.store (i32.const 4688) (i32.sub (i32.load (i32.const 4688)) (i32.load (i32.const 4684)) ) ) (br $loop_envelope) ) )  (i32.store (i32.const 4696) (i32.add (i32.load (i32.const 4696)) (local.get $incr) ) ) (if (i32.and (i32.load (i32.const 4696)) (i32.const 0x40)) (then (if (i32.and (i32.load (i32.const 4692)) (i32.const 1) ) (then (i32.store (i32.const 4692) (i32.xor (i32.load (i32.const 4692)) (i32.const 0x24000) ) ) ) ) (i32.store (i32.const 4692) (i32.shr_u (i32.const 4692) (i32.const 1) ) ) (i32.store (i32.const 4696) (i32.sub (i32.const 4696) (select (i32.load (i32.const 4700)) (i32.const 2) (i32.or (i32.load (i32.const 4700)) (i32.const 0)) ) ) ) ) ) (local.set $noise (i32.and (i32.load (i32.const 4692)) (i32.const 1) ) )  (local.set $i (i32.const 2)) (block $tone_exit (loop $tone_loop (br_if $tone_exit (i32.eqz (local.get $i))) (local.set $offset (i32.shl (local.get $i) (i32.const 2) ) ) (i32.store (i32.add (i32.const 4568) (local.get $offset) ) (i32.add (i32.load (i32.add (i32.const 4568) (local.get $offset) ) ) (local.get $incr) ) ) (if (i32.and (i32.load (i32.add (i32.const 4568) (local.get $offset) ) ) (i32.const 0x1000) ) (then (if (i32.gt_u (i32.load (i32.add (i32.const 4592) (local.get $offset) ) ) (i32.const 1) ) (then (i32.store (i32.add (i32.const 4592) (local.get $offset) ) (i32.xor (i32.load (i32.add (i32.const 4604) (local.get $offset) ) ) (i32.const 0xffff_ffff ) ) ) (i32.store (i32.add (i32.const 4568) (local.get $offset) ) (i32.sub (i32.load (i32.add (i32.const 4568) (local.get $offset) ) ) (i32.load (i32.add (i32.const 4592) (local.get $offset) ) ) ) ) ) (else (i32.store (i32.add (i32.const 4604) (local.get $offset) ) (i32.const 1) ) ) ) ) ) (if (i32.and (i32.load (i32.const 4640)) (i32.shl (i32.const 1) (local.get $i)) ) (then (local.set $i (i32.sub (local.get $i) (i32.const 1) ) ) (br $tone_loop) ) ) (if (i32.and (i32.or (i32.load (i32.add (i32.const 4616) (local.get $offset))) (i32.load (i32.add (i32.const 4604) (local.get $offset))) ) (i32.or (i32.load (i32.add (i32.const 4628) (local.get $offset))) (local.get $noise) ) ) (then (if (i32.xor (i32.and (i32.load (i32.add (i32.const 4580) (local.get $offset) ) ) (i32.const 32) ) (i32.const 0xffff_ffff) ) (then (i32.store (i32.add (i32.const 4732) (local.get $offset) ) (i32.add (i32.add (i32.const 4732) (local.get $offset) ) (i32.shl (i32.load (i32.add (i32.load (i32.const 4544)) (i32.and (i32.load (i32.add (i32.const 4580) (local.get $offset) ) ) (i32.const 31) ) ) ) (i32.const 4) ) ) ) ) (else (i32.store (i32.add (i32.const 4732) (local.get $offset) ) (i32.add (i32.load (i32.add (i32.const 4732) (local.get $offset) ) ) (i32.shl (i32.load (i32.add (i32.load (i32.const 4544)) (i32.load (i32.const 4652)) ) ) (i32.const 4) ) ) ) ) ) ) ) (i32.store (i32.add (i32.const 4732) (local.get $offset) ) (i32.shr_u (i32.load (i32.add (i32.const 4732) (local.get $offset) ) ) (i32.const 1) ) ) (br $tone_loop) ) ) ) (func $mix_output (result i32) (i32.store (i32.const 4548) (i32.add (i32.load (i32.const 4732)) (i32.add (i32.load (i32.const 4736)) (i32.load (i32.const 4740)) ) ) ) ) (func $calc (result i32) (if (i32.eqz (i32.load (i32.const 4564))) (then call $update_output call $mix_output return ) ) (block $rate_loop_exit (loop $rate_loop (br_if $rate_loop_exit (i32.le_u (i32.load(i32.const 4704) (i32.load(i32.const 4708))))) (i32.store (i32.const 4708) (i32.add (i32.load(i32.const 4708)) (i32.load(i32.const 4712)) ) ) call $update_output ) ) (i32.store (i32.const 4708) (i32.sub (i32.load(i32.const 4708)) (i32.load(i32.const 4704)) ) ) call $mix_output ) (func $writereg (param $reg i32) (param $val i32) (local $c i32) (local $reg_offset i32) (local $w i32) (if (i32.gt_u (local.get $reg) (i32.const 15)) (then return ) ) (local.set $reg_offset (i32.add (i32.const 4096) (i32.shl (local.get $reg) (i32.const 2) ) ) ) (local.set $val (i32.and (local.get $val) (i32.load (local.get $reg_offset)) ) ) (i32.store (local.get $reg_offset) (i32.and (local.get $val) (i32.const 0xff) ) ) (block $default (br_if $default (i32.gt_u (local.get $reg) (i32.const 13))) (block $reg0_5 (block $reg6 (block $reg7 (block $reg8_10 (block $reg11_12 (block $reg13 (br_table $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg0_5 $reg6 $reg7 $reg8_10 $reg8_10 $reg8_10 $reg11_12 $reg11_12 $reg13 (local.get $reg) ) )  (i32.store (i32.const 4660) (i32.and (i32.shr_u (local.get $val) (i32.const 3)) (i32.const 1) ) ) (i32.store (i32.const 4664) (i32.and (i32.shr_u (local.get $val) (i32.const 2)) (i32.const 1) ) ) (i32.store (i32.const 4668) (i32.and (i32.shr_u (local.get $val) (i32.const 1)) (i32.const 1) ) ) (i32.store (i32.const 4672) (i32.and (local.get $val) (i32.const 1) ) ) (i32.store (i32.const 4656) (i32.load (i32.const 4656)) ) (i32.store (i32.const 4676) (i32.const 0) ) (i32.store (i32.const 4688) (i32.sub (i32.const 0x10000) (i32.load (i32.const 4684)) ) ) (i32.store (i32.const 4688) (select (i32.const 0) (i32.const 0x1f) (i32.load (i32.const 4656)) ) ) return )  (i32.store (i32.const 4684) (i32.add (i32.shl (i32.load (i32.const 4464) ) (i32.const 8) ) (i32.load(i32.const 4460)) ) ) return )  (i32.store (i32.add (i32.const 4580) (i32.shl (i32.sub (local.get $reg) (i32.const 8)) (i32.const 2) ) ) (i32.shl (local.get $val) (i32.const 1) ) ) return )  (i32.store (i32.const 4616) (i32.and (local.get $val) (i32.const 1))) (i32.store (i32.const 4620) (i32.and (local.get $val) (i32.const 2))) (i32.store (i32.const 4624) (i32.and (local.get $val) (i32.const 4))) (i32.store (i32.const 4628) (i32.and (local.get $val) (i32.const 8))) (i32.store (i32.const 4632) (i32.and (local.get $val) (i32.const 16))) (i32.store (i32.const 4636) (i32.and (local.get $val) (i32.const 32))) return )  (i32.store (i32.const 4700) (i32.shl (i32.and (local.get $val) (i32.const 31) ) (i32.const 1) ) ) return )  (local.set $c (i32.shr_u (local.get $c) (i32.const 1) ) ) (local.set $w (i32.const 2) ) (i32.store (i32.add (i32.const 4592) ( ) return ) ) ) 