import nodeResolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';

export default [{
  input: './lib/index.mjs',
  plugins: [
    nodeResolve({ jsnext: true }),
    commonjs()
  ],
  external: [
    'wabt','binaryen'
  ],
  output: {
    file: './index.js',
    format: 'esm'
  }
}];
