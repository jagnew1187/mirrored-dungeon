const http=require('node:http'),fs=require('node:fs'),path=require('node:path');
const port=Number(process.env.PORT)||4173;
http.createServer((req,res)=>{
 if(req.method!=='GET'||!['/','/index.html'].includes(req.url.split('?')[0])){res.writeHead(404);res.end('Not found');return}
 res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'});
 fs.createReadStream(path.join(__dirname,'index.html')).pipe(res);
}).listen(port,'127.0.0.1',()=>console.log('Mirrored Dungeon: http://127.0.0.1:'+port));
