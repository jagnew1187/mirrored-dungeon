"""Extract only selected CC0 Foley sources; never downloads at build time."""
import json, zipfile
from pathlib import Path
root=Path(__file__).resolve().parent/'assets/audio'
selection={
 'rpg':['knifeSlice','knifeSlice2','drawKnife1','drawKnife2','cloth1','cloth2','chop','creak1','creak2','metalClick'],
 'impact':[f'{kind}_{i:03}' for kind in ['impactMetal_medium','impactMetal_heavy','impactPunch_heavy','impactWood_medium','impactWood_heavy','impactMining','impactGlass_light','impactGlass_heavy','impactSoft_medium','footstep_grass','footstep_concrete','footstep_carpet'] for i in range(2)]
}
manifest={}
for pack,names in selection.items():
 folder=root/'source'/('kenney-'+pack);folder.mkdir(parents=True,exist_ok=True)
 with zipfile.ZipFile(root/'source'/('kenney-'+pack+'.zip')) as archive:
  (folder/'License.txt').write_bytes(archive.read('License.txt'))
  for name in names:
   output=folder/(name+'.ogg');output.write_bytes(archive.read('Audio/'+name+'.ogg'));manifest[name]=str(output.relative_to(root)).replace('\\','/')
(root/'sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Selected',len(manifest),'original CC0 audio sources')
