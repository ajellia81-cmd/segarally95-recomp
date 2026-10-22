"""Synthetic bytes only. Tests the same ZIP importer used on iPhone."""
import pathlib,struct,subprocess,sys,tempfile,zipfile
exe=sys.argv[1]
names=['epr-17888b.12','epr-17889b.13','mpr-17746.10','mpr-17747.11','mpr-17744.8','mpr-17745.9','mpr-17884.6','mpr-17885.7']
with tempfile.TemporaryDirectory() as tmp:
 root=pathlib.Path(tmp)
 def run(path,ok):
  out=root/('out'+str(len(list(root.iterdir()))));out.mkdir()
  p=subprocess.run([exe,str(path),str(out),'synthetic'],capture_output=True,text=True)
  assert (p.returncode==0)==ok,(p.returncode,p.stderr)
  return out
 for method in [zipfile.ZIP_STORED,zipfile.ZIP_DEFLATED]:
  archive=root/f'valid{method}.zip'
  with zipfile.ZipFile(archive,'w',compression=method) as z:
   for i,name in enumerate(names):z.writestr(('srallycb/' if i<2 else '')+name,bytes([i,1,2,3]))
   z.writestr('epr-17888c.12',b'NOT B')
  out=run(archive,True)
  assert (out/'maincpu_deinterleaved.bin').read_bytes()==bytes([0,1,1,1,2,3,2,3])
  assert (out/'main_data_deinterleaved.bin').stat().st_size==24
  data=bytearray(archive.read_bytes());data[0]=0
  bad=root/f'bad-local{method}.zip';bad.write_bytes(data);run(bad,False)
  bad=root/f'truncated{method}.zip';bad.write_bytes(archive.read_bytes()[:-8]);run(bad,False)
 for case in ['missing','wrong-crc','traversal','symlink','oversize']:
  archive=root/(case+'.zip')
  with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as z:
   for i,name in enumerate(names):
    if case=='missing' and i==0:continue
    path=('../'+name) if case=='traversal' and i==0 else name
    info=zipfile.ZipInfo(path)
    if case=='symlink' and i==0:info.create_system=3;info.external_attr=0o120777<<16
    data=bytes([i,1,2,3])
    if case=='wrong-crc' and i==0:data=b'FAIL'
    if case=='oversize' and i==0:data*=2
    z.writestr(info,data)
  run(archive,False)
print('Stored/deflated merged ZIP, interleave order, missing/CRC/bounds/traversal/symlink rejection passed')
