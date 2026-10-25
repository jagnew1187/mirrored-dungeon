module.exports=html=>{
 html=html.replace('window.MirroredDungeonDebug={selectedMouseEnemy,','window.MirroredDungeonDebug={audio:GameAudio,selectedMouseEnemy,');
 html=html.replace('function renderAll(){if(!s)return;renderRewardStatus();','function renderAll(){if(!s)return;GameAudio.sync();renderRewardStatus();');
 html=html.replace('function renderAll(){if(!s)return;renderPracticeCamp();','function renderAll(){if(!s)return;GameAudio.sync();renderPracticeCamp();');
 html=html.replace('drawEnvironment();drawMouseSelection();drawEntities();ctx.restore()', 'drawEnvironment();drawEnvironmentalLife();drawMouseSelection();drawEntities();drawBossArrival();ctx.restore()');
 if(!html.includes('updateImmersion(dt);\n  // Rival'))html=html.replace('  // Rival is deliberately', '  updateImmersion(dt);\n  // Rival is deliberately');
 return html;
};
