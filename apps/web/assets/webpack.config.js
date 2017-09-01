var path = require("path");
var ExtractTextPlugin = require("extract-text-webpack-plugin");
module.exports = {
  entry: {
    app: "./js/app",
    userAttributes: "./js/userAttributes"
  },
  output: {
    path: path.join(__dirname, "../priv/static"),
    filename: "js/[name].js"
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['env', 'react']
          }
        }
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: "css-loader"
        })
      },
    ]
  },
  plugins: [
    new ExtractTextPlugin("css/[name].css")
  ]
};
