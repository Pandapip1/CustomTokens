import HtmlWebpackPlugin from 'html-webpack-plugin';
import { VueLoaderPlugin } from 'vue-loader';
import NodePolyfillPlugin from 'node-polyfill-webpack-plugin';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default {
  entry: './src/index.js',
  module: {
    rules: [
      { test: /\.vue$/, use: 'vue-loader' },
      { test: /\.js$/, use: 'babel-loader', include: path.resolve(__dirname, 'src') },
      { test: /\.css$/, use: ['vue-style-loader', 'css-loader'] },
    ]
  }, plugins: [
    new HtmlWebpackPlugin({
      template: './src/index.html',
    }),
    new VueLoaderPlugin(),
    new NodePolyfillPlugin(),
  ],
  experiments: {
    asyncWebAssembly: true
  },
};
