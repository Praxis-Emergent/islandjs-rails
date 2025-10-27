const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');
const { WebpackManifestPlugin } = require('webpack-manifest-plugin');
const fs = require('fs');

const isProduction = process.env.NODE_ENV === 'production';

// Custom plugin to clean old island bundle files
class CleanIslandsPlugin {
  apply(compiler) {
    compiler.hooks.afterEmit.tap('CleanIslandsPlugin', (compilation) => {
      const publicDir = path.resolve(__dirname, 'public');
      if (!fs.existsSync(publicDir)) return;
      
      // Get the newly emitted files
      const emittedFiles = Object.keys(compilation.assets).map(
        filename => filename.split('/').pop() // Get just the filename
      );
      
      const files = fs.readdirSync(publicDir);
      files.forEach(file => {
        // Clean old islands files, but keep the newly emitted ones
        // Also include .map and .LICENSE.txt files
        const isEmitted = emittedFiles.includes(file) || 
                         emittedFiles.some(ef => file.startsWith(ef) && (
                           file.endsWith('.map') || file.endsWith('.LICENSE.txt')
                         ));
        
        if (file.startsWith('islands_') && !isEmitted) {
          const filePath = path.join(publicDir, file);
          try {
            fs.unlinkSync(filePath);
          } catch (err) {
            // Ignore errors
          }
        }
      });
    });
  }
}

module.exports = {
  mode: isProduction ? 'production' : 'development',
  entry: {
    islands_bundle: ['./app/javascript/islands/index.js']
  },
  externals: {
    // IslandJS managed externals - do not edit manually
  },
  output: {
    filename: '[name].[contenthash].js',
    path: path.resolve(__dirname, 'public'),
    publicPath: '/',
    clean: false
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env', '@babel/preset-react']
          }
        }
      }
    ]
  },
  resolve: {
    extensions: ['.js', '.jsx']
  },
  optimization: {
    minimize: isProduction,
    minimizer: [new TerserPlugin()]
  },
  plugins: [
    new CleanIslandsPlugin(),
    new WebpackManifestPlugin({
      fileName: 'islands_manifest.json',
      publicPath: '/'
    })
  ],
  devtool: isProduction ? false : 'source-map'
};
