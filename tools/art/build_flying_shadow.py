"""Blender 4.5: original distance humanoid, scalloped batlike wings, rig and six flight clips."""
import bpy,math,json,bmesh
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
models=root/'assets/models';source=root/'assets/source'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
skin=bpy.data.materials.new('Sombra_carvao');skin.diffuse_color=(.009,.011,.012,1);skin.use_nodes=True
skin.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.009,.011,.012,1)
skin.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.85
skin.use_backface_culling=False
arm=bpy.data.armatures.new('SombraAladaRig');rig=bpy.data.objects.new('SombraAlada',arm);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
bones={}
def bone(name,a,b,parent=None):
    e=arm.edit_bones.new(name);e.head=a;e.tail=b
    if parent:e.parent=arm.edit_bones[parent]
    if name.startswith('wing'):e.align_roll(Vector((0,0,1)))
    bones[name]=(Vector(a),Vector(b))
bone('root',(0,0,.1),(0,0,1.2));bone('chest',(0,0,1.2),(0,0,2.6),'root');bone('head',(0,0,2.6),(0,0,3.4),'chest')
for side,s in [('L',-1),('R',1)]:
    bone('arm_'+side,(s*.3,0,2.5),(s*.55,-.05,1.2),'chest')
    bone('leg_'+side,(s*.14,0,1.2),(s*.23,.1,.05),'root')
    bone('wing_'+side,(s*.3,.1,2.5),(s*3,.2,3.1),'chest')
    bone('wing_tip_'+side,(s*3,.2,3.1),(s*7,.1,2.7),'wing_'+side)
bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
parts=[]
def weights(o,name):
    group=o.vertex_groups.new(name=name);group.add(list(range(len(o.data.vertices))),1,'REPLACE')
    parts.append(o);o.data.materials.append(skin)
def oval(name,at,scale,joint):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=at)
    o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);weights(o,joint)
def spindle(name,a,b,r,joint):
    a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=r,radius2=r*.35,depth=(b-a).length,location=(a+b)/2)
    o=bpy.context.object;o.name=name;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();weights(o,joint)
oval('Torax',(0,0,2.15),(.32,.19,.65),'chest')
oval('Cintura',(0,0,1.25),(.2,.14,.35),'root')
oval('Cabeca',(0,-.06,3.0),(.19,.18,.37),'head')
spindle('Cranio_fendido_L',(-.08,0,3.25),(-.28,.13,3.65),.09,'head')
spindle('Cranio_fendido_R',(.08,0,3.25),(.23,.08,3.52),.07,'head')
for side,s in [('L',-1),('R',1)]:
    spindle('Braco_'+side,*bones['arm_'+side],.085,'arm_'+side)
    spindle('Perna_'+side,*bones['leg_'+side],.095,'leg_'+side)
    for i in range(3):spindle('Garra_'+side+str(i),(s*(.48+i*.05),-.05,1.2),(s*(.52+i*.07),-.22,.83-i*.04),.022,'arm_'+side)
    spindle('Pe_'+side,(s*.23,.1,.12),(s*.25,-.22,-.04),.065,'leg_'+side)
    edge=[(s*.3,.1,2.5),(s*3,.2,3.1),(s*7,.1,2.7),(s*5.7,.8,1.35),(s*4.8,.5,2.15),(s*3.8,1.4,.85),(s*3.0,.8,1.9),(s*2.0,1.3,.85),(s*1.2,.65,1.65),(s*.5,.3,1.45)]
    mesh=bpy.data.meshes.new('Membrana_'+side);mesh.from_pydata(edge,[],[list(range(len(edge)))]);mesh.update()
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    o=bpy.data.objects.new('Membrana_'+side,mesh);bpy.context.collection.objects.link(o);o.data.materials.append(skin)
    inner=o.vertex_groups.new(name='wing_'+side);outer=o.vertex_groups.new(name='wing_tip_'+side)
    for v in mesh.vertices:
        blend=max(0,min(1,(abs(v.co.x)-2)/2.0));inner.add([v.index],1-blend,'REPLACE');outer.add([v.index],blend,'REPLACE')
    parts.append(o)
    for a,b in [(edge[0],edge[1]),(edge[1],edge[2]),(edge[1],edge[3]),(edge[1],edge[5]),(edge[1],edge[7])]:
        spindle('Nervura_'+side,a,b,.045,'wing_tip_'+side if abs(b[0])>3 else 'wing_'+side)
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();body=bpy.context.object;body.name='SombraAladaMesh'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
for p in body.data.polygons:p.use_smooth=True
modifier=body.modifiers.new('Armature','ARMATURE');modifier.object=rig;body.parent=rig
bpy.context.view_layer.objects.active=body;bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project();bpy.ops.object.mode_set(mode='OBJECT')
rig.animation_data_create();bpy.context.scene.render.fps=30
clips=[('glide',2.4),('flap',1.4),('bank_left',2.4),('bank_right',2.4),('fast_pass',1.0),('vanish',2.4)]
for name,duration in clips:
    action=bpy.data.actions.new(name);action.use_fake_user=True;rig.animation_data.action=action
    for frame in range(0,round(duration*30)+1,2):
        p=frame/(duration*30)
        for joint in rig.pose.bones:joint.rotation_mode='XYZ';joint.rotation_euler=(0,0,0)
        amplitude=.5 if name in ['flap','fast_pass'] else .045
        for side in ['L','R']:
            rig.pose.bones['wing_'+side].rotation_euler.x=math.sin(p*math.tau)*amplitude
            rig.pose.bones['wing_tip_'+side].rotation_euler.x=math.sin(p*math.tau-.45)*amplitude*.6
            rig.pose.bones['leg_'+side].rotation_euler.x=.14+math.sin(p*math.tau)*.04
        rig.pose.bones['chest'].rotation_euler.z=(.18 if name=='bank_left' else -.18 if name=='bank_right' else .02)*math.sin(p*math.tau)
        rig.pose.bones['head'].rotation_euler.x=.12
        for joint in rig.pose.bones:joint.keyframe_insert(data_path='rotation_euler',frame=frame)
rig.animation_data.action=bpy.data.actions['glide'];bpy.context.scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(source/'sombra_alada.blend'))
kwargs=dict(export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True,export_cameras=False,export_lights=False)
bpy.ops.export_scene.gltf(filepath=str(models/'sombra_alada.glb'),**kwargs)
triangles=sum(len(p.vertices)-2 for p in body.data.polygons)
bpy.context.view_layer.objects.active=body;rig.select_set(False);body.select_set(True)
dec=body.modifiers.new('Low','DECIMATE');dec.ratio=.55;bpy.ops.object.modifier_move_up(modifier=dec.name);bpy.ops.object.modifier_apply(modifier=dec.name)
bpy.ops.export_scene.gltf(filepath=str(models/'sombra_alada_low.glb'),**kwargs)
manifest=dict(name='A Sombra Alada',origin='original procedural rigged model',triangles=triangles,triangles_low=sum(len(p.vertices)-2 for p in body.data.polygons),bones=len(arm.bones),wingspan_m=14,clips=[n for n,d in clips],source='tools/art/build_flying_shadow.py',limitations='Distance silhouette; no landing, hunting AI or close-up sculpt polish.')
(models/'sombra_alada_manifest.json').write_text(json.dumps(manifest,indent=2))
print('FLYING_SHADOW_COMPLETE',json.dumps(manifest))
