"""Read the supplied GLB without executing the supplied generator."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets/source/received_escutador/Escutador_Criatura_Original.glb'
OUT=ROOT/'docs/review/escutador_received'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
report=[]
for o in objects:
 points=[o.matrix_world@Vector(c) for c in o.bound_box]
 report.append({'name':o.name,'vertices':len(o.data.vertices),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'uv':len(o.data.uv_layers),'min':[min(p[i] for p in points) for i in range(3)],'max':[max(p[i] for p in points) for i in range(3)]})
audit={'sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'mesh_count':len(objects),'triangles':sum(o['triangles'] for o in report),'armatures':len([o for o in bpy.context.scene.objects if o.type=='ARMATURE']),'actions':len(bpy.data.actions),'objects':report}
(OUT/'input_audit.json').write_text(json.dumps(audit,indent=2))
scene=bpy.context.scene;scene.render.engine='BLENDER_WORKBENCH';scene.render.resolution_x=900;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.display.shading.light='STUDIO';scene.display.shading.color_type='VERTEX';scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True
scene.display.shading.background_type='WORLD';scene.world.color=(.055,.055,.055)
def shot(name,position,target,scale):
 bpy.ops.object.camera_add(location=position);camera=bpy.context.object;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=scale;scene.camera=camera;scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
shot('original_front',(3,8,2.1),(0,0,1.75),3.9)
shot('original_face',(1,5,3.1),(0,.25,3.02),1.25)
print('INPUT_AUDIT',json.dumps({k:v for k,v in audit.items() if k!='objects'}))
