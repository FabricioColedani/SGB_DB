import fs from 'fs';
const sql = fs.readFileSync('./src/debugPosiciones.js','utf8');
console.log('Length:', sql.length);
const pos = 1291;
console.log(sql.slice(pos-30, pos+30));
