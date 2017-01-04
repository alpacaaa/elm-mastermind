require('./main.css');

var Elm = require('./Main.elm');
// var Elm = require('./Explain.elm');

var root = document.getElementById('root');

Elm.Main.embed(root);
