from pathlib import Path
root=Path('assets/materials'); root.mkdir(exist_ok=True)
names=['aged_concrete','damp_concrete','cracked_floor','peeling_plaster','rusted_iron','rotten_wood','mud_leaves','torn_fabric','organic_residue','creature_skin']
for name in names:
 s='[gd_resource type="StandardMaterial3D" load_steps=4 format=3]\n'
 for i,suffix in enumerate(['albedo','normal','orm'],1): s+=f'[ext_resource type="Texture2D" path="res://assets/textures/pbr/{name}_{suffix}.png" id="{i}"]\n'
 s+='\n[resource]\n'+f'resource_name = "{name}"\n'
 s+='albedo_texture = ExtResource("1")\nnormal_enabled = true\nnormal_scale = 0.8\nnormal_texture = ExtResource("2")\nroughness = 1.0\nroughness_texture = ExtResource("3")\nroughness_texture_channel = 1\nmetallic = 1.0\nmetallic_texture = ExtResource("3")\nmetallic_texture_channel = 2\nao_enabled = true\nao_texture = ExtResource("3")\nao_texture_channel = 0\ntexture_filter = 3\n'
 (root/(name+'.tres')).write_text(s,encoding='utf-8')
