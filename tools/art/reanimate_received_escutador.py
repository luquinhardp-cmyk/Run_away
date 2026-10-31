"""Re-author action data against the saved rig, keeping sculpt and weights intact."""
import bpy,math,json
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2]
source=ROOT/'assets/source/received_escutador/escutador_refined.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
rig=bpy.data.objects['Received_Escutador'];body=bpy.data.objects['Received_Escutador_SkinnedMesh']
bones={b.name:(b.head_local.copy(),b.tail_local.copy()) for b in rig.data.bones}
rig.animation_data_clear()
for action in list(bpy.data.actions):bpy.data.actions.remove(action,do_unlink=True)
def activate(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
exec((ROOT/'tools/art/animate_received_escutador.py').read_text(),globals())
rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
manifest=ROOT/'assets/models/escutador_received_manifest.json';data=json.loads(manifest.read_text());data['clips']=[{'name':n,'duration':d,'loop':l} for n,d,l in clips];data['nominal_stance_speed_mps']={'patrol':1.533333,'chase':3.333333};manifest.write_text(json.dumps(data,indent=2))
