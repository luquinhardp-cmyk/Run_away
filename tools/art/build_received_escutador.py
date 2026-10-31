"""Blender refinement of the supplied mesh. Not a claim of final photorealism."""
import bpy,math,json,hashlib,faulthandler
faulthandler.dump_traceback_later(120,repeat=True)
import numpy as np
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/'assets/source/received_escutador'
OUT=ROOT/'assets/models'
TEX=ROOT/'assets/textures/escutador_received';TEX.mkdir(parents=True,exist_ok=True)
S=.74
def point(x,y,z): return Vector((x,-z,y))*S+Vector((0,0,.012))
def activate(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def image_save(name,values,size):
 image=bpy.data.images.new(name,width=size,height=size,alpha=True)
 image.colorspace_settings.name='Non-Color';image.pixels.foreach_set(values.astype(np.float32).ravel());image.filepath_raw=str(TEX/(name+'.png'));image.file_format='PNG';image.save();return image
def textures():
 albedo=bpy.data.images.load(str(SRC/'skin_albedo_generated.png'));albedo.scale(1024,1024)
 albedo.filepath_raw=str(TEX/'skin_albedo.png');albedo.file_format='PNG';albedo.save()
 # New periodic micro-normal/roughness data, not a physically scanned or baked map.
 n=1024;rng=np.random.default_rng(942);u,v=np.meshgrid(np.arange(n)/n,np.arange(n)/n)
 height=np.zeros((n,n));broad=np.zeros((n,n))
 for i in range(48):
  kx,ky=rng.integers(1,100,2);phase=rng.random()*math.tau
  height+=np.sin(math.tau*(kx*u+ky*v)+phase)/(kx*kx+ky*ky)**.35
 for i in range(12):
  kx,ky=rng.integers(1,10,2);broad+=np.sin(math.tau*(kx*u+ky*v)+rng.random()*math.tau)*.035
 wrinkles=np.sin(math.tau*(12*u+3*v)+np.sin(math.tau*5*v)*1.8)
 height=height*.045-np.exp(-wrinkles**2*120)*.035
 dx=(np.roll(height,-1,1)-np.roll(height,1,1))*2.0;dy=(np.roll(height,-1,0)-np.roll(height,1,0))*2.0
 normals=np.stack((-dx,-dy,np.ones_like(dx)),axis=-1);normals/=np.linalg.norm(normals,axis=-1,keepdims=True)
 normal=image_save('skin_normal',np.concatenate((normals*.5+.5,np.ones((n,n,1))),axis=-1),n)
 orm=np.ones((n,n,4));orm[:,:,1]=np.clip(.67+broad,.48,.85);orm[:,:,2]=0
 rough=image_save('skin_orm',orm,n)
 for name in ['skin_albedo','skin_normal','skin_orm']:
  original=bpy.data.images.load(str(TEX/(name+'.png')),check_existing=True);low=original.copy();low.scale(512,512);low.filepath_raw=str(TEX/(name+'_low.png'));low.file_format='PNG';low.save()
 return albedo,normal,rough
def material(name,tint,roughness,maps=None):
 mat=bpy.data.materials.new(name);mat.diffuse_color=(*tint,1);mat.use_nodes=True;bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*tint,1);bs.inputs['Roughness'].default_value=roughness
 if maps:
  al,no,orm=maps;nodes=mat.node_tree.nodes;links=mat.node_tree.links
  tex=nodes.new('ShaderNodeTexImage');tex.image=al;links.new(tex.outputs['Color'],bs.inputs['Base Color'])
  normal=nodes.new('ShaderNodeTexImage');normal.image=no;nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.65;links.new(normal.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bs.inputs['Normal'])
  tex=nodes.new('ShaderNodeTexImage');tex.image=orm;sep=nodes.new('ShaderNodeSeparateColor');links.new(tex.outputs['Color'],sep.inputs['Color']);links.new(sep.outputs['Green'],bs.inputs['Roughness'])
 return mat
def ell(name,center,radius,mat,segments=32,rings=20):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=point(*center));o=bpy.context.object;o.name=name;o.scale=Vector((radius[0],radius[2],radius[1]))*S;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);return o
def tube(name,coordinates,radii,mat,sides=10):
 pts=[point(*c) for c in coordinates];verts=[];faces=[]
 for i,p in enumerate(pts):
  direction=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized();q=direction.to_track_quat('Z','Y')
  for j in range(sides): verts.append(p+q@Vector((math.cos(j*math.tau/sides)*radii[i]*S,math.sin(j*math.tau/sides)*radii[i]*S,0)))
 for i in range(len(pts)-1):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
 faces.extend([tuple(reversed(range(sides))),tuple((len(pts)-1)*sides+j for j in range(sides))])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(mat);return o
def join(parts,name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();o=bpy.context.object;o.name=name;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);return o
def remesh(o,voxel):
 activate(o);m=o.modifiers.new('Continuous tissue','REMESH');m.mode='VOXEL';m.voxel_size=voxel;m.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=m.name)
 m=o.modifiers.new('Tissue relaxation','SMOOTH');m.factor=.5;m.iterations=4;bpy.ops.object.modifier_apply(modifier=m.name)
def carve(o,center,radius,tilt=0):
 if cavity.name not in [m.name for m in o.data.materials]:o.data.materials.append(cavity)
 cutter=ell('Temporary anatomical cavity',center,radius,skin);cutter.data.materials.append(cavity)
 for polygon in cutter.data.polygons:polygon.material_index=1
 cutter.rotation_euler.y=tilt;activate(o);m=o.modifiers.new('Recessed anatomy','BOOLEAN');m.operation='DIFFERENCE';m.solver='EXACT';m.object=cutter;bpy.ops.object.modifier_apply(modifier=m.name);bpy.data.objects.remove(cutter,do_unlink=True)
def unwrap(o):
 activate(o);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.uv.smart_project(angle_limit=math.radians(65),island_margin=.015);bpy.ops.object.mode_set(mode='OBJECT')
 uv=o.data.uv_layers.active.data;area=0
 for polygon in o.data.polygons:
  p=[uv[i].uv.copy() for i in polygon.loop_indices]
  for i in range(1,len(p)-1):a,b=p[i]-p[0],p[i+1]-p[0];area+=abs(a.x*b.y-a.y*b.x)*.5
 density=math.sqrt(sum(p.area for p in o.data.polygons)/max(area,1e-8))*2.5
 for loop in uv:loop.uv*=density
 for p in o.data.polygons:p.use_smooth=True
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
maps=textures();skin=material('Received_Skin',(.32,.31,.29),.72,maps);cartilage=material('Received_Cartilage',(.22,.14,.13),.57,maps);keratin=material('Received_Keratin',(.17,.15,.12),.64);cavity=material('Received_Cavity',(.012,.008,.009),.58)
bpy.ops.import_scene.gltf(filepath=str(SRC/'Escutador_Criatura_Original.glb'))
body_parts=[];details=[];ear_parts={-1:[],1:[]};jaw_parts=[]
for o in list(bpy.context.scene.objects):
 if o.type!='MESH':continue
 name=o.name
 # Remove toy-like spherical muzzle/eyes, flat jaw, detached rib sticks and fin spikes.
 if any(name.startswith(p) for p in ['cranium','face_muzzle','jaw','mouth_void','eye_','upper_tooth','lower_tooth','auditory_','rib_','torn_tissue','claw_']):bpy.data.objects.remove(o,do_unlink=True);continue
 o.matrix_world=Matrix.Scale(S,4)@o.matrix_world;o.location.z+=.012;activate(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.data.materials.clear()
 if name.startswith('shoulder_'):
  side=-1 if '-1' in name else 1;center=point(side*.42,2.47,.18)
  for v in o.data.vertices:v.co=center+(v.co-center)*.82
 hard=any(word in name for word in ['spinal_spur','neck_spur','toe_'])
 o.data.materials.append(keratin if hard else skin)
 (details if hard else body_parts).append(o)
# Mature elongated skull, continuous cheek/temple/brow/nasal bridge, recessed sockets.
skull=ell('Elongated skull',(.01,3.025,-.22),(.157,.32,.235),skin)
for s in [-1,1]:carve(skull,(s*.111,3.075+s*.008,-.425),(.084,.032,.085),s*.18)
carve(skull,(0,2.89,-.43),(.117,.070,.145))
body_parts.append(skull)
for s in [-1,1]:
 body_parts.append(tube('Zygomatic arch',[(s*.158,3.065,-.31),(s*.13,3.025,-.385),(s*.105,2.94,-.405)],[.024,.032,.018],skin))
 body_parts.append(tube('Supraorbital ridge',[(s*.025,3.145,-.405),(s*.105,3.145,-.425),(s*.165,3.095,-.36)],[.020,.024,.014],skin))
 body_parts.append(tube('Sternomastoid tendon',[(s*.12,2.92,-.20),(s*.16,2.74,-.02),(s*.25,2.50,.03)],[.035,.045,.045],skin))
body_parts.append(tube('Nasal bridge',[(.005,3.15,-.405),(0,3.03,-.452),(.005,2.965,-.48)],[.026,.032,.023],skin))
body=join(body_parts,'Continuous_received_dermis')
print('PRE_REMESH',list(body.dimensions),len(body.data.vertices),flush=True)
remesh(body,.012)
print('POST_REMESH',len(body.data.vertices),flush=True)
# Body contour sculpting and neck/knee creases are actual vertex geometry.
sculpt_normals=[v.normal.copy() for v in body.data.vertices]
for v,normal in zip(body.data.vertices,sculpt_normals):
 x,y,z=v.co;source_z=(z-.012)/S;waist=math.exp(-((source_z-1.82)/.31)**2)
 if abs(x)<.4*S:v.co.x*=1-.18*waist
 mask=math.exp(-((source_z-2.80)/.15)**2)+.6*math.exp(-((source_z-.78)/.13)**2)
 v.co+=normal*(math.sin(z*155+y*31)*.0014*mask+math.sin(x*39+y*29+z*21)*.0008)
 if source_z>2.82 and y>.14*S:
  # Hollow cheeks and asymmetric nasolabial scarring, rather than a spherical muzzle.
  hollow=math.exp(-((abs(x/S)-.105)/.047)**2-((source_z-2.985)/.09)**2)
  v.co.y-=.027*S*hollow
  scar=math.exp(-((x/S+.06+(source_z-2.98)*.3)/.010)**2-((source_z-3.0)/.17)**2)
  v.co.y-=.007*S*scar
activate(body);dec=body.modifiers.new('Mobile retopology approximation','DECIMATE');dec.ratio=min(1,22000/max(1,sum(len(p.vertices)-2 for p in body.data.polygons)));bpy.ops.object.modifier_apply(modifier=dec.name)
# Cavities are the concave Boolean surfaces themselves, not oval eye/mouth inserts.
jaw_parts.append(tube('Articulated mandibular arch',[(-.158,2.96,-.25),(-.147,2.85,-.39),(-.08,2.815,-.465),(.008,2.80,-.48),(.08,2.815,-.465),(.147,2.85,-.39),(.158,2.96,-.25)],[.042,.045,.041,.038,.041,.045,.042],skin,12))
for i in range(9):
 x=(i-4)*.025;length=.030+(i%3)*.008
 details.append(tube('Uneven upper dentition',[(x,2.96,-.44),(x*.99,2.96-length*.65,-.475),(x*.96,2.96-length,-.465)],[.011,.008,.003],keratin,8))
 jaw_parts.append(tube('Uneven lower dentition',[(x,2.83,-.472),(x,2.85,-.48),(x*.98,2.865+(i%2)*.009,-.472)],[.010,.008,.003],keratin,8))
for s in [-1,1]:
 # A cupped, corrugated membrane with an irregular lobed rim, rather than cones.
 vertices=[];faces=[];rings=8;segments=40
 for r in range(rings):
  t=(r+.05)/(rings-1+.05)
  for j in range(segments):
   a=j*math.tau/segments;rag=1+.12*math.sin(3*a+.7*s)+.045*math.sin(7*a)
   taper=.65+.35*(1-math.sin(a))
   x=s*(.235+math.cos(a)*(.105 if s<0 else .078)*t*rag*taper)
   z=(3.14 if s<0 else 3.10)+math.sin(a)*(.29 if s<0 else .225)*t*rag
   forward=.065+.065*t*t+.045*math.sin(a*3+t*7)*t
   vertices.append(point(x,z,-forward))
 for r in range(rings-1):
  for j in range(segments):a=r*segments+j;b=r*segments+(j+1)%segments;faces.append((a,b,b+segments,a+segments))
 mesh=bpy.data.meshes.new('Cupped auditory membrane');mesh.from_pydata(vertices,[],faces);mesh.update();o=bpy.data.objects.new('Auditory_concha',mesh);bpy.context.collection.objects.link(o);o.data.materials.append(cartilage);activate(o);solid=o.modifiers.new('Cartilage thickness','SOLIDIFY');solid.thickness=.006;bpy.ops.object.modifier_apply(modifier=solid.name);ear_parts[s].append(o)
 for i in range(4):
  wx=s*(.65 if s<0 else .80);x=wx+(i-1.5)*.083;z=-.30 if s<0 else -.30
  details.append(tube('Curved keratin claw',[(x+s*.018,.57+(i%2)*.025,z-.16),(x+s*.03,.48,z-.20),(x+s*.025,.40,z-.28),(x+s*.015,.385,z-.33)],[.029,.023,.012,.001],keratin,10))
print('ANATOMY_REBUILT',flush=True)
# Same public bone identifiers as the existing visual controller, no gameplay rig changes.
arm=bpy.data.armatures.new('Received_Escutador_Rig');rig=bpy.data.objects.new('Received_Escutador',arm);bpy.context.collection.objects.link(rig);activate(rig);bpy.ops.object.mode_set(mode='EDIT');bones={}
def bone(name,a,b,parent=None):
 a,b=point(*a),point(*b);bo=arm.edit_bones.new(name);bo.head=a;bo.tail=b
 if parent:bo.parent=arm.edit_bones[parent]
 bones[name]=(a,b)
bone('root',(0,0,0),(0,.2,0));bone('hips',(0,1.37,.12),(0,1.68,.18),'root');bone('spine',(0,1.68,.18),(0,2.10,.21),'hips');bone('chest',(0,2.10,.21),(0,2.48,.20),'spine');bone('neck',(0,2.48,.20),(0,2.82,-.16),'chest');bone('head',(0,2.82,-.16),(0,3.22,-.16),'neck');bone('jaw',(0,2.94,-.23),(0,2.76,-.46),'head')
for side,s in [('L',-1),('R',1)]:
 sh=(s*.42,2.47,.18);el=(s*(.70 if s<0 else .67),1.69,-.10 if s<0 else .22);w=(s*(.65 if s<0 else .80),.93,-.30)
 bone('upper_arm_'+side,sh,el,'chest');bone('forearm_'+side,el,w,'upper_arm_'+side);bone('hand_'+side,w,(w[0],.75,-.34),'forearm_'+side)
 for i in range(4):x=w[0]+(i-1.5)*.083;bone('finger_'+str(i)+'_'+side,(x,.78,-.37),(x+s*.018,.48,-.52),'hand_'+side)
 knee=(s*(.36 if s<0 else .42),.78,-.13 if s<0 else .22)
 bone('thigh_'+side,(s*.25,1.40,.13),knee,'hips');bone('shin_'+side,knee,(s*.40,.17,.10),'thigh_'+side);bone('foot_'+side,(s*.40,.17,.10),(s*.40,.08,-.40),'shin_'+side);bone('ear_'+side,(s*.20,3.13,-.16),(s*.43,3.36,-.17),'head')
bpy.ops.object.mode_set(mode='OBJECT')
def bind(o,fixed=None):
 if fixed:
  g=o.vertex_groups.new(name=fixed);g.add(list(range(len(o.data.vertices))),1,'REPLACE');return
 names=[n for n in bones if n not in ['root','jaw'] and not n.startswith('ear_')];groups={n:o.vertex_groups.new(name=n) for n in names}
 for vertex in o.data.vertices:
  distances=[]
  for name in names:
   a,b=bones[name];t=max(0,min(1,(vertex.co-a).dot(b-a)/(b-a).length_squared));distances.append(((vertex.co-(a+(b-a)*t)).length,name))
  nearest=sorted(distances)[:3];weights=[1/max(.012,d)**6 for d,n in nearest];total=sum(weights)
  for (d,n),w in zip(nearest,weights):groups[n].add([vertex.index],w/total,'REPLACE')
parts=[body]+details
for o in parts:unwrap(o);bind(o)
for o in jaw_parts:unwrap(o);bind(o,'jaw');parts.append(o)
for s in [-1,1]:
 for o in ear_parts[s]:unwrap(o);bind(o,'ear_L' if s<0 else 'ear_R');parts.append(o)
body=join(parts,'Received_Escutador_SkinnedMesh');activate(body);bpy.ops.object.material_slot_remove_unused();mod=body.modifiers.new('Weighted articulation','ARMATURE');mod.object=rig;body.parent=rig
exec((ROOT/'tools/art/animate_received_escutador.py').read_text(),globals())
rig.animation_data.action=bpy.data.actions['idle'];bpy.context.scene.frame_set(0)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'escutador_refined.blend'))
activate(rig);body.select_set(True)
export=dict(export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True,export_materials='EXPORT',export_image_format='NONE',export_cameras=False,export_lights=False)
bpy.ops.export_scene.gltf(filepath=str(OUT/'escutador_received.glb'),**export)
main_triangles=sum(len(p.vertices)-2 for p in body.data.polygons)
activate(body);mod=body.modifiers.new('Android low detail','DECIMATE');mod.ratio=.44;bpy.ops.object.modifier_move_up(modifier=mod.name);bpy.ops.object.modifier_apply(modifier=mod.name);rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'escutador_received_low.glb'),**export)
low_triangles=sum(len(p.vertices)-2 for p in body.data.polygons)
report={'input_sha256':hashlib.sha256((SRC/'Escutador_Criatura_Original.glb').read_bytes()).hexdigest(),'input_triangles':21684,'input_meshes':130,'triangles':main_triangles,'triangles_low':low_triangles,'bones':len(bones),'clips':[{'name':n,'duration':d,'loop':l} for n,d,l in clips],'texture_size':1024,'texture_size_low':512,'materials':len(body.data.materials),'scale_from_input':S,'source_blend':'assets/source/received_escutador/escutador_refined.blend','limitations':['Procedural anatomy refinement, not a final production sculpt','Decimated remesh, no manually authored animation edge loops','Authored keyframes and analytic leg IK, no motion capture','Generated albedo; procedural micro normals and roughness, no scanned or high-poly-baked skin','Real Android FPS, thermals, microphone and touch not measured']}
(OUT/'escutador_received_manifest.json').write_text(json.dumps(report,indent=2))
print('RECEIVED_REFINEMENT_COMPLETE',json.dumps(report),flush=True)
