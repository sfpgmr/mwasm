class PSG extends AudioWorkletProcessor {
  constructor(options){
    super();
    this.options = options;
    if(options.processorOptions){
      const userOptions = options.processorOptions;
      
      (!userOptions.clock) && (userOptions.clock = 3580000);
      (!userOptions.sampleRate) && (userOptions.sampleRate = sampleRate);

      if(userOptions.wasmBinary){
        const module = new WebAssembly.Module(userOptions.wasmBinary);
        const instance = new WebAssembly.Instance(module, {});
        this.module = instance.exports;
        this.module.init(userOptions.clock,userOptions.sampleRate);
        this.module.reset();
        this.enable = true;

        this.port.onmessage = (event)=>{
          if(this.enable){
            const message = event.data;
            switch(message.message){
              case 'writeReg':
                this.module.writeReg(message.reg,message.value);
                this.port.postMessage({
                  check:this.module.readReg(message.reg) == message.value,
                  value:message.value,
                  read:this.module.readReg(message.reg),
                  reg:message.reg
                });
                break;
            }
          }
        }        
      }
    }
  
  }


  static get parameterDescriptors () {
      return [{
          name: 'register',
          defaultValue: 0,
          minValue: 0,
          maxValue: 15,
          automationRate: "a-rate"
      },
      {
        name: 'value',
        defaultValue: 0,
        minValue: 0,
        maxValue: 15,
        automationRate: "a-rate"
      }
    ];
  }




  process (inputs, outputs, parameters) {
      if(this.enable){
        let output = outputs[0];
        for (let i = 0,e = output[0].length; i < e; ++i) {

          const out = this.module.calc() / 16384;

          for (let channel = 0; channel < output.length; ++channel) {
              output[channel][i] = out;
          }
        }
      }
      return true;
  }
}
registerProcessor("PSG", PSG);
