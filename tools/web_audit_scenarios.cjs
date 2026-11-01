const {chromium}=require(process.env.PLAYWRIGHT_MODULE || require('path').resolve(__dirname,'../../.tools/browser/node_modules/playwright'));
const fs=require('fs'),http=require('http'),path=require('path');
const root=process.env.GAME_SMOKE_SITE?path.resolve(process.env.GAME_SMOKE_SITE):path.resolve(__dirname,'../builds/web-audit/site');
const out=process.env.GAME_SMOKE_REPORTS?path.resolve(process.env.GAME_SMOKE_REPORTS):path.resolve(__dirname,'../docs/review/web-audit');
fs.mkdirSync(out,{recursive:true});
const server=http.createServer((req,res)=>{
 const pathname=new URL(req.url,'http://localhost').pathname;
 const file=path.join(root,pathname.endsWith('/')?pathname+'index.html':pathname);
 if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return}
 fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);res.end();return}
 if(file.endsWith('.html'))data=Buffer.from(data.toString().replace('"args":[]','"args":["--","--label","web-after","--steady","15","--quality","1"]'));
 res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':'application/octet-stream');res.end(data)});
});
(async()=>{
 await new Promise(r=>server.listen(8790,'127.0.0.1',r));
 const browser=await chromium.launch({headless:true,args:['--use-angle=d3d11','--enable-webgl','--ignore-gpu-blocklist']});
 try{
 const page=await browser.newPage({viewport:{width:960,height:540}});
 const logs=[],errors=[];
 let resolveDone;const done=new Promise(r=>resolveDone=r);
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{
  const t=m.text();logs.push(t);
  if(m.type()==='error')errors.push(t);
  if(t.startsWith('WEB_STARTUP_JSON '))fs.writeFileSync(path.join(out,'startup.json'),JSON.stringify(JSON.parse(t.slice(17)),null,2));
  if(t.startsWith('WEB_AUDIT_JSON ')){
   const report=JSON.parse(t.slice(15));
   fs.writeFileSync(path.join(out,'scenarios.json'),JSON.stringify(report,null,2));
   if(report.complete)resolveDone(report);
  }
  if(t.startsWith('BENCH ')||t.startsWith('WEB_STARTUP'))console.log(t);
 });
 await page.goto('http://127.0.0.1:8790/play/',{waitUntil:'domcontentloaded'});
 if(await page.locator('#ecos-window').count())await page.locator('#ecos-window').evaluate(button=>button.click());
 await page.mouse.click(30,30);
 let timer; const report=await Promise.race([done,new Promise((_,reject)=>timer=setTimeout(()=>reject(Error('Web benchmark timeout')),240000))]);clearTimeout(timer);
 fs.writeFileSync(path.join(out,'scenarios.log'),logs.join('\n'));
 fs.writeFileSync(path.join(out,'scenarios-errors.json'),JSON.stringify(errors,null,2));
 console.log('SCENARIOS',report.results.length,'ERRORS',errors.length,'LOAD_MS',report.load_ms);
 }finally{await browser.close();server.close()}
})().catch(e=>{console.error(e);server.close();process.exitCode=1});
