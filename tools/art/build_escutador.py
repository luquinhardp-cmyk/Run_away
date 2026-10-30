"""Blender 4.5 LTS: original skinned creature, UVs, 12 clips, two geometric LODs."""
import bpy, math, json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / 'assets/models'
SOURCE = ROOT / 'assets/source'
MODELS.mkdir(parents=True, exist_ok=True); SOURCE.mkdir(parents=True, exist_ok=True)
(SOURCE / '.gdignore').write_text('')
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def material(name, tint, rough, map_name='creature_skin'):
    mat=bpy.data.materials.new(name); mat.use_nodes=True
    nodes=mat.node_tree.nodes; links=mat.node_tree.links
    bs=nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*tint,1)
    bs.inputs['Roughness'].default_value=rough
    for suffix in ['albedo','normal','orm']:
        tex=nodes.new('ShaderNodeTexImage'); tex.image=bpy.data.images.load(str(ROOT/f'assets/textures/pbr/{map_name}_{suffix}.png'),check_existing=True)
        if suffix!='albedo': tex.image.colorspace_settings.name='Non-Color'
        if suffix=='albedo': links.new(tex.outputs['Color'],bs.inputs['Base Color'])
        elif suffix=='normal':
            normal=nodes.new('ShaderNodeNormalMap'); normal.inputs['Strength'].default_value=.7
            links.new(tex.outputs['Color'],normal.inputs['Color']); links.new(normal.outputs['Normal'],bs.inputs['Normal'])
        else:
            separate=nodes.new('ShaderNodeSeparateColor'); links.new(tex.outputs['Color'],separate.inputs['Color'])
            links.new(separate.outputs['Green'],bs.inputs['Roughness'])
    return mat

skin=material('Pele_terrosa',(0.34,.32,.28),.74)
plate=material('Placas_queratina',(0.20,.17,.12),.88,'rotten_wood')
inner=material('Cartilagem_auditiva',(0.28,.15,.11),.55,'organic_residue')
eye=bpy.data.materials.new('Olhos_profundos'); eye.diffuse_color=(.022,.017,.01,1); eye.use_nodes=True
eye.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.015,.012,.008,1)
eye.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.22

armdata=bpy.data.armatures.new('Escutador_Rig'); rig=bpy.data.objects.new('Escutador',armdata)
bpy.context.collection.objects.link(rig); bpy.context.view_layer.objects.active=rig; rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bones={}
def bone(name,head,tail,parent=None):
    b=armdata.edit_bones.new(name); b.head=head; b.tail=tail
    if parent: b.parent=armdata.edit_bones[parent]
    bones[name]=(Vector(head),Vector(tail)); return b
bone('root',(0,0,0),(0,0,.2))
bone('hips',(0,0,1.02),(0,0,1.27),'root')
bone('spine',(0,0,1.27),(0,.06,1.62),'hips')
bone('chest',(0,.06,1.62),(0,.12,1.92),'spine')
bone('neck',(0,.12,1.92),(0,.15,2.18),'chest')
bone('head',(0,.15,2.18),(0,.16,2.52),'neck')
bone('jaw',(0,.17,2.28),(0,.34,2.17),'head')
for side,s in [('L',-1),('R',1)]:
    shoulder=(s*.22,.07,1.9+(0.07 if side=='L' else -.03))
    elbow=(s*.40,.09,1.31)
    wrist=(s*.42,.18,.76)
    bone('upper_arm_'+side,shoulder,elbow,'chest')
    bone('forearm_'+side,elbow,wrist,'upper_arm_'+side)
    bone('hand_'+side,wrist,(s*.43,.22,.56),'forearm_'+side)
    for digit in range(4): bone(f'finger_{digit}_{side}',(s*(.35+digit*.045),.23,.61),(s*(.36+digit*.048),.34,.35+digit*.018),'hand_'+side)
    bone('thigh_'+side,(s*.13,0,1.12),(s*.15,.11,.65),'hips')
    bone('shin_'+side,(s*.15,.11,.65),(s*.16,-.11,.23),'thigh_'+side)
    bone('foot_'+side,(s*.16,-.11,.23),(s*.16,.22,.08),'shin_'+side)
    bone('ear_'+side,(s*.13,.14,2.43),(s*.34,.16,2.56 if side=='L' else 2.48),'head')
bpy.ops.object.mode_set(mode='OBJECT'); rig.select_set(False)
parts=[]

def bind(obj, name, mat):
    obj.data.materials.append(mat)
    # Keep each component UVs; overlapping UV islands intentionally reuse tileable skin.
    group=obj.vertex_groups.new(name=name); group.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
    for p in obj.data.polygons: p.use_smooth=True
    parts.append(obj); return obj

def oval(name,loc,scale,b,mat=skin,segments=16,rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=loc)
    obj=bpy.context.object; obj.name=name; obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return bind(obj,b,mat)

def spindle(name,a,b,radius_a,radius_b,bone_name,mat=skin,sides=12):
    a,b=Vector(a),Vector(b); delta=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=sides,radius1=radius_a,radius2=radius_b,depth=delta.length,location=(a+b)/2)
    obj=bpy.context.object; obj.name=name; obj.rotation_euler=delta.to_track_quat('Z','Y').to_euler()
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return bind(obj,bone_name,mat)

# Tensioned lean torso, sternum and asymmetric shoulder girdle.
oval('Pelvis',(0,0,1.19),(.205,.14,.22),'hips')
oval('Abdomen',(0,.035,1.43),(.145,.115,.27),'spine')
oval('Thorax',(0,.08,1.72),(.245,.16,.31),'chest')
oval('Sternum',(0,.24,1.76),(.045,.027,.24),'chest',plate)
for s in [-1,1]:
    for j in range(5):
        rib=oval('Costela',(s*(.10+j*.012),.205,1.58+j*.07),(.13,.034,.025),'chest',plate,12,6)
        rib.rotation_euler.y=s*.3
spindle('Pescoco',(0,.08,1.89),(0,.17,2.26),.105,.075,'neck')
for s in [-1,1]: spindle('Tendao',(s*.055,.20,1.95),(s*.075,.22,2.3),.018,.012,'neck',inner,8)
oval('Cranio',(0,.15,2.38),(.135,.165,.225),'head')
oval('Occipital',(0,.025,2.40),(.10,.09,.19),'head',plate)
for side,s in [('L',-1),('R',1)]:
    # Sloping hard plates break the normal humanoid outline.
    brow=oval('Placa_facial_'+side,(s*.09,.28,2.43),(.064,.055,.115),'head',plate,12,8)
    brow.rotation_euler.y=s*.55
    oval('Orbita_'+side,(s*.076,.293,2.365),(.040,.029,.035),'head',inner,12,6)
    oval('Olho_'+side,(s*.073,.315,2.374),(.013,.012,.014),'head',eye,10,6)
oval('Mandibula',(0,.25,2.20),(.105,.105,.105),'jaw',inner)
oval('Fenda_mandibular',(0,.335,2.25),(.075,.012,.03),'jaw',eye,12,6)
for j in range(7):
    x=(j-3)*.026
    spindle('Dente',(x,.335,2.25),(x,.355,2.19-abs(j-3)*.007),.012,.002,'jaw',plate,7)

# Open, concave auditory cups. Their moving rims belong to dedicated bones.
for side,s in [('L',-1),('R',1)]:
    vertices=[]; faces=[]; size=.17 if side=='L' else .115
    center=Vector((s*.16,.15,2.40))
    axis=Vector((s*.8,.35,-.08)).normalized(); u=Vector((s*.55,0,.60)).normalized(); v=axis.cross(u).normalized()
    for ring in range(5):
        t=ring/4; radius=size*(.18+.82*t)
        for i in range(20):
            angle=i*2*math.pi/20
            rim=radius*(1+.22*math.sin(angle*3)+.09*math.cos(angle*5))
            p=center+axis*(.035+t*t*.10)+u*math.cos(angle)*rim+v*math.sin(angle)*rim*.65
            vertices.append(p)
    for r in range(4):
        for i in range(20):
            a=r*20+i; n=r*20+(i+1)%20
            faces.append((a,n,n+20,a+20))
    mesh=bpy.data.meshes.new('Concha_'+side); mesh.from_pydata(vertices,[],faces); mesh.update()
    obj=bpy.data.objects.new('Concha_'+side,mesh); bpy.context.collection.objects.link(obj)
    bind(obj,'ear_'+side,inner)
    # Add UVs to the authored cup topology.
    uv=mesh.uv_layers.new(name='UVMap')
    for poly in mesh.polygons:
        for loop in poly.loop_indices:
            vi=mesh.loops[loop].vertex_index; uv.data[loop].uv=(vi%20/20,vi//20/4)
    solid=obj.modifiers.new('Espessura_cartilagem','SOLIDIFY'); solid.thickness=.008
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=solid.name)
    oval('Base_auditiva_'+side,(s*.15,.12,2.43),(.065,.08,.09),'ear_'+side,skin,12,8)
    for k in range(3):
        spindle('Nervura_auditiva',(s*.17,.15,2.43),(s*(.24+k*.025),.19,2.56+k*.025),.012,.004,'ear_'+side,plate,7)

for side,s in [('L',-1),('R',1)]:
    for key,ra,rb in [('upper_arm_',.105,.065),('forearm_',.068,.038),('thigh_',.12,.075),('shin_',.072,.035),('foot_',.045,.07)]:
        a,b=bones[key+side]; spindle(key+side,a,b,ra,rb,key+side)
        oval('Junta_'+key+side,a,(ra,ra,ra),key+side,skin,12,8)
    a,b=bones['hand_'+side]; oval('Mao_'+side,(a+b)/2,(.095,.045,.15),'hand_'+side)
    for digit in range(4):
        a,b=bones[f'finger_{digit}_{side}']; mid=a.lerp(b,.6)+Vector((0,.025,0))
        spindle('Dedo',a,mid,.019,.012,f'finger_{digit}_{side}',skin,7)
        spindle('Garra',mid,b+Vector((0,.04,-.025)),.013,.001,f'finger_{digit}_{side}',plate,7)
    # Small reverse-knee ridge and heel spur, within the existing capsule footprint.
    spindle('Tibia_exposta',(s*.16,-.09,.30),(s*.15,.10,.66),.024,.04,'shin_'+side,plate,8)
    for digit in range(3):
        spindle('Unha_pe',(s*.16+(digit-1)*.04,.13,.10),(s*.16+(digit-1)*.045,.28,.06),.025,.003,'foot_'+side,plate,7)

# Join by material to keep a small draw call count, skin weights preserved.
bpy.ops.object.select_all(action='DESELECT')
for part in parts: part.select_set(True)
bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join()
body=bpy.context.object; body.name='Escutador_SkinnedMesh'
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
modifier=body.modifiers.new('Deformacao_esqueletica','ARMATURE'); modifier.object=rig
body.parent=rig
bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); bpy.context.view_layer.objects.active=rig
rig.animation_data_create()

clips=[('idle',3.2,True),('breathe',3.6,True),('walk',1.2,True),('patrol',1.4,True),('listen',1.6,False),('investigate',1.5,True),('search',3.0,True),('run',.72,True),('chase',.72,True),('attack',.65,False),('capture',.9,False),('return',1.4,True)]
bpy.context.scene.render.fps=30
for clip,duration,loop in clips:
    action=bpy.data.actions.new(clip); action.use_fake_user=True; rig.animation_data.action=action
    count=round(duration*30)
    for frame in range(0,count+1,3):
        p=frame/count; cycle=p*math.tau
        for pb in rig.pose.bones:
            pb.rotation_mode='XYZ'; pb.rotation_euler=(0,0,0); pb.location=(0,0,0); pb.scale=(1,1,1)
        rig.pose.bones['chest'].scale=(1+math.sin(cycle)*.014,1+math.sin(cycle)*.02,1)
        rig.pose.bones['head'].rotation_euler.x=.045*math.sin(cycle)
        if clip in ['walk','patrol','investigate','return','run','chase']:
            fast=clip in ['run','chase']; amplitude=.68 if fast else .32
            for side,s in [('L',-1),('R',1)]:
                swing=math.sin(cycle)*s
                rig.pose.bones['thigh_'+side].rotation_euler.x=swing*amplitude
                rig.pose.bones['shin_'+side].rotation_euler.x=max(0,-swing)*amplitude*.9
                rig.pose.bones['foot_'+side].rotation_euler.x=-swing*amplitude*.35
                rig.pose.bones['upper_arm_'+side].rotation_euler.x=-swing*amplitude*.55
                rig.pose.bones['forearm_'+side].rotation_euler.x=.16+max(0,swing)*.15
            rig.pose.bones['hips'].location.z=abs(math.sin(cycle))*(.025 if fast else .012)
            rig.pose.bones['spine'].rotation_euler.x=.14 if fast else .03
            rig.pose.bones['head'].rotation_euler.z=math.sin(cycle+.5)*(.07 if fast else .025)
        if clip=='listen':
            # Hold feet planted; slow asymmetric tilt, then release toward the stimulus.
            envelope=math.sin(math.pi*p)**.7
            rig.pose.bones['neck'].rotation_euler.z=-envelope*.12
            rig.pose.bones['head'].rotation_euler.z=envelope*.58
            rig.pose.bones['head'].rotation_euler.x=-envelope*.13
            rig.pose.bones['ear_L'].rotation_euler.y=envelope*.5
            rig.pose.bones['ear_R'].rotation_euler.y=-envelope*.32
            rig.pose.bones['ear_L'].rotation_euler.z=envelope*.27+math.sin(p*math.tau*2)*.025
            rig.pose.bones['chest'].rotation_euler.z=envelope*.08
            rig.pose.bones['hand_L'].rotation_euler.x=envelope*.18
        if clip=='search':
            rig.pose.bones['neck'].rotation_euler.y=math.sin(cycle)*.32
            rig.pose.bones['head'].rotation_euler.z=math.sin(cycle+.7)*.19
            rig.pose.bones['ear_L'].rotation_euler.y=math.sin(cycle)*.15
        if clip in ['attack','capture']:
            strike=math.sin(math.pi*p)
            rig.pose.bones['spine'].rotation_euler.x=strike*.35
            rig.pose.bones['neck'].rotation_euler.x=-strike*.3
            rig.pose.bones['jaw'].rotation_euler.x=strike*.5
            for side in ['L','R']:
                rig.pose.bones['upper_arm_'+side].rotation_euler.x=-strike*1.1
                rig.pose.bones['forearm_'+side].rotation_euler.x=-strike*.4
        for pb in rig.pose.bones:
            pb.keyframe_insert(data_path='rotation_euler',frame=frame)
            if pb.name in ['hips','chest']: pb.keyframe_insert(data_path='location' if pb.name=='hips' else 'scale',frame=frame)
    # Include exact terminal frame for deterministic loop lengths.
    bpy.context.scene.frame_set(count)
    action['loop']=loop; action['duration']=duration

rig.animation_data.action=bpy.data.actions['idle']; bpy.context.scene.frame_set(0)
bpy.context.scene.frame_end=108
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'escutador.blend'))
kwargs=dict(export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True,export_cameras=False,export_lights=False)
bpy.ops.export_scene.gltf(filepath=str(MODELS/'escutador.glb'),**kwargs)
triangles=sum(len(p.vertices)-2 for p in body.data.polygons)
# Low mesh shares the same rig and action set; decimation keeps vertex groups.
bpy.context.view_layer.objects.active=body; rig.select_set(False); body.select_set(True)
decimate=body.modifiers.new('LOD_mobile','DECIMATE'); decimate.ratio=.46
bpy.ops.object.modifier_move_up(modifier=decimate.name)
bpy.ops.object.modifier_apply(modifier=decimate.name)
bpy.ops.export_scene.gltf(filepath=str(MODELS/'escutador_low.glb'),**kwargs)
low_triangles=sum(len(p.vertices)-2 for p in body.data.polygons)
stats={'name':'O Escutador','tool':bpy.app.version_string,'triangles_main':triangles,'triangles_low':low_triangles,'bones':len(armdata.bones),'clips':[{'name':n,'duration':d,'loop':l} for n,d,l in clips],'height_m':2.7,'origin':'original procedural sculpt and armature; no copied character or third-party model','source':'tools/art/build_escutador.py','formats':['GLB','blend'],'notes':'Segmented anatomical mesh with overlapping joint volumes; not hand-retopologized production sculpture.'}
(MODELS/'escutador_manifest.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print('ESCUTADOR_COMPLETE',json.dumps(stats))
