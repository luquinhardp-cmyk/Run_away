const path=require('path'),fs=require('fs'),http=require('http');
const {chromium,firefox}=require(process.env.PLAYWRIGHT_MODULE||path.resolve(__dirname,'../../.tools/browser/node_modules/playwright'));
const qaMode=process.argv.includes('--qa');
const directMode=process.argv.includes('--direct'),micTest=process.argv.includes('--microphone');
const desktopMode=process.argv.includes('--desktop');
const root=process.env.GAME_SMOKE_SITE?path.resolve(process.env.GAME_SMOKE_SITE):path.resolve(__dirname,qaMode?'../builds/tutorial-ui-qa/site':'../builds/tutorial-ui/site'),out=process.env.GAME_SMOKE_REPORTS?path.resolve(process.env.GAME_SMOKE_REPORTS):path.resolve(__dirname,'../docs/review/tutorial-ui');
fs.mkdirSync(out,{recursive:true});
const testResultPattern=/^(TUTORIAL|MACABRE|HORROR|STABILITY|STAGED) RESULT /;
const port=Number(process.env.GAME_SMOKE_PORT||8793);
const server=http.createServer((req,res)=>{
 const pathname=new URL(req.url,'http://localhost').pathname;
 const file=path.join(root,pathname.endsWith('/')?pathname+'index.html':pathname);
 if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return}
 fs.readFile(file,(err,data)=>{if(err){res.writeHead(404);res.end();return}res.setHeader('Content-Type',file.endsWith('.js')?'text/javascript':file.endsWith('.html')?'text/html':'application/octet-stream');res.end(data)});
});
(async()=>{
 await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,'127.0.0.1',resolve)});
 const results=[];
 try {
 const browserName=process.argv.slice(2).find(x=>!x.startsWith('--'));
 for(const name of (browserName?[browserName]:['chromium','firefox'])){
  let browser,qaFinished=false;const logs=[],errors=[],runtimeErrors=[],shutdownErrors=[];const result={browser:name,physicalDevice:false};
  try {
   browser=name==='firefox'?await firefox.launch({headless:true,firefoxUserPrefs:{'webgl.force-enabled':true}}):await chromium.launch({headless:true,args:['--use-angle=d3d11','--enable-webgl','--ignore-gpu-blocklist',...(micTest?['--use-fake-device-for-media-stream','--use-fake-ui-for-media-stream']:[])]});
   const page=await browser.newPage({viewport:{width:960,height:540},hasTouch:!desktopMode});
   const tap=(x,y)=>desktopMode?page.mouse.click(x,y):page.touchscreen.tap(x,y);
   page.on('console',m=>{logs.push(m.text());if(testResultPattern.test(m.text()))qaFinished=true;if(m.type()==='error'){errors.push(m.text());(qaFinished?shutdownErrors:runtimeErrors).push(m.text())}});page.on('pageerror',e=>{errors.push(e.message);(qaFinished?shutdownErrors:runtimeErrors).push(e.message)});
   const ready=page.waitForEvent('console',{predicate:m=>m.text().includes('Build configuration:'),timeout:120000});
   const qaDone=qaMode?page.waitForEvent('console',{predicate:m=>testResultPattern.test(m.text()),timeout:180000}):null;
   ready.catch(()=>{});if(qaDone)qaDone.catch(()=>{});
   await page.goto('http://127.0.0.1:'+port+'/play/',{waitUntil:'domcontentloaded'});
   if(await page.locator('#ecos-window').count()){
    if(qaMode)await page.locator('#ecos-window').evaluate(button=>button.click());
    else await page.locator('#ecos-window').click();
   }
   await ready;if(qaMode)await tap(20,20);await page.waitForTimeout(2200);
   if(qaMode){
    result.testResult=(await qaDone).text();await page.waitForTimeout(400);
    result.completed=true;result.errors=errors;result.runtimeErrors=runtimeErrors;result.shutdownErrors=shutdownErrors;result.qaMode=true;
    result.expectedWarnings=logs.includes('EXPECTED_DIAGNOSTIC fall_recovery_no_verified_floor')?runtimeErrors.filter(t=>t.startsWith('WARNING: Fall recovery: no verified clear floor')||t.includes('at: push_warning (core/variant/variant_utility.cpp:')):[];
    result.unexpectedRuntimeErrors=runtimeErrors.filter(t=>!result.expectedWarnings.includes(t));
    fs.writeFileSync(path.join(out,name+'-qa.log'),logs.join('\n'));
    fs.writeFileSync(path.join(out,name+'-qa.json'),JSON.stringify(result,null,2));
    fs.writeFileSync(path.join(out,'browser-results.json'),JSON.stringify([result],null,2));
    console.log(JSON.stringify({browser:name,result:result.testResult,errors:errors.length}));
    if(result.unexpectedRuntimeErrors.length||!result.testResult.includes('0 failed'))process.exitCode=1;
    continue;
   }
   await tap(480,210);await page.waitForTimeout(500);
   await page.screenshot({path:path.join(out,name+'-new-game.png')});
   await tap(480,directMode?197:145);await page.waitForTimeout(500);
   await page.screenshot({path:path.join(out,name+'-consent.png')});
   const levelReady=page.waitForEvent('console',{predicate:m=>m.text().startsWith('ECOS_LEVEL_READY '),timeout:120000});levelReady.catch(()=>{});
   await tap(480,274);await levelReady;await page.waitForTimeout(1000);
   result.directMode=directMode;
   if(micTest){
    await page.evaluate(()=>{const get=navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);navigator.mediaDevices.getUserMedia=async constraints=>{const s=await get(constraints);window.smokeMicTracks=s.getTracks();return s}});
    await tap(710,40);await page.waitForFunction(()=>window.EcosWeb?.micState==='active',{timeout:30000});
    await page.waitForTimeout(3500);await page.screenshot({path:path.join(out,name+'-mic-active.png')});
    await tap(710,40);await page.waitForFunction(()=>EcosWeb.micState==='off');
    result.hudMicrophoneTracksStopped=await page.evaluate(()=>smokeMicTracks.every(t=>t.readyState==='ended'));
    if(!result.hudMicrophoneTracksStopped)throw Error('HUD microphone failed to release tracks');
   }
   if(desktopMode){await page.mouse.click(480,300);await page.waitForFunction(()=>!!document.pointerLockElement);result.desktopPointerLock=true;}
   const sampleFrames=()=>page.evaluate(()=>new Promise(resolve=>{const frames=[];let last=performance.now(),start=last;function tick(now){frames.push(now-last);last=now;if(now-start<2000){requestAnimationFrame(tick);return}frames.sort((a,b)=>a-b);resolve({samples:frames.length,meanMs:frames.reduce((a,b)=>a+b,0)/frames.length,p95Ms:frames[Math.floor(frames.length*.95)],maxMs:frames.at(-1),metric:'browser requestAnimationFrame; not GPU timing'})}requestAnimationFrame(tick)}));
   result.gameplayFrames=await sampleFrames();
   await page.screenshot({path:path.join(out,name+'-tutorial.png')});
   if(desktopMode)await page.keyboard.press('Tab');else await tap(698,495);
   await page.waitForTimeout(1000);
   if(desktopMode&&await page.evaluate(()=>!!document.pointerLockElement))throw Error('Backpack did not release desktop pointer lock');
   result.backpackFrames=await sampleFrames();
   await page.screenshot({path:path.join(out,name+'-backpack.png')});
   await page.keyboard.press('Escape');await page.waitForTimeout(700);
   await page.screenshot({path:path.join(out,name+'-closed.png')});
   if(micTest&&!desktopMode){
    await page.setViewportSize({width:540,height:960});await page.waitForTimeout(400);
    result.portraitOverlay=await page.locator('#ecos-rotate').isVisible();
    await page.screenshot({path:path.join(out,name+'-portrait.png')});
    await page.setViewportSize({width:960,height:540});await page.waitForTimeout(400);
    result.landscapeOverlayHidden=await page.locator('#ecos-rotate').isHidden();
    if(!result.portraitOverlay||!result.landscapeOverlayHidden)throw Error('Orientation fallback failed');
   }
   result.storage=await page.evaluate(async()=>{
    const rows=[];for(const item of await indexedDB.databases()){
     const db=await new Promise((resolve,reject)=>{let r=indexedDB.open(item.name);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});
     for(const store of db.objectStoreNames){const keys=await new Promise((resolve,reject)=>{let r=db.transaction(store).objectStore(store).getAllKeys();r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)});rows.push({database:item.name,store,keys})}db.close()
    }return rows;
   });
   result.tutorialPersisted=result.storage.some(x=>x.keys.some(k=>String(k).endsWith('/tutorial.json')));
   const reloaded=page.waitForEvent('console',{predicate:m=>m.text().includes('Build configuration:'),timeout:120000});
   reloaded.catch(()=>{});
   await page.reload({waitUntil:'domcontentloaded'});
   if(await page.locator('#ecos-window').count())await page.locator('#ecos-window').click();
   await reloaded;await page.waitForTimeout(2500);
   await page.screenshot({path:path.join(out,name+'-resume-menu.png')});
   result.completed=true;result.ua=await page.evaluate(()=>navigator.userAgent);
  }catch(e){result.completed=false;result.failure=e.message}
  finally{if(browser)await browser.close()}
  result.errors=errors;results.push(result);
  fs.writeFileSync(path.join(out,name+'-browser.log'),logs.join('\n'));
  fs.writeFileSync(path.join(out,'browser-results.json'),JSON.stringify(results,null,2));
  console.log(JSON.stringify({browser:name,completed:result.completed,errors:errors.length,tutorialPersisted:result.tutorialPersisted,failure:result.failure}));
  if(!result.completed||errors.length)process.exitCode=1;
 }
 }finally{server.close()}
})().catch(e=>{console.error(e);server.close();process.exitCode=1});
