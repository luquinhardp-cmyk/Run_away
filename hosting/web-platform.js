/* Browser-only presentation and local microphone intensity. No audio upload. */
(() => {
 'use strict';
 const api=window.EcosWeb={portrait:false,hidden:false,resumeRequired:false,micState:'off',micDb:-80,safeX:0,safeY:0,viewportWidth:innerWidth,viewportHeight:innerHeight};
 api.micSupported=!!(isSecureContext&&navigator.mediaDevices?.getUserMedia&&(window.AudioContext||window.webkitAudioContext));
 let enterResolve;window.ECOS_ENTRY_READY=new Promise(resolve=>enterResolve=resolve);
 const style=document.createElement('style');style.textContent=`
 html,body{margin:0!important;width:100%;height:100%;overflow:hidden;background:#070b09;overscroll-behavior:none}
 #canvas{display:block!important;width:100%!important;height:100%!important;touch-action:none}
 #ecos-entry,#ecos-rotate{position:fixed;inset:0;z-index:30;background:#090e0cf5;color:#d3ccba;display:flex;align-items:center;justify-content:center;text-align:center;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);font:18px system-ui}
 #ecos-entry[hidden],#ecos-rotate[hidden]{display:none}
 .ecos-card{max-width:520px;padding:24px}.ecos-card h1{letter-spacing:.14em;font-size:28px}.ecos-card p{line-height:1.5}
 .ecos-button{min-width:56px;min-height:52px;background:#20271f;color:#d3ccba;border:1px solid #706951;border-radius:5px;cursor:pointer;font:16px system-ui;padding:10px 16px;margin:6px}
 #ecos-fullscreen{position:fixed;z-index:12;right:max(16px,env(safe-area-inset-right));top:max(24px,env(safe-area-inset-top));padding:8px;margin:0}
 #ecos-fullscreen svg{width:26px;height:26px;display:block}#ecos-web-note{position:fixed;bottom:max(12px,env(safe-area-inset-bottom));left:20%;right:20%;z-index:31;background:#171c17;color:#ddd3b9;padding:10px;text-align:center;font:14px system-ui;pointer-events:none}
 #ecos-safe{position:fixed;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left);visibility:hidden;pointer-events:none}
 `;document.head.append(style);
 const viewport=document.querySelector('meta[name=viewport]');if(viewport)viewport.content='width=device-width,initial-scale=1,viewport-fit=cover';
 const entry=document.createElement('div');entry.id='ecos-entry';entry.innerHTML='<div class="ecos-card"><h1>ECOS</h1><p>Entre no jogo. A tela cheia e a orientação horizontal serão solicitadas quando o navegador permitir.</p><button class="ecos-button" id="ecos-enter">ENTRAR NO JOGO</button><button class="ecos-button" id="ecos-window">CONTINUAR EM JANELA</button></div>';document.body.append(entry);
 const rotate=document.createElement('div');rotate.id='ecos-rotate';rotate.hidden=true;rotate.innerHTML='<div class="ecos-card"><svg width="100" height="90" viewBox="0 0 100 90" fill="none" stroke="currentColor" stroke-width="3" aria-hidden="true"><rect x="35" y="15" width="30" height="58" rx="5" transform="rotate(-35 50 45)"/><path d="M15 45a35 35 0 0 1 60-24m0-12v15H60M85 45a35 35 0 0 1-60 24m0 12V66h15"/></svg><h1>GIRE SEU CELULAR</h1><p>Este jogo foi desenvolvido para ser jogado na horizontal.</p><p>Se a rotação automática estiver bloqueada, gire o aparelho manualmente.</p></div>';document.body.append(rotate);
 const button=document.createElement('button');button.id='ecos-fullscreen';button.className='ecos-button';button.title='Entrar ou sair da tela cheia';button.setAttribute('aria-label',button.title);button.innerHTML='<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 4H4v8m16-8h8v8M4 20v8h8m8 0h8v-8"/></svg>';document.body.append(button);
 const note=document.createElement('div');note.id='ecos-web-note';note.hidden=true;document.body.append(note);
 const safe=document.createElement('div');safe.id='ecos-safe';document.body.append(safe);
 let noticeTimer;
 function notice(text){note.textContent=text;note.hidden=false;clearTimeout(noticeTimer);noticeTimer=setTimeout(()=>note.hidden=true,4500)}
 api.toggleFullscreen=async()=>{
  try {
   if(document.fullscreenElement){await document.exitFullscreen();return}
   if(!document.documentElement.requestFullscreen){notice('Tela cheia indisponível. Continue jogando nesta janela.');return}
   await document.documentElement.requestFullscreen();
   if(screen.orientation?.lock)try{await screen.orientation.lock('landscape')}catch(_){notice('Gire o aparelho manualmente se necessário.')}
  }catch(_){notice('O navegador recusou a tela cheia. O jogo continua em janela.')}
 };
 button.addEventListener('click',api.toggleFullscreen);
 function enter(fullscreen){entry.hidden=true;if(fullscreen)api.toggleFullscreen();requestAnimationFrame(()=>requestAnimationFrame(enterResolve))}
 document.getElementById('ecos-enter').addEventListener('click',()=>enter(true));
 document.getElementById('ecos-window').addEventListener('click',()=>enter(false));
 function resize(){
  api.viewportWidth=visualViewport?.width||innerWidth;api.viewportHeight=visualViewport?.height||innerHeight;
  document.body.style.height=api.viewportHeight+'px';
  const mobile=matchMedia('(pointer:coarse)').matches||navigator.maxTouchPoints>0;
  api.portrait=mobile&&api.viewportHeight>api.viewportWidth;
  rotate.hidden=!api.portrait;const css=getComputedStyle(safe);
  api.safeX=Math.max(parseFloat(css.paddingLeft)||0,parseFloat(css.paddingRight)||0);
  api.safeY=Math.max(parseFloat(css.paddingTop)||0,parseFloat(css.paddingBottom)||0);
 }
 addEventListener('resize',resize);addEventListener('orientationchange',resize);visualViewport?.addEventListener('resize',resize);document.addEventListener('fullscreenchange',()=>{button.setAttribute('aria-pressed',String(!!document.fullscreenElement));resize()});resize();
 let generation=0,stream=null,context=null,source=null,analyser=null,zero=null,timer=null;
 api.stopMic=()=>{
  generation++;clearInterval(timer);timer=null;
  if(stream)stream.getTracks().forEach(t=>t.stop());stream=null;
  try{source?.disconnect();analyser?.disconnect();zero?.disconnect()}catch(_){}
  if(context)context.close().catch(()=>{});context=null;source=null;analyser=null;zero=null;
  api.micDb=-80;api.micState='off';
 };
 api.startMic=async()=>{
  api.stopMic();const request=++generation;
  if(document.hidden||api.portrait)return;
  if(!isSecureContext||!navigator.mediaDevices?.getUserMedia){api.micState='unavailable';return}
  api.micState='pending';
  try {
   const result=await navigator.mediaDevices.getUserMedia({audio:{echoCancellation:true,noiseSuppression:true,autoGainControl:false},video:false});
   if(request!==generation){result.getTracks().forEach(t=>t.stop());return}
   stream=result;context=new (window.AudioContext||window.webkitAudioContext)();await context.resume();
   if(request!==generation)return;
   source=context.createMediaStreamSource(stream);analyser=context.createAnalyser();analyser.fftSize=1024;
   zero=context.createGain();zero.gain.value=0;source.connect(analyser);analyser.connect(zero);zero.connect(context.destination);
   const samples=new Float32Array(analyser.fftSize);
   api.micState='active';
   for(const track of stream.getTracks())track.addEventListener('ended',()=>{if(request===generation){api.stopMic();api.micState='ended'}});
   timer=setInterval(()=>{if(request!==generation)return;analyser.getFloatTimeDomainData(samples);let sum=0;for(const v of samples)sum+=v*v;api.micDb=Math.max(-80,20*Math.log10(Math.max(1e-8,Math.sqrt(sum/samples.length))))},50);
  }catch(error){if(request===generation){api.stopMic();api.micState=error.name==='NotAllowedError'?'denied':'unavailable'}}
 };
 document.addEventListener('visibilitychange',()=>{api.hidden=document.hidden;if(api.hidden){api.resumeRequired=true;api.stopMic()}});
 addEventListener('pagehide',api.stopMic);
})();
