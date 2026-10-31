"""Blender 4.5: original, UV-unwrapped rural/industrial asset library, in metres.
Run: blender --background --python tools/art/build_geometry_library.py
No external models or textures. Godot assigns the existing shared PBR library.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'assets/models/library'; OUT.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT/'assets/source'; SOURCE.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
random.seed(181104)
MATS = {}
for name, color, metallic in [
 ('rusted_iron',(.18,.105,.066,1),.65),('brushed_metal',(.34,.35,.30,1),.8),
 ('wet_steel',(.13,.18,.16,1),.7),('industrial_sheet',(.17,.22,.19,1),.65),
 ('rotten_wood',(.17,.10,.052,1),0),('damp_wood',(.23,.17,.09,1),0),
 ('aged_plastic',(.105,.12,.105,1),0),('worn_rubber',(.025,.03,.027,1),0),
 ('dirty_glass',(.21,.28,.22,1),.05),('old_upholstery',(.16,.19,.14,1),0),
 ('torn_fabric',(.39,.34,.24,1),0),('aged_concrete',(.22,.23,.20,1),0),
 ('moss',(.04,.09,.045,1),0)]:
 m=bpy.data.materials.new(name); m.diffuse_color=color; m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=color
 bs.inputs['Metallic'].default_value=metallic; bs.inputs['Roughness'].default_value=.78
 MATS[name]=m
PARTS=[]
def finish(o,name,mat,bevel=0):
 o.name=name; o.data.materials.append(MATS[mat]); PARTS.append(o)
 bpy.context.view_layer.objects.active=o
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Worn chamfer','BEVEL'); mod.width=bevel; mod.segments=2
  bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def box(name,p,s,mat='rusted_iron',bevel=.006,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p,rotation=rot)
 o=bpy.context.object; o.dimensions=s
 return finish(o,name,mat,min(bevel,min(s)*.22))
def cyl(name,p,r,h,mat='rusted_iron',axis='Z',vertices=16,r2=None):
 rot={'Z':(0,0,0),'Y':(math.pi/2,0,0),'X':(0,math.pi/2,0)}[axis]
 bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=h,location=p,rotation=rot)
 return finish(bpy.context.object,name,mat,min(.002,h*.2,r*.1) if r>.02 else 0)
def pipe(name,pts,r,mat='rusted_iron',sides=8):
 for i,(a,b) in enumerate(zip(pts,pts[1:])):
  a,b=Vector(a),Vector(b); o=cyl(name+str(i),(a+b)*.5,r,(a-b).length,mat,vertices=sides)
  o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
def torus(name,p,major,minor,mat='rusted_iron',rot=(0,0,0),segments=20):
 bpy.ops.mesh.primitive_torus_add(major_segments=segments,minor_segments=6,location=p,rotation=rot,major_radius=major,minor_radius=minor)
 return finish(bpy.context.object,name,mat)
def ring(name,p,outer,inner,height,mat='brushed_metal',segments=24):
 verts=[]
 for z in [-height/2,height/2]:
  for radius in [outer,inner]:
   verts.extend([(p[0]+radius*math.cos(i*math.tau/segments),p[1]+radius*math.sin(i*math.tau/segments),p[2]+z) for i in range(segments)])
 faces=[]
 for i in range(segments):
  j=(i+1)%segments; n=segments
  faces.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
 mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
 o=bpy.data.objects.new(name,mesh); bpy.context.collection.objects.link(o)
 return finish(o,name,mat,.001)
def bolt(p,axis='Z',r=.012): cyl('Hex bolt',p,r,.012,'brushed_metal',axis,6)
def lathe(name,profile,mat='dirty_glass',segments=20):
 verts=[];faces=[]
 for z,r in profile:
  verts.extend([(r*math.cos(i*math.tau/segments),r*math.sin(i*math.tau/segments),z) for i in range(segments)])
 for j in range(len(profile)-1):
  for i in range(segments):
   a=j*segments+i;b=j*segments+(i+1)%segments
   faces.append((a,b,b+segments,a+segments))
 faces.extend([tuple(range(segments-1,-1,-1)),tuple((len(profile)-1)*segments+i for i in range(segments))])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);return finish(o,name,mat)
def key():
 ring('Open key bow',(-.068,0,0),.041,.026,.012)
 box('Key shoulder',(-.025,0,0),(.033,.025,.014),'brushed_metal',.003)
 box('Key shaft',(.037,0,0),(.11,.016,.012),'brushed_metal',.002)
 for x,y in [(.018,.015),(.045,.020),(.077,.013)]: box('Cut tooth',(x,-y,0),(.013,y*1.5,.012),'brushed_metal',.001)
def fuse():
 cyl('Ceramic cartridge',(0,0,0),.029,.13,'torn_fabric','X',24)
 for x in [-.075,.075]:
  cyl('Contact cap',(x,0,0),.033,.027,'brushed_metal','X',24)
  cyl('Contact lip',(x+(.013 if x>0 else -.013),0,0),.034,.004,'brushed_metal','X',24)
 box('Rating band',(0,-.029,0),(.06,.002,.019),'aged_plastic',0)
def flashlight():
 cyl('Grip',(0,0,0),.036,.22,'worn_rubber','X',24)
 for x in [-.09+i*.025 for i in range(8)]: cyl('Grip ring',(x,0,0),.039,.007,'aged_plastic','X',24)
 cyl('Bezel',(.13,0,0),.06,.08,'brushed_metal','X',24,r2=.043)
 cyl('Recessed lens',(.171,0,0),.049,.006,'dirty_glass','X',24)
 cyl('Reflector',(.169,0,0),.022,.009,'brushed_metal','X',16)
 cyl('Tail cap',(-.12,0,0),.042,.022,'rusted_iron','X',20)
 box('Switch',(.04,0,.039),(.036,.019,.012),'aged_plastic',.003)
 torus('Lanyard',(-.135,0,0),.024,.004,rot=(0,math.pi/2,0))
def card():
 box('Card', (0,0,0),(.21,.135,.007),'aged_plastic',.006)
 box('Contact chip',(-.05,0,.004),(.035,.035,.001),'brushed_metal',.001)
 box('Stripe',(0,.035,.004),(.19,.019,.001),'worn_rubber',0)
 for x in [-.04,0,.04]:box('Engraved identity',(x,-.03,.004),(.023,.007,.001),'torn_fabric',0)
def wrench():
 box('Forged handle',(0,0,0),(.033,.25,.018),'brushed_metal',.007)
 ring('Box end',(0,-.15,0),.037,.025,.021)
 # A real open jaw, with an exposed void rather than a cube head.
 box('Jaw heel',(0,.132,0),(.07,.035,.022),'brushed_metal',.006)
 for side in [-1,1]: box('Jaw prong',(side*.028,.166,0),(.023,.06,.022),'brushed_metal',.004,rot=(0,0,side*.12))
def bottle():
 lathe('Glass bottle',[(0,.046),(.012,.061),(.22,.059),(.255,.027),(.31,.025),(.32,.026)])
 cyl('Bottle rim',(0,0,.315),.029,.013,'brushed_metal',vertices=20)
 box('Torn label',(0,-.059,.14),(.075,.003,.09),'torn_fabric',.002)
def can():
 lathe('Dented can',[(-.13,.077),(-.12,.086),(-.05,.08),(.04,.087),(.12,.083),(.13,.076)],'industrial_sheet',24)
 for z in [-.125,.125]:torus('Rolled rim',(0,0,z),.080,.005,'brushed_metal',segments=24)
 ring('Pull tab',(0,0,.133),.023,.012,.003)
def crate(size=(.65,.55,.6)):
 w,d,h=size
 for y in [-d/2,d/2]:
  for i in range(4):box('Individual side plank',(0,y,(i+.5)*h/4-h/2),(w,.035,h/4-.008),'rotten_wood',.004)
 for x in [-w/2,w/2]:
  for i in range(4):box('End plank',(x,0,(i+.5)*h/4-h/2),(.035,d,h/4-.008),'damp_wood',.004)
 for i in range(5):box('Lid plank',(-w/2+(i+.5)*w/5,0,h/2),(w/5-.007,d,.025),'rotten_wood',.003)
 box('Bottom',(0,0,-h/2),(w,d,.025),'damp_wood',.003)
 for x in [-w*.39,w*.39]:
  for y in [-d*.53,d*.53]:
   box('Corner brace',(x,y,0),(.047,.03,h*.94),'damp_wood',.003)
   for z in [-h*.37,h*.37]:bolt((x,y*1.03,z),'Y',.007)
def bucket():
 # Hollow wall with a separately closed base; no opaque solid cylinder.
 lathe('Bucket shell',[(-.15,.105),(.14,.15),(.15,.15),(.15,.139),(-.137,.097)],'wet_steel',24)
 torus('Rolled bucket lip',(0,0,.15),.146,.006,'brushed_metal')
 pts=[(.147*math.cos(i*math.pi/12),0,.15+.16*math.sin(i*math.pi/12)) for i in range(13)]
 pipe('Wire handle',pts,.006,'rusted_iron',6)
 cyl('Handle grip',(0,0,.30),.011,.10,'worn_rubber','X',12)
def chair():
 box('Padded seat',(0,0,.045),(.45,.43,.075),'old_upholstery',.018)
 for x in [-.19,.19]:
  for y in [-.17,.17]:pipe('Splayed leg',[(x*1.08,y*1.08,-.43),(x,y,0)],.022,'rusted_iron')
  pipe('Back upright',[(x,.17,-.03),(x,.19,.48)],.021)
  pipe('Side brace',[(x,-.17,-.24),(x,.17,-.24)],.012)
 box('Worn backrest',(0,.19,.32),(.43,.055,.26),'old_upholstery',.02,rot=(.06,0,.025))
 for x in [-.18,.18]:bolt((x,.152,.32),'Y',.01)
def trolley():
 for z in [-.26,.23]:
  box('Rolled tray',(0,0,z),(.68,.52,.035),'wet_steel',.01)
  for y in [-.25,.25]:box('Tray lip',(0,y,z+.025),(.68,.018,.055),'rusted_iron',.004)
 for x in [-.29,.29]:
  for y in [-.21,.21]:
   pipe('Tubular leg',[(x,y,-.30),(x,y,.39)],.018,'brushed_metal')
   cyl('Caster wheel',(x,y,-.35),.055,.028,'worn_rubber','X',16)
 for y in [-.21,.21]:pipe('Push handle',[(-.29,y,.24),(-.29,y,.44),(.29,y,.44),(.29,y,.24)],.016)
def table():
 box('Bench top',(0,0,.70),(1.8,.85,.09),'damp_wood',.012)
 for i in range(5):box('Separate top boards',(-.72+i*.36,0,.752),(.35,.85,.017),'rotten_wood',.004)
 for x in [-.76,.76]:
  for y in [-.32,.32]:box('Bench leg',(x,y,.35),(.075,.075,.70),'rusted_iron',.007)
  box('Leg crossbar',(x,0,.12),(.055,.7,.06),'rusted_iron',.004)
 box('Long stretcher',(0,.28,.24),(1.55,.05,.07),'rusted_iron',.005)
 for x in [-.76,.76]:
  for y in [-.32,.32]:bolt((x,y,.77),'Z')
def shelf():
 for x in [-.7,.7]:
  for y in [-.32,.32]:
   box('Upright',(x,y,1.08),(.035,.045,2.16),'rusted_iron',.004)
   for z in [.3,.9,1.5,2.0]:bolt((x,y-.025,z),'Y',.008)
 for z in [.12,.77,1.42,2.08]:
  box('Shelf deck',(0,0,z),(1.45,.7,.035),'industrial_sheet',.004)
  box('Folded front lip',(0,-.35,z-.025),(1.45,.018,.07),'rusted_iron',.003)
 pipe('Diagonal rear brace',[(-.7,.33,.2),(.7,.33,2.0)],.012)
def locker():
 for x in [-.53,.53]:box('Locker side',(x,0,1),(.035,.96,2),'industrial_sheet',.006)
 box('Locker back',(0,.47,1),(1.07,.025,2),'industrial_sheet',.004)
 for z in [.04,1.96]:box('Locker cap',(0,0,z),(1.08,.96,.04),'rusted_iron',.004)
 box('Lower door',(0,-.485,.62),(1.01,.035,1.12),'industrial_sheet',.006)
 box('Upper door',(0,-.485,1.89),(1.01,.035,.15),'industrial_sheet',.004)
 for z in [1.24,1.38,1.52,1.66,1.8]:box('Slanted louver',(0,-.49,z),(.99,.045,.065),'industrial_sheet',.003,rot=(.3,0,0))
 for x in [-.5,.5]:box('Front stile',(x,-.49,1),(.035,.045,1.9),'rusted_iron',.003)
 pipe('Locker handle',[(.36,-.51,.86),(.36,-.55,.86),(.36,-.55,1.02),(.36,-.51,1.02)],.012,'brushed_metal')
 for z in [.28,1.72]:cyl('Hinge barrel',(-.50,-.52,z),.022,.09,'brushed_metal')
def generator():
 # Open skid, recognisable diesel engine, alternator, radiator and upper fuel tank.
 for x in [-.56,.56]:box('Skid rail',(x,0,.09),(.11,.73,.18),'rusted_iron',.012)
 for y in [-.30,.30]:box('Frame crossmember',(0,y,.12),(1.2,.08,.08),'rusted_iron',.008)
 box('Engine block',(-.15,0,.67),(.63,.5,.63),'wet_steel',.035)
 for x in [-.35,-.12,.11]:
  cyl('Cylinder head',(x,0,1.06),.11,.28,'brushed_metal',vertices=16)
  box('Valve cover',(x,0,1.23),(.18,.33,.08),'industrial_sheet',.012)
  pipe('Fuel injection line',[(x,-.18,.7),(x,-.25,.9),(x,-.1,1.25)],.012,'brushed_metal')
 cyl('Alternator',(.39,0,.70),.28,.37,'industrial_sheet','X',24)
 for x in [.27,.33,.39,.45,.51]:cyl('Cooling fin',(x,0,.70),.29,.018,'rusted_iron','X',24)
 box('Radiator',(-.57,0,.77),(.10,.62,.81),'aged_plastic',.012)
 for z in [.42+i*.065 for i in range(11)]:box('Radiator grille',(-.63,-.01,z),(.018,.56,.018),'brushed_metal',.002)
 pipe('Exhaust manifold',[(-.40,.25,1.03),(.1,.25,1.03),(.1,.29,1.52),(.4,.29,1.52)],.044)
 cyl('Muffler',(.20,.29,1.52),.10,.39,'rusted_iron','X',16)
 for x in [-.55,.55]:pipe('Protective upright',[(x,.33,.12),(x,.33,1.89)],.032)
 box('Fuel reservoir',(0,.08,1.77),(1.07,.54,.26),'industrial_sheet',.025)
 cyl('Fuel cap',(.34,.05,1.93),.055,.035,'brushed_metal',vertices=12)
 box('Instrument enclosure',(.30,-.33,1.36),(.45,.16,.32),'aged_plastic',.012)
 for x in [.19,.39]:
  cyl('Gauge rim',(x,-.423,1.40),.062,.02,'brushed_metal','Y',20)
  cyl('Gauge face',(x,-.437,1.40),.048,.005,'dirty_glass','Y',20)
  box('Gauge needle',(x,-.442,1.41),(.005,.003,.05),'torn_fabric',0,rot=(0,.4,0))
 for x in [.18,.28,.39]:cyl('Control switch',(x,-.44,1.27),.019,.019,'worn_rubber','Y',12)
 pipe('Power cable',[(.5,.15,.4),(.59,.25,.2),(.4,.33,.12),(.25,.34,.25)],.021,'worn_rubber')
 for x in [-.56,.56]:
  for y in [-.27,.27]:bolt((x,y,.19),'Z',.018)
def panel():
 box('Panel back',(0,.055,0),(.68,.06,.88),'industrial_sheet',.012)
 for x in [-.34,.34]:box('Enclosure wall',(x,0,0),(.035,.18,.88),'rusted_iron',.005)
 for z in [-.44,.44]:box('Enclosure rim',(0,0,z),(.70,.18,.035),'rusted_iron',.004)
 box('Recessed insulated board',(0,-.01,0),(.57,.04,.74),'aged_plastic',.006)
 for x in [-.17,0,.17]:
  box('Fuse carrier',(x,-.07,.11),(.11,.03,.29),'torn_fabric',.004)
  for z in [-.025,.245]:box('Spring contact',(x,-.105,z),(.078,.035,.035),'brushed_metal',.003)
  if x !=0:cyl('Installed cartridge',(x,-.10,.11),.024,.20,'torn_fabric',vertices=16)
  pipe('Wiring',[(x,-.06,-.04),(x,-.06,-.28),(x*.8,-.06,-.35)],.008,'worn_rubber',6)
 box('Breaker',(-.16,-.08,-.25),(.11,.05,.13),'industrial_sheet',.004)
 box('Breaker lever',(-.16,-.115,-.24),(.035,.025,.05),'worn_rubber',.003)
 for x in [-.29,.29]:
  for z in [-.38,.38]:bolt((x,-.10,z),'Y',.012)
def door(wood=False,exit=False):
 w,h,d=1.72,2.52,.115
 if wood:
  for i in range(7):box('Door plank',(-w/2+(i+.5)*w/7,0,0),(w/7-.008,d,h),'rotten_wood',.009)
  for z in [-.82,.82]:box('Iron strap',(0,-.07,z),(w*.94,.025,.09),'rusted_iron',.004)
 else:
  box('Heavy steel leaf',(0,0,0),(w,d,h),'industrial_sheet',.014)
  for x in [-.77,.77]:box('Folded stile',(x,-.073,0),(.09,.035,2.4),'rusted_iron',.005)
  for z in [-1.15,1.15]:box('Reinforcement',(0,-.073,z),(1.6,.035,.10),'rusted_iron',.005)
  for z in [-.7,-.60,-.50,-.40]:box('Recessed vent slot',(0,-.061,z),(.66,.007,.028),'worn_rubber',.003)
 for z in [-.88,.82]:
  cyl('Pin hinge',(-.86,0,z),.035,.19,'brushed_metal',vertices=12)
  for x in [-.75,-.65]:bolt((x,-.091,z),'Y',.012)
 box('Lock escutcheon',(.61,-.086,-.10),(.13,.035,.28),'brushed_metal',.007)
 ring('Keyhole rim',(.61,-.11,-.17),.018,.008,.006)
 pipe('Lever handle',[(.61,-.1,0),(.61,-.17,0),(.39,-.17,0)],.018,'brushed_metal')
 box('Keyhole void',(.61,-.109,-.17),(.012,.004,.035),'worn_rubber',.002)
 if exit:pipe('Panic bar',[(-.65,-.10,-.1),(-.65,-.2,-.1),(.65,-.2,-.1),(.65,-.1,-.1)],.035,'brushed_metal')
def radio():
 box('Radio case',(0,0,0),(.48,.22,.32),'aged_plastic',.025)
 box('Speaker recess',(-.1,-.116,-.01),(.22,.008,.24),'worn_rubber',.008)
 for x in [-.19+i*.025 for i in range(8)]:box('Speaker bar',(x,-.125,-.01),(.007,.008,.23),'brushed_metal',.001)
 box('Tuning scale',(.13,-.122,.07),(.15,.012,.065),'dirty_glass',.004)
 for x in [.08,.17]:cyl('Tuning knob',(x,-.13,-.07),.027,.03,'worn_rubber','Y',16)
 pipe('Carrying handle',[(-.16,0,.16),(-.16,0,.23),(.16,0,.23),(.16,0,.16)],.013)
 pipe('Telescopic aerial',[(.19,.04,.15),(.23,.06,.44)],.004,'brushed_metal')
def alarm():
 box('Alarm mounting plate',(0,0,0),(.30,.07,.34),'rusted_iron',.014)
 cyl('Siren housing',(0,-.10,.03),.12,.17,'industrial_sheet','Y',20,r2=.06)
 cyl('Siren opening',(0,-.19,.03),.09,.009,'worn_rubber','Y',20)
 for x in [-.1,.1]:box('Protective cage',(x,-.2,.03),(.014,.015,.2),'brushed_metal',.003)
 for x in [-.12,.12]:
  for z in [-.13,.13]:bolt((x,-.05,z),'Y')
def battery():
 cyl('Battery cell',(0,0,0),.015,.05,'aged_plastic',vertices=20)
 for z in [-.027,.027]:cyl('Battery terminal',(0,0,z),.013,.005,'brushed_metal',vertices=20)
 cyl('Positive nub',(0,0,.031),.006,.004,'brushed_metal',vertices=16)
def rock():
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=.5)
 o=bpy.context.object
 for v in o.data.vertices:
  v.co*=random.uniform(.72,1.20);v.co.z*=.65
 finish(o,'Fractured stone','aged_concrete')
def tank():
 lathe('Pressure vessel',[(0,.06),(.08,.23),(.22,.29),(1.75,.29),(1.91,.23),(2,.06)],'industrial_sheet',24)
 for z in [.35,1.65]:torus('Vessel hoop',(0,0,z),.295,.018)
 for x in [-.19,.19]:box('Tank foot',(x,0,.1),(.10,.45,.2),'rusted_iron',.009)
 pipe('Outlet',[(0,0,1.99),(0,0,2.15),(.28,0,2.15)],.04)
 torus('Valve handwheel',(.22,0,2.23),.10,.012,'brushed_metal')
 for i in range(4):pipe('Valve spoke',[(.22,0,2.23),(.22+.095*math.cos(i*math.pi/2),.095*math.sin(i*math.pi/2),2.23)],.006,'brushed_metal')
def motor():
 cyl('Motor housing',(0,0,.30),.26,.55,'wet_steel','X',24)
 for x in [-.25+i*.05 for i in range(11)]:cyl('Cooling ring',(x,0,.30),.28,.014,'industrial_sheet','X',24)
 cyl('Shaft',(.37,0,.30),.065,.22,'brushed_metal','X',16)
 for x in [-.18,.18]:box('Mounting foot',(x,0,.045),(.12,.52,.09),'rusted_iron',.009)
 box('Terminal box',(0,0,.59),(.22,.23,.13),'aged_plastic',.008)
def press():
 box('Press base',(0,0,.12),(.90,.60,.24),'rusted_iron',.015)
 for x in [-.38,.38]:box('Press upright',(x,0,.86),(.14,.46,1.48),'industrial_sheet',.015)
 box('Press crossbeam',(0,0,1.55),(1,.55,.18),'rusted_iron',.015)
 box('Work bed',(0,0,.77),(.72,.55,.12),'brushed_metal',.012)
 cyl('Hydraulic cylinder',(0,0,1.34),.13,.36,'industrial_sheet',vertices=20)
 cyl('Piston',(0,0,1.05),.045,.34,'brushed_metal',vertices=20)
 pipe('Hydraulic hose',[(0,.18,1.40),(.27,.27,1.35),(.30,.25,.3)],.017,'worn_rubber')
 for x in [-.37,.37]:
  for z in [.5,.8,1.1]:bolt((x,-.245,z),'Y',.016)
def window():
 for x in [-.7,.7]:box('Window jamb',(x,0,0),(.09,.16,1.25),'rotten_wood',.012)
 for z in [-.58,.58]:box('Window sill',(0,0,z),(1.5,.21,.10),'damp_wood',.012)
 box('Mullion',(0,0,0),(.055,.12,1.1),'rusted_iron',.005)
 # Broken panes leave a real open central view; glass is opaque shards, avoiding sorting.
 for side in [-1,1]:
  mesh=bpy.data.meshes.new('Broken pane');mesh.from_pydata([(side*.65,.025,-.5),(side*.65,.025,.48),(side*.12,.025,.48),(side*.3,.025,.2),(side*.48,.025,-.1)],[],[(0,1,2),(0,2,3),(0,3,4)])
  o=bpy.data.objects.new('Glass remnant',mesh);bpy.context.collection.objects.link(o);finish(o,'Broken glass','dirty_glass')
 for x in [-.48,.48]:box('Security bar',(x,-.08,0),(.025,.03,1.15),'rusted_iron',.003)
def drain():
 box('Drain frame',(0,0,0),(.72,.45,.025),'rusted_iron',.004)
 box('Dark recess',(0,0,.015),(.65,.38,.005),'worn_rubber',0)
 for i in range(11):box('Grate slat',(-.3+i*.06,0,.027),(.018,.37,.018),'brushed_metal',.002)
def roof_module():
 box('Roof purlin',(0,0,0),(3.8,.12,.14),'rotten_wood',.012)
 for side in [-1,1]:pipe('Triangulated truss',[(side*1.8,0,0),(0,0,.48),(0,0,0)],.045,'rusted_iron',8)
 for x in [-1.2,-.6,.6,1.2]:pipe('Truss web',[(x,0,0),(x*.5,0,.24)],.025,'rusted_iron')
def pallet():
 for x in [-.43,0,.43]:box('Runner',(x,0,.09),(.09,.8,.18),'damp_wood',.006)
 for i in range(7):box('Pallet deck',(0,-.4+(i+.5)*.8/7,.20),(1,.105,.045),'rotten_wood',.004)
def monitor():
 box('CRT enclosure',(0,.035,.12),(.60,.42,.43),'aged_plastic',.035)
 box('Recessed screen',(0,-.19,.14),(.49,.018,.31),'dirty_glass',.018)
 box('Screen rim',(0,-.201,.14),(.53,.01,.35),'worn_rubber',.016)
 box('Screen glass',(0,-.208,.15),(.48,.008,.29),'dirty_glass',.014)
 for x in [.16,.22]:cyl('Monitor knob',(x,-.22,-.035),.014,.012,'brushed_metal','Y',12)
 box('Monitor neck',(0,.04,-.17),(.11,.14,.20),'rusted_iron',.01)
 box('Monitor foot',(0,0,-.28),(.35,.30,.035),'aged_plastic',.01)
 for i in range(6):box('Vent recess',(.303,.02+i*.04,.17),(.006,.02,.19),'worn_rubber',.001)
def door_frame():
 for x in [-.93,.93]:
  box('Folded jamb',(x,0,0),(.07,.25,2.67),'rusted_iron',.009)
  box('Door stop',(x*.95,.045,0),(.025,.05,2.61),'industrial_sheet',.003)
 box('Lintel',(0,0,1.32),(1.93,.25,.07),'rusted_iron',.008)
 for x in [-.92,.92]:
  for z in [-.9,0,.9]:bolt((x,-.133,z),'Y',.012)
def drawer_handle():
 for x in [-.10,.10]:box('Handle mounting plate',(x,0,0),(.04,.017,.05),'rusted_iron',.004)
 pipe('Drawer pull',[(-.1,-.01,0),(-.1,-.05,0),(.1,-.05,0),(.1,-.01,0)],.009,'brushed_metal',10)
 for x in [-.10,.10]:bolt((x,-.012,0),'Y',.006)
def mechanical_part():
 ring('Open shaft collar',(0,0,0),.08,.032,.035,'rusted_iron',24)
 for i in range(12):
  a=i*math.tau/12
  box('Gear tooth',(.088*math.cos(a),.088*math.sin(a),0),(.025,.025,.035),'brushed_metal',.002,rot=(0,0,a))
 cyl('Broken shaft',(0,0,-.06),.025,.09,'brushed_metal',vertices=12)
def tree(variant):
 height=[9,11,12][variant]
 points=[(0,0,0),(.12,-.13,2),(-.15,.02,4),(.3,.1,6),(.1,-.2,height)]
 for i in range(4):
  a,b=Vector(points[i]),Vector(points[i+1]);o=cyl('Bent trunk',(a+b)*.5,.45*(1-i*.20),(b-a).length,'rotten_wood',vertices=9,r2=.45*(.80-i*.20));o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
 for i in range(6):
  angle=i*2.4+.4;length=random.uniform(.9,1.8)
  pipe('Exposed root',[(0,0,.4),(math.cos(angle)*length*.55,math.sin(angle)*length*.55,.09),(math.cos(angle)*length,math.sin(angle)*length,0)],.10,'rotten_wood',7)
 for i in range(11):
  angle=i*2.39;z=2.8+i*.48;length=random.uniform(1.5,2.8)*(1-i*.035)
  end=(math.cos(angle)*length,math.sin(angle)*length,z+random.uniform(.4,1.3))
  pipe('Asymmetric branch',[(0,0,z),(end[0]*.6,end[1]*.6,z+.35),end],.07*(1-i*.04),'rotten_wood',7)
  pipe('Fork',[end,(end[0]+math.cos(angle+.7)*.65,end[1]+math.sin(angle+.7)*.65,end[2]+.8)],.024,'rotten_wood',6)
  if variant==1:
   for j in range(2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=random.uniform(1,1.6),location=(end[0]+j*.4,end[1],end[2]))
    o=bpy.context.object
    for v in o.data.vertices:v.co*=random.uniform(.75,1.2)
    o.scale=(1,.8,.7);finish(o,'Irregular leaf cluster','moss')
 if variant==2:
  for layer in range(7):
   z=3+layer*1.15;r=3.1-layer*.37
   # Ragged radial branch fans instead of identical stacked cones.
   verts=[(0,0,z+2.6)]+[(math.cos(i*math.tau/15)*r*random.uniform(.78,1.15),math.sin(i*math.tau/15)*r*random.uniform(.78,1.15),z+random.uniform(-.25,.25)) for i in range(15)]
   faces=[(0,1+i,1+(i+1)%15) for i in range(15)]
   mesh=bpy.data.meshes.new('Needle fan');mesh.from_pydata(verts,[],faces);mesh.update()
   o=bpy.data.objects.new('Broken pine whorl',mesh);bpy.context.collection.objects.link(o);finish(o,'Pine whorl','moss')

BUILDERS={'key':key,'fuse':fuse,'flashlight':flashlight,'security_card':card,'wrench':wrench,'bottle':bottle,'can':can,'crate':crate,'bucket':bucket,'chair':chair,'trolley':trolley,'workbench':table,'shelf':shelf,'locker':locker,'diesel_generator':generator,'fuse_panel':panel,'door_steel':door,'door_wood':lambda:door(True),'door_exit':lambda:door(exit=True),'radio':radio,'alarm':alarm,'battery':battery,'rock':rock,'tank':tank,'motor':motor,'workshop_press':press,'broken_window':window,'drain':drain,'roof_truss':roof_module,'pallet':pallet,'tree_dead':lambda:tree(0),'tree_broadleaf':lambda:tree(1),'tree_pine':lambda:tree(2),'crt_monitor':monitor,'door_frame':door_frame,'drawer_handle':drawer_handle,'mechanical_part':mechanical_part}
manifest={'units':'metres','origin':'Original Blender procedural authored models; no third-party assets','models':{}}
PLACEHOLDERS={'key','fuse','flashlight','security_card','wrench','bottle','can','bucket','diesel_generator','fuse_panel','radio','alarm','crt_monitor','motor','mechanical_part','rock'}
ABSENT={'battery','door_frame','drawer_handle'}
saved=[]
for name,build in BUILDERS.items():
 PARTS=[];build(); part_names=[o.name for o in PARTS]
 bpy.ops.object.select_all(action='DESELECT')
 for o in PARTS:o.select_set(True)
 bpy.context.view_layer.objects.active=PARTS[0]
 bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 if not name.startswith('tree_'):
  bounds=[Vector(v) for v in o.bound_box];center=(Vector(tuple(min(v[i] for v in bounds) for i in range(3)))+Vector(tuple(max(v[i] for v in bounds) for i in range(3))))*.5
  for v in o.data.vertices:v.co-=center
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
 bpy.ops.mesh.normals_make_consistent(inside=False)
 bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.015,correct_aspect=True,scale_to_bounds=False)
 bpy.ops.object.mode_set(mode='OBJECT')
 # Tiled PBR, consistent density: two texture repeats per metre, not an atlas
 # stretched over the entire object. Overlap between tiling islands is intentional.
 uv_layer=o.data.uv_layers.active.data;uv_area=0.0
 for polygon in o.data.polygons:
  coords=[uv_layer[j].uv.copy() for j in polygon.loop_indices]
  for j in range(1,len(coords)-1):
   a,b=coords[j]-coords[0],coords[j+1]-coords[0];uv_area+=abs(a.x*b.y-a.y*b.x)*.5
 density=math.sqrt(sum(p.area for p in o.data.polygons)/max(uv_area,1e-9))*2
 for loop in uv_layer:loop.uv*=density
 tris=sum(len(p.vertices)-2 for p in o.data.polygons)
 uv=bool(o.data.uv_layers)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_cameras=False,export_lights=False)
 copy=o.copy();copy.data=o.data.copy();bpy.context.collection.objects.link(copy)
 o.select_set(False);copy.select_set(True);bpy.context.view_layer.objects.active=copy
 dec=copy.modifiers.new('Distance geometry','DECIMATE');dec.ratio=.55
 bpy.ops.object.modifier_apply(modifier=dec.name)
 low_tris=sum(len(p.vertices)-2 for p in copy.data.polygons)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'_low.glb')),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_cameras=False,export_lights=False)
 bpy.data.objects.remove(copy,do_unlink=True)
 manifest['models'][name]={'triangles':tris,'triangles_low':low_tris,'uv':uv,'parts':part_names,'materials':[m.name for m in o.data.materials],'dimensions_blender_xyz':list(o.dimensions),'classification_before':'D' if name in ABSENT else ('C' if name in PLACEHOLDERS else 'B'),'classification_after':'B','uv_density_repeats_per_metre':2,'note':'Authored procedural asset; visual polish and real-device profiling still required.'}
 saved.append(o);o.hide_set(True)
 print('ASSET_DONE',name,tris,low_tris,flush=True)
for i,o in enumerate(saved):o.hide_set(False);o.location=((i%7)*5,(i//7)*5,0)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'rural_industrial_library.blend'))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('GEOMETRY_LIBRARY_COMPLETE',len(saved),flush=True)
