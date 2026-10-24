const http=require('node:http'),fs=require('node:fs'),path=require('node:path');
const port=Number(process.env.PORT)||4173;
http.createServer((req,res)=>{
 const url=req.url.split('?')[0],asset=/^\/runtime-assets\/[a-z0-9-]+\.js$/.test(url),page=['/','/index.html'].includes(url);
 if(req.method!=='GET'||!page&&!asset){res.writeHead(404);res.end('Not found');return}
 const file=page?'index.html':url.slice(1),full=path.join(__dirname,file);
 if(!fs.existsSync(full)){res.writeHead(404);res.end('Not found');return}
 res.writeHead(200,{'Content-Type':asset?'text/javascript; charset=utf-8':'text/html; charset=utf-8','Cache-Control':'no-store'});
 fs.createReadStream(full).pipe(res);
}).listen(port,'127.0.0.1',()=>console.log('Mirrored Dungeon: http://127.0.0.1:'+port));
