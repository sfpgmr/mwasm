"use strict";
import fs from 'fs'
function getInstance(obj, imports = {}) {
  const bin = new WebAssembly.Module(obj);
  const inst = new WebAssembly.Instance(bin, imports);
  return inst;
}

(async ()=>{
  const psg  = getInstance(await fs.promises.readFile('./em2149.wasm')).exports;
  
        psg.writeReg(8, 32);
        psg.writeReg(0, 0x5d);
        psg.writeReg(1, 0xd);
        psg.writeReg(2, 0x5d);
        psg.writeReg(3, 0x1);
        psg.writeReg(4, 0x5d);
        psg.writeReg(5, 0x2);
        psg.writeReg(7, 0b111110);
        psg.writeReg(6, 0x10);
        psg.writeReg(13,9);
        psg.writeReg(12,1);

        for(let i = 0;i < 1024;++i){
          console.log(psg.calc());
        }
})();


