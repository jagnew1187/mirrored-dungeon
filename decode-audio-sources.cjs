// Build tool only: convert selected Ogg sources to universal mono PCM for DSP.
const fs=require('node:fs'),path=require('node:path');let pw;try{pw=require('playwright')}catch{pw=require(path.resolve(path.dirname(process.execPath),'../node_modules/playwright'))}
(async()=>{const browser=await pw.chromium.launch({headless:true,executablePath:process.env.CHROME_PATH});try{
 const page=await browser.newPage(),manifest=require('./assets/audio/sources.json');fs.mkdirSync('assets/audio/work',{recursive:true});
 for(const [name,file]of Object.entries(manifest)){
  const pcm=await page.evaluate(async base64=>{const bytes=Uint8Array.from(atob(base64),c=>c.charCodeAt(0)),context=new OfflineAudioContext(1,1,44100),buffer=await context.decodeAudioData(bytes.buffer),mono=new Float32Array(buffer.length);for(let channel=0;channel<buffer.numberOfChannels;channel++){const data=buffer.getChannelData(channel);for(let i=0;i<mono.length;i++)mono[i]+=data[i]/buffer.numberOfChannels}return Array.from(mono)},fs.readFileSync('assets/audio/'+file).toString('base64'));
  const wav=Buffer.alloc(44+pcm.length*2);wav.write('RIFF');wav.writeUInt32LE(wav.length-8,4);wav.write('WAVEfmt ',8);wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(44100,24);wav.writeUInt32LE(88200,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(pcm.length*2,40);pcm.forEach((v,i)=>wav.writeInt16LE(Math.round(Math.max(-1,Math.min(1,v))*32767),44+i*2));fs.writeFileSync('assets/audio/work/'+name+'.wav',wav);
 }console.log('Decoded '+Object.keys(manifest).length+' source sounds at 44.1 kHz');
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
