const { Resvg } = require('@resvg/resvg-js');
const fs = require('fs');
const path = require('path');

const buildDir = __dirname;
const svg = fs.readFileSync(path.join(buildDir, 'icon.svg'));
const resvg = new Resvg(svg, {
  fitTo: { mode: 'width', value: 1024 },
  background: 'rgba(0,0,0,0)', // fully transparent
});
const png = resvg.render().asPng();
fs.writeFileSync(path.join(buildDir, 'icon.png'), png);
console.log('rendered icon.png', png.length, 'bytes');
