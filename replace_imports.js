const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            if (!file.includes('.dart_tool') && !file.includes('build') && !file.includes('.git')) {
                results = results.concat(walk(file));
            }
        } else {
            if (file.endsWith('.dart') || file.endsWith('.patch')) {
                results.push(file);
            }
        }
    });
    return results;
}

const files = walk('.');
let count = 0;
files.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    if (content.includes('package:oasis_v2/')) {
        const newContent = content.replace(/package:oasis_v2\//g, 'package:oasis/');
        fs.writeFileSync(file, newContent, 'utf8');
        count++;
    }
});
console.log(`Updated ${count} files.`);
