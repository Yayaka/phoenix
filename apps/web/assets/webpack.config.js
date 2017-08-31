var path = require("path");
module.exports = {
  entry: {
    app: "./js/app",
    userAttributes: "./js/userAttributes"
  },
  output: {
    path: path.join(__dirname, "../priv/static/js"),
    filename: "[name].js"
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
      }
    ]
  }
};
