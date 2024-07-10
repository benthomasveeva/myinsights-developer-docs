import { nodeResolve } from '@rollup/plugin-node-resolve';

export default {
  input: 'src/codemirror-element.js',
  output: {
    dir: 'dist',
    name: 'codemirrorElement',
    format: 'iife'
  },
  plugins: [nodeResolve()]
};