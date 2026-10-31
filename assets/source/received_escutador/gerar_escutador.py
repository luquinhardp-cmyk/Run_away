import numpy as np, trimesh, math, os
from trimesh.transformations import rotation_matrix
OUT=os.path.dirname(__file__)
scene=trimesh.Scene()
rng=np.random.default_rng(12)
COL={'skin':(64,65,61,255),'dark':(28,29,28,255),'bone':(118,110,92,255),'scar':(94,66,58,255),'wet':(47,42,40,255),'teeth':(153,141,116,255),'eye':(8,9,9,255),'rust':(75,49,40,255)}
def add(mesh,name,color):
 mesh.visual.vertex_colors=np.tile(np.array(color,dtype=np.uint8),(len(mesh.vertices),1));scene.add_geometry(mesh,geom_name=name,node_name=name)
def ell(name,at,scale,color,sub=2):
 m=trimesh.creation.icosphere(subdivisions=sub,radius=1);m.apply_scale(scale);m.apply_translation(at);add(m,name,COL.get(color,color))
def bone(name,a,b,r1,r2,color,sections=11):
 a=np.array(a,float);b=np.array(b,float);d=b-a;L=np.linalg.norm(d)
 m=trimesh.creation.cone(radius=1,height=1,sections=sections) if r2<.001 else None
 # varying elliptical rings, slightly irregular
 rings=7;verts=[];faces=[]
 z=d/L;tmp=np.array([1.,0,0]) if abs(z[0])<.9 else np.array([0.,1,0]);x=np.cross(z,tmp);x/=np.linalg.norm(x);y=np.cross(z,x)
 for i in range(rings):
  t=i/(rings-1);r=r1*(1-t)+r2*t
  for j in range(sections):
   ang=j*2*np.pi/sections;irr=1+.055*np.sin(j*3+i*2)
   verts.append(a+d*t+r*irr*(x*np.cos(ang)+y*np.sin(ang)))
 for i in range(rings-1):
  for j in range(sections):
   u=i*sections+j;v=i*sections+(j+1)%sections;w=(i+1)*sections+j;q=(i+1)*sections+(j+1)%sections
   faces.extend([(u,v,w),(v,q,w)])
 for j in range(1,sections-1):
  faces.append((0,j+1,j))
  faces.append(((rings-1)*sections,(rings-1)*sections+j,(rings-1)*sections+j+1))
 m=trimesh.Trimesh(vertices=verts,faces=faces,process=False);add(m,name,COL.get(color,color))
# Coordinates: forward is -Z, up Y, height ~3.25m
# Legs bent and unequal
ell('pelvis',(0,1.37,.12),(.38,.26,.24),'skin',3)
for side in [-1,1]:
 x=side
 hip=(x*.25,1.40,.13);knee=(x*(.36 if side<0 else .42),.78,-.13 if side<0 else .22);ankle=(x*.40,.17,.10)
 bone(f'{side}_upper_leg',hip,knee,.20,.125,'skin',14)
 ell(f'{side}_knee',knee,(.16,.14,.15),'scar')
 bone(f'{side}_shin',knee,ankle,.13,.082,'skin',12)
 ell(f'{side}_ankle',ankle,(.11,.10,.11),'dark')
 foot=(x*.40,.095,-.19);ell(f'{side}_foot',foot,(.18,.10,.38),'dark',2)
 for i in range(3):
  tx=x*.40+(i-1)*.11
  bone(f'{side}_toe_{i}',(tx,.085,-.37),(tx+(i-1)*.025,.065,-.63),.065,.006,'bone',8)
# hunched torso, neck pitched forward
bone('spine_lower',(0,1.48,.17),(0,2.40,.32),.28,.33,'skin',18)
ell('ribcage',(0,2.12,.21),(.48,.62,.33),'skin',3)
ell('hunch',(0,2.51,.44),(.53,.35,.34),'dark',2)
# Exposed ribs as dark scar bands, forward side (-Z)
for i in range(5):
 yy=2.45-i*.17
 for side in [-1,1]:
  bone(f'rib_{i}_{side}',(side*.10,yy,-.103),(side*(.35+i*.012),yy-.065,-.09+i*.017),.032,.012,'scar',8)
# neck long with vertebral knobs
bone('neck',(0,2.48,.20),(.03,2.94,-.15),.19,.125,'skin',14)
for i in range(4):ell(f'neck_spur_{i}',(.02,2.56+i*.13,.31-i*.11),(.085,.07,.085),'bone',1)
# elongated skull and jaw
ell('cranium',(.02,3.05,-.23),(.235,.31,.27),'skin',3)
ell('face_muzzle',(.015,2.99,-.44),(.175,.16,.16),'wet',2)
ell('jaw',(0,2.75,-.44),(.20,.09,.20),'scar',2)
# mouth cavity dark, triangular teeth
ell('mouth_void',(0,2.81,-.568),(.14,.062,.034),'eye',2)
for i in range(8):
 xx=(i-3.5)*.037
 bone(f'upper_tooth_{i}',(xx,2.86,-.60),(xx,2.78-(i%2)*.013,-.615),.015,.001,'teeth',7)
 bone(f'lower_tooth_{i}',(xx,2.76,-.60),(xx,2.82+(i%3)*.009,-.605),.012,.001,'teeth',7)
# recessed small eyes, asymmetrical
for side in [-1,1]:
 ell(f'eye_socket_{side}',(side*.135,3.095,-.439),(.094,.065,.032),'dark',2)
 ell(f'eye_glint_{side}',(side*.135,3.097,-.464),(.019,.012,.008),'eye',1)
 # auditory cartilage horns, flared and ragged
 root=(side*.20,3.15,-.18)
 for k,(end,r) in enumerate([((side*.43,3.45,-.10),.09),((side*.55,3.28,-.04),.075),((side*.41,3.12,.13),.07)]):
  bone(f'auditory_fin_{side}_{k}',root,end,r,.004,'scar',9)
 ell(f'auditory_cavity_{side}',(side*.27,3.17,-.17),(.07,.14,.10),'dark',2)
# shoulder asymmetric long arms
for side in [-1,1]:
 x=side;sh=(x*.42,2.47,.18);el=(x*(.70 if side<0 else .67),1.69,-.10 if side<0 else .22);wrist=(x*(.65 if side<0 else .80),.93,-.30)
 ell(f'shoulder_{side}',sh,(.24,.24,.23),'skin',2)
 bone(f'upper_arm_{side}',sh,el,.18,.12,'skin',13)
 ell(f'elbow_{side}',el,(.14,.14,.14),'bone')
 bone(f'forearm_{side}',el,wrist,.16,.095,'skin',12)
 ell(f'palm_{side}',(wrist[0],wrist[1]-.10,wrist[2]-.04),(.145,.19,.09),'dark',2)
 for i in range(4):
  spread=(i-1.5)*.083;start=(wrist[0]+spread,.78,wrist[2]-.07)
  mid=(start[0]+x*.018,.57+(i%2)*.025,start[2]-.09)
  tip=(mid[0]+x*.018,.37+(i%3)*.028,mid[2]-.15)
  bone(f'finger_{side}_{i}',start,mid,.037,.026,'skin',8)
  bone(f'claw_{side}_{i}',mid,tip,.033,.002,'bone',8)
# back bony spikes and organic lesions
for i in range(8):
 yy=2.58-i*.16
 bone(f'spinal_spur_{i}',(0,yy,.46),(0,yy+.05,.63+(.08 if i<4 else 0)),.07,.004,'bone',9)
for i in range(24):
 side=rng.choice([-1,1]);y=rng.uniform(1.55,2.65);x=side*rng.uniform(.22,.43);z=rng.uniform(-.03,.40)
 ell(f'scar_nodule_{i}',(x,y,z),(rng.uniform(.022,.065),rng.uniform(.025,.08),.025),'scar',1)
# torn skin strips from abdomen
for i in range(5):
 x=(i-2)*.14
 bone(f'torn_tissue_{i}',(x,1.80,-.14),(x+.05,1.50-rng.uniform(0,.19),-.16),.065,.008,'wet',8)
path=os.path.join(OUT,'Escutador_Criatura_Original.glb')
scene.export(path)
print(path,os.path.getsize(path),len(scene.geometry),sum(len(m.faces) for m in scene.geometry.values()))
