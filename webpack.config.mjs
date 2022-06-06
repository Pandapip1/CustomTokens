import HtmlWebpackPlugin from 'html-webpack-plugin';
import { VueLoaderPlugin } from 'vue-loader';

export default {
  entry: './src/index.ts',
  module: {
    rules: [
      { test: /\.js$/, use: 'babel-loader' },
      { test: /\.ts$/, use: ['ts-loader', 'babel-loader'] },
      { test: /\.vue$/, use: ['ts-loader', 'vue-loader'] },
      { test: /\.css$/, use: ['vue-style-loader', 'css-loader'] },
    ]
  }, plugins: [
    new HtmlWebpackPlugin({
      template: './src/index.html',
    }),
    new VueLoaderPlugin(),
  ]
};
