const path=require('path'),fs=require('fs'),http=require('http');
const {chromium,firefox}=require(process.env.PLAYWRIGHT_MODULE||path.resolve(__dirname,'../../.tools/browser/node_modules/playwright'));
const root=path.resolve(__dirname,'../builds/web-audit/release'),out=path.resolve(__dirname,'../docs/review/web-audit');
const server=http.createServer((req,res)=>{
 const pathname=new URL(req.url,'http://localhost').pathname;
 const file=path.join(root,pathname.endsWith('/')?pathname+'index.html':pathname);
 if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return}
 fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);res.end();return}res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':'application/octet-stream');res.end(data)});
});
(async()=>{
 await new Promise(r=>server.listen(8791,'127.0.0.1',r));
 const results=[];
 try{
 for(const name of ['chrome','edge','firefox']){
  let browser;const logs=[],errors=[];const result={browser:name};
  try{
   browser=name==='firefox'?await firefox.launch({headless:true,firefoxUserPrefs:{'webgl.force-enabled':true}}):await chromium.launch({headless:true,executablePath:name==='chrome'?'C:/Program Files/Google/Chrome/Application/chrome.exe':'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',args:['--use-angle=d3d11','--enable-webgl','--ignore-gpu-blocklist']});
   const page=await browser.newPage({viewport:{width:960,height:540}});
   page.on('console',m=>{logs.push(m.text());if(m.type()==='error')errors.push(m.text())});
   page.on('pageerror',e=>errors.push(e.message));
   const ready=page.waitForEvent('console',{predicate:m=>m.text().includes('Build configuration:'),timeout:90000});
   const began=Date.now();await page.goto('http://127.0.0.1:8791/play/',{waitUntil:'domcontentloaded'});await ready;await page.waitForTimeout(2200);
   result.engineBootMs=Date.now()-began;
   await page.mouse.click(480,210);await page.waitForTimeout(900);await page.mouse.click(480,274);
   await page.waitForTimeout(22000);
   await page.keyboard.press('Escape');await page.waitForTimeout(1500);
   await page.screenshot({path:path.join(out,name+'-release-pause.png'),timeout:30000});
   result.storage=await page.evaluate(async()=>{
    const names=await indexedDB.databases();const data=[];
    for(const item of names){
     const db=await new Promise((resolve,reject)=>{const req=indexedDB.open(item.name);req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error)});
     for(const store of db.objectStoreNames){
      const keys=await new Promise((resolve,reject)=>{const req=db.transaction(store).objectStore(store).getAllKeys();req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error)});
      data.push({database:item.name,store,keys});}db.close();
    }return data;
   });
   result.checkpointPersisted=result.storage.some(d=>d.keys.some(k=>String(k).endsWith('/checkpoint.json')));
   const reloaded=page.waitForEvent('console',{predicate:m=>m.text().includes('Build configuration:'),timeout:90000});
   await page.reload({waitUntil:'domcontentloaded'});await reloaded;await page.waitForTimeout(2500);
   await page.screenshot({path:path.join(out,name+'-release-reload.png'),timeout:30000});
   result.completed=true;result.ua=await page.evaluate(()=>navigator.userAgent);
  }catch(error){result.completed=false;result.failure=error.message}
  finally{if(browser)await browser.close()}
  result.errors=errors;results.push(result);fs.writeFileSync(path.join(out,name+'-release.log'),logs.join('\n'));fs.writeFileSync(path.join(out,'release-browsers.json'),JSON.stringify(results,null,2));console.log(JSON.stringify({browser:name,completed:result.completed,errors:errors.length,checkpointPersisted:result.checkpointPersisted,failure:result.failure}));
 }
 }finally{server.close()}
})().catch(e=>{console.error(e);server.close();process.exitCode=1});
