"""Blender: bind the user's GLB, preserve its silhouette/colors, author actual clips."""
import bpy, math, json, hashlib, shutil
from pathlib import Path
from mathutils import Vector, Matrix
from mathutils.kdtree import KDTree
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'assets/source/macabre_escutador'; SRC.mkdir(parents=True,exist_ok=True)
incoming=Path('C:/Users/DANF/Downloads/Escutador_Monstro_3D.glb')
shutil.copy2(incoming,SRC/incoming.name)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(incoming))
parts=[o for o in bpy.context.scene.objects if o.type=='MESH']
S=2.55/3.673
def activate(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
for o in parts:
 world=o.matrix_world.copy();o.parent=None;o.matrix_world=world
 activate(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 for v in o.data.vertices:v.co*=S
floor=min(v.co.z for o in parts for v in o.data.vertices)
for o in parts:
 for v in o.data.vertices:v.co.z-=floor
# Join/remesh intersecting body pieces before skinning. Otherwise an elbow bend
# exposes the uncapped ends of the source's separate primitive segments.
input_meshes=len(parts)
skin_parts=[o for o in parts if not any(t in o.name for t in ['ear','fang','claw','jaw','drool','eye','mouth_dark'])]
samples=[]
for o in skin_parts:
 attr=o.data.color_attributes.active_color
 if attr:
  for poly in o.data.polygons:
   for li in poly.loop_indices:
    vi=o.data.loops[li].vertex_index
    samples.append((o.data.vertices[vi].co.copy(),tuple(attr.data[li if attr.domain=='CORNER' else vi].color)))
tree=KDTree(len(samples))
for i,(co,col) in enumerate(samples):tree.insert(co,i)
tree.balance()
activate(skin_parts[0])
for o in skin_parts:o.select_set(True)
bpy.ops.object.join();skin=bpy.context.object;skin.name='Continuous_Body_Skin'
remesh=skin.modifiers.new('Continuous joint anatomy','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.014;remesh.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=remesh.name)
sm=skin.modifiers.new('Smooth fused transitions','SMOOTH');sm.factor=.7;sm.iterations=3;bpy.ops.object.modifier_apply(modifier=sm.name)
dec=skin.modifiers.new('Body triangle budget','DECIMATE');dec.ratio=min(1,19000/max(1,sum(len(p.vertices)-2 for p in skin.data.polygons)));bpy.ops.object.modifier_apply(modifier=dec.name)
for attr in list(skin.data.color_attributes):skin.data.color_attributes.remove(attr)
attr=skin.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='POINT')
for v in skin.data.vertices:
 co,index,d=tree.find(v.co);attr.data[v.index].color=samples[index][1]
parts=[o for o in bpy.context.scene.objects if o.type=='MESH']
def point(x,y,z):return Vector((x,-z,y))*S-Vector((0,0,floor))
arm=bpy.data.armatures.new('MacabreRig');rig=bpy.data.objects.new('MacabreEscutador',arm);bpy.context.collection.objects.link(rig)
activate(rig);bpy.ops.object.mode_set(mode='EDIT');bones={}
def bone(name,a,b,parent=None):
 a,b=point(*a),point(*b);bo=arm.edit_bones.new(name);bo.head=a;bo.tail=b
 if parent:bo.parent=arm.edit_bones[parent]
 bones[name]=(a,b)
bone('root',(0,0,0),(0,.2,0));bone('hips',(0,1.05,.17),(0,1.4,.2),'root')
bone('spine',(0,1.4,.2),(0,1.9,.22),'hips');bone('chest',(0,1.9,.22),(0,2.4,.15),'spine')
bone('neck',(0,2.4,.15),(0,2.77,-.4),'chest');bone('head',(0,2.77,-.4),(0,3.12,-.55),'neck')
bone('jaw',(0,2.45,-.55),(0,2.23,-.87),'head')
for side,s in [('L',-1),('R',1)]:
 bone('upper_arm_'+side,(s*.43,2.25,.1),(s*.78,1.58,-.12),'chest')
 bone('forearm_'+side,(s*.78,1.58,-.12),(s*.99,.80,-.45),'upper_arm_'+side)
 bone('hand_'+side,(s*.99,.80,-.45),(s*1.02,.52,-.48),'forearm_'+side)
 for i in range(4):
  x=s*1.02+(i-1.5)*.10
  bone('finger_'+str(i)+'_'+side,(x,.52,-.48),(x+s*.04,.16,-.65),'hand_'+side)
 bone('thigh_'+side,(s*.26,1.12,.08),(s*.66,.70,-.5),'hips')
 bone('shin_'+side,(s*.66,.70,-.5),(s*.47,.14,-.10),'thigh_'+side)
 bone('foot_'+side,(s*.47,.14,-.10),(s*.47,.08,-.61),'shin_'+side)
 bone('ear_'+side,(s*.22,2.98,-.25),(s*.85,3.35,-.25),'head')
bpy.ops.object.mode_set(mode='OBJECT')
materials={}
for name,rough in [('Skin',.78),('Cartilage',.63),('Keratin',.49),('Mouth',.42)]:
 m=bpy.data.materials.new('Received_Macabre_'+name);m.use_nodes=True
 nt=m.node_tree;p=nt.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=rough
 vc=nt.nodes.new('ShaderNodeVertexColor');vc.layer_name='Color';nt.links.new(vc.outputs['Color'],p.inputs['Base Color'])
 if name in ['Skin','Cartilage']:
  tex=nt.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT/'assets/textures/escutador_received/skin_normal.png'),check_existing=True)
  tex.image.colorspace_settings.name='Non-Color';normal=nt.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.38
  nt.links.new(tex.outputs['Color'],normal.inputs['Color']);nt.links.new(normal.outputs['Normal'],p.inputs['Normal'])
 materials[name]=m
def distance(v,n):
 a,b=bones[n];d=b-a;t=max(0,min(1,(v-a).dot(d)/d.length_squared));return (v-a-d*t).length
for o in parts:
 name=o.name;center=sum((v.co for v in o.data.vertices),Vector())/len(o.data.vertices)
 side='L' if center.x<0 else 'R'; fixed=None
 if 'ear' in name:fixed='ear_'+side;material='Cartilage'
 elif any(t in name for t in ['fang','claw']):material='Keratin'
 elif 'mouth_dark' in name:material='Mouth';fixed='head'
 elif any(t in name for t in ['jaw','drool']):material='Cartilage';fixed='jaw' if ('lower_jaw' in name or 'drool' in name) else 'head'
 else:material='Skin'
 if any(t in name for t in ['skull','forehead','eye','upper_jaw','ivory_fang']):fixed='head'
 if 'ivory_fang' in name and center.z<2.5*S:fixed='jaw'
 if 'toe' in name or 'wide_foot' in name:fixed='foot_'+side
 if any(t in name for t in ['long_finger','black_claw']):
  index=min(range(4),key=lambda i:distance(center,'finger_'+str(i)+'_'+side));fixed='finger_'+str(index)+'_'+side
 if 'knuckle_palm' in name:fixed='hand_'+side
 o.data.materials.clear();o.data.materials.append(materials[material])
 # Blender join otherwise drops colors from pieces whose attribute domain/type
 # differs from the remeshed body's FLOAT_COLOR/POINT attribute.
 if o.data.color_attributes:
  old=o.data.color_attributes.active_color or o.data.color_attributes[0]
  values=[None]*len(o.data.vertices)
  if old.domain=='POINT':values=[tuple(c.color) for c in old.data]
  else:
   for loop in o.data.loops:values[loop.vertex_index]=tuple(old.data[loop.index].color)
  for attr in list(o.data.color_attributes):o.data.color_attributes.remove(attr)
  attr=o.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='POINT')
  for i,col in enumerate(values):attr.data[i].color=col or (.35,.24,.20,1)
  o.data.color_attributes.active_color=attr
 for poly in o.data.polygons:poly.use_smooth=True
 activate(o);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.015);bpy.ops.object.mode_set(mode='OBJECT')
 if fixed:
  g=o.vertex_groups.new(name=fixed);g.add(list(range(len(o.data.vertices))),1,'REPLACE')
 else:
  if 'long_arm' in name:candidates=['upper_arm_'+side,'forearm_'+side,'hand_'+side]
  elif 'bent_leg' in name:candidates=['thigh_'+side,'shin_'+side,'foot_'+side]
  elif name=='Continuous_Body_Skin':candidates=[n for n in bones if n not in ['root','jaw'] and not n.startswith('ear_')]
  else:candidates=['hips','spine','chest','neck','head']
  groups={n:o.vertex_groups.new(name=n) for n in candidates}
  for v in o.data.vertices:
   near=sorted((distance(v.co,n),n) for n in candidates)[:3];weights=[1/max(.025,d)**4 for d,n in near];total=sum(weights)
   for (d,n),w in zip(near,weights):groups[n].add([v.index],w/total,'REPLACE')
activate(parts[0])
for o in parts:o.select_set(True)
bpy.ops.object.join();body=bpy.context.object;body.name='Macabre_SkinnedMesh'
bpy.ops.object.material_slot_remove_unused();mod=body.modifiers.new('Skin deformation','ARMATURE');mod.object=rig;body.parent=rig
# Reuse the action vocabulary and analytic stance IK; positions use this model's rig.
exec((ROOT/'tools/art/animate_received_escutador.py').read_text(),globals())
rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(0)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'escutador_macabre.blend'))
activate(body);rig.select_set(True)
export=dict(export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True,export_materials='EXPORT',export_cameras=False,export_lights=False)
out=ROOT/'assets/models';triangles=sum(len(p.vertices)-2 for p in body.data.polygons)
bpy.ops.export_scene.gltf(filepath=str(out/'escutador_macabre.glb'),**export)
activate(body);mod=body.modifiers.new('Android reduction','DECIMATE');mod.ratio=.55;bpy.ops.object.modifier_move_up(modifier=mod.name);bpy.ops.object.modifier_apply(modifier=mod.name);rig.select_set(True)
low_triangles=sum(len(p.vertices)-2 for p in body.data.polygons)
bpy.ops.export_scene.gltf(filepath=str(out/'escutador_macabre_low.glb'),**export)
report=dict(input_sha256=hashlib.sha256(incoming.read_bytes()).hexdigest(),input_meshes=input_meshes,triangles=triangles,triangles_low=low_triangles,bones=len(bones),clips=[dict(name=n,duration=d,loop=l) for n,d,l in clips],source='assets/source/macabre_escutador/escutador_macabre.blend',limitations=['Original GLB has vertex colors, no scanned skin textures','Authored animation with analytic leg IK, not motion capture','Body voxel union and decimation, not manually authored deformation loops','Physical Android and iOS performance not measured'])
(out/'escutador_macabre_manifest.json').write_text(json.dumps(report,indent=2));print('MACABRE_COMPLETE',json.dumps(report),flush=True)
