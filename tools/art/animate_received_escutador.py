"""Executed by the Blender builder with its rig/bones in scope. In-place motion only."""
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT.parent/'.tools/received_anatomy.blend'))
clips=[('idle',3.6,True),('breathe',4.1,True),('walk',1.0,True),('patrol',1.0,True),('listen',1.6,False),('investigate',1.0,True),('search',1.0,True),('run',.5,True),('chase',.5,True),('attack',.75,False),('capture',1.25,False),('return',1.0,True),('head_tilt',2.1,False),('hide_search',2.6,True),('lost',2.8,True)]+[('capture_'+n,1.25,False) for n in ['front','side','rear','hide','corridor','chase','silent','dark']]
bpy.context.scene.render.fps=30;activate(rig);rig.animation_data_create()
def ease(a,b,t):
 t=max(0,min(1,(t-a)/(b-a)));return t*t*(3-2*t)
def orient(name,origin,target):
 pb=rig.pose.bones[name];rest=rig.data.bones[name].matrix_local.to_3x3();direction=target-origin
 rotation=(bones[name][1]-bones[name][0]).rotation_difference(direction).to_matrix()@rest
 pb.matrix=Matrix.Translation(origin)@rotation.to_4x4();bpy.context.view_layer.update()
def leg(side,phase,fast,walking,hip_drop):
 thigh='thigh_'+side;shin='shin_'+side;foot='foot_'+side
 pb=rig.pose.bones[thigh];H=pb.matrix.translation.copy();T=bones[shin][1].copy()
 if walking:
  stride=.50 if fast else .46
  if phase<.60:forward=stride*(1-2*phase/.60);lift=0
  else:
   p=(phase-.60)/.40;forward=-stride+2*stride*ease(0,1,p);lift=math.sin(p*math.pi)*(.12 if fast else .07)
  T.y+=forward;T.z+=lift
 length_a=(bones[thigh][1]-bones[thigh][0]).length;length_b=(bones[shin][1]-bones[shin][0]).length
 direction=T-H;d=max(.05,min(direction.length,(length_a+length_b)*.997));direction.normalize();T=H+direction*d
 a=(length_a**2-length_b**2+d*d)/(2*d);height=math.sqrt(max(.00001,length_a**2-a*a))
 # Respect the supplied asymmetric knee anatomy rather than stretching bones.
 rest_bend=bones[thigh][1]-(bones[thigh][0]+bones[shin][1])*.5
 bend=rest_bend-direction*rest_bend.dot(direction)
 if bend.length<.001:bend=Vector((0,1,0))-direction*direction.y
 bend.normalize();K=H+direction*a+bend*height
 orient(thigh,H,K);orient(shin,K,T)
 foot_end=T+(bones[foot][1]-bones[foot][0])
 orient(foot,T,foot_end)
for clip,duration,loop in clips:
 action=bpy.data.actions.new(clip);action.use_fake_user=True;rig.animation_data.action=action
 count=round(duration*30);samples=sorted(set(list(range(0,count+1,2))+[count]))
 for frame in samples:
  p=frame/count;cycle=p*math.tau;walking=clip in ['walk','patrol','investigate','return','search','run','chase'];fast=clip in ['run','chase']
  for pb in rig.pose.bones:
   pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0);pb.scale=(1,1,1)
  chest=rig.pose.bones['chest'];head=rig.pose.bones['head'];neck=rig.pose.bones['neck'];hips=rig.pose.bones['hips']
  # Breathing uses subtle chest rotation, not balloon-like scaling of the torso.
  chest.rotation_euler.x=.009*math.sin(cycle);chest.rotation_euler.z=.006*math.sin(cycle+.8)
  head.rotation_euler.x=.013*math.sin(cycle+.4)
  if walking:
   hips.location.z=(1-math.cos(cycle*2))*(.009 if fast else .004)
   hips.rotation_euler.z=math.sin(cycle)*(.025 if fast else .018)
   rig.pose.bones['spine'].rotation_euler.x=-.12 if fast else -.025
   chest.rotation_euler.y=math.sin(cycle)*(.065 if fast else .025)
   for side,offset in [('L',0),('R',.5)]:
    swing=math.sin(cycle+offset*math.tau)
    rig.pose.bones['upper_arm_'+side].rotation_euler.x=swing*(.42 if fast else .13)
    rig.pose.bones['forearm_'+side].rotation_euler.x=-.10-max(0,-swing)*.13
    rig.pose.bones['hand_'+side].rotation_euler.y=.04*math.sin(cycle+offset)
   if clip=='investigate':head.rotation_euler.z=.11+.035*math.sin(cycle)
  if clip in ['listen','head_tilt']:
   hold=ease(.05,.40,p)*(1-ease(.80,1,p))
   neck.rotation_euler.z=-.10*hold;head.rotation_euler.z=.42*hold;head.rotation_euler.y=.13*hold
   chest.rotation_euler.z=.045*hold
   rig.pose.bones['ear_L'].rotation_euler.y=.27*hold;rig.pose.bones['ear_R'].rotation_euler.y=-.18*hold
   rig.pose.bones['ear_L'].rotation_euler.x=.06*hold*math.sin(cycle*2)
  if clip in ['search','hide_search','lost']:
   neck.rotation_euler.y=math.sin(cycle)*.23;head.rotation_euler.y=math.sin(cycle+.4)*.20
   head.rotation_euler.z=.06*math.sin(cycle+.8)
   rig.pose.bones['ear_L'].rotation_euler.y=.10*math.sin(cycle+.3)
   if clip=='hide_search':
    rig.pose.bones['spine'].rotation_euler.x=-.17*(.5+.5*math.sin(cycle));rig.pose.bones['upper_arm_R'].rotation_euler.x=-.65*(.5+.5*math.sin(cycle))
  if clip in ['attack','capture'] or clip.startswith('capture_'):
   windup=ease(0,.20,p);strike=ease(.20,.45,p);recoil=ease(.70,1,p);reach=strike*(1-recoil)
   rig.pose.bones['spine'].rotation_euler.x=.07*windup-.28*reach
   neck.rotation_euler.x=.13*reach
   rig.pose.bones['jaw'].rotation_euler.x=-.42*reach
   for side in ['L','R']:
    rig.pose.bones['upper_arm_'+side].rotation_euler.x=-1.02*reach
    rig.pose.bones['forearm_'+side].rotation_euler.x=.12*windup-.22*reach
    for i in range(4):rig.pose.bones['finger_'+str(i)+'_'+side].rotation_euler.x=-.18*reach*(1+i*.12)
   if clip.startswith('capture_'):
    variant=['front','side','rear','hide','corridor','chase','silent','dark'].index(clip[8:])
    head.rotation_euler.z=reach*[-.08,.24,-.20,.12,-.10,.10,.025,-.27][variant]
    chest.rotation_euler.y=reach*[0,.28,-.25,.08,-.12,.12,0,-.10][variant]
    rig.pose.bones['upper_arm_L'].rotation_euler.z=reach*[.12,.48,-.18,.28,.60,.18,.05,.28][variant]
    rig.pose.bones['upper_arm_R'].rotation_euler.x*= [1,.5,1.1,1.2,.25,1.2,.6,.8][variant]
    if variant==3:hips.location.z=-.07*reach
  bpy.context.view_layer.update()
  for side,offset in [('L',0),('R',.5)]:leg(side,(p+offset)%1,fast,walking,0)
  for pb in rig.pose.bones:
   pb.keyframe_insert(data_path='rotation_euler',frame=frame)
   # IK solves local joint locations too; all changes are sampled for glTF.
   pb.keyframe_insert(data_path='location',frame=frame)
 action['loop']=loop;action['duration']=duration
 # Linear sampled curves avoid spline overshoot at constrained ankle positions.
 for layer in action.layers:
  for strip in layer.strips:
   for bag in strip.channelbags:
    for curve in bag.fcurves:
     for key in curve.keyframe_points:key.interpolation='LINEAR'
print('ANIMATIONS_AUTHORED',len(clips),flush=True)
