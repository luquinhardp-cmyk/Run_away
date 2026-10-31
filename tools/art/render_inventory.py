"""Render inventory thumbnails from the actual GLB library, never placeholder drawings."""
import bpy, sys
import re, json
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
out=root/"assets/ui/items"
out.mkdir(parents=True,exist_ok=True)
models=["key","fuse","flashlight","security_card","mechanical_part","can","wrench","bottle","rock","crate","bucket","chair","trolley","rubber_ball"]
arguments=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
if arguments: models=[name for name in models if name in arguments]
for model in models:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene
    scene.render.engine="CYCLES"
    scene.cycles.samples=24
    scene.render.resolution_x=256
    scene.render.resolution_y=256
    scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.render.image_settings.file_format="PNG"
    scene.render.image_settings.color_mode="RGBA"
    if model=='rubber_ball':
        # The game represents this item with a procedural SphereMesh, not a GLB.
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,radius=.15)
        material=bpy.data.materials.new('worn_rubber')
        bpy.context.object.data.materials.append(material)
    else:
        bpy.ops.import_scene.gltf(filepath=str(root/"assets/models/library"/(model+".glb")))
    names=set(json.loads(re.search(r'const NAMES := (\[.*\])',(root/'scripts/systems/horror_art.gd').read_text()).group(1)))
    for material in bpy.data.materials:
        name=material.name
        if name not in names or name=='rusted_iron': name='weathered_iron'
        material.use_nodes=True
        nodes=material.node_tree.nodes
        links=material.node_tree.links
        bsdf=nodes.get('Principled BSDF')
        if not bsdf: continue
        for suffix,socket in [('albedo','Base Color'),('normal',None),('orm',None)]:
            texture=nodes.new('ShaderNodeTexImage')
            texture.image=bpy.data.images.load(str(root/'assets/textures/pbr'/(name+'_'+suffix+'.png')),check_existing=True)
            if suffix=='albedo': links.new(texture.outputs['Color'],bsdf.inputs[socket])
            elif suffix=='normal':
                texture.image.colorspace_settings.name='Non-Color'
                normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.8
                links.new(texture.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
            else:
                texture.image.colorspace_settings.name='Non-Color'
                channels=nodes.new('ShaderNodeSeparateColor')
                links.new(texture.outputs['Color'],channels.inputs['Color'])
                links.new(channels.outputs['Green'],bsdf.inputs['Roughness']);links.new(channels.outputs['Blue'],bsdf.inputs['Metallic'])
    meshes=[o for o in scene.objects if o.type=="MESH"]
    corners=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
    lo=Vector(tuple(min(c[i] for c in corners) for i in range(3)))
    hi=Vector(tuple(max(c[i] for c in corners) for i in range(3)))
    center=(lo+hi)/2
    pivot=bpy.data.objects.new("Thumbnail",None)
    scene.collection.objects.link(pivot)
    for o in list(scene.objects):
        if o!=pivot and o.parent is None:
            o.parent=pivot
    pivot.location=-center
    # Retain actual model proportions; camera scale fits its longest dimension.
    bpy.ops.object.camera_add(location=center+Vector((2.8,-3.8,2.8))*max((hi-lo).length,0.1))
    camera=bpy.context.object
    camera.location=Vector((2.8,-3.8,2.8))*max((hi-lo).length,0.1)
    camera.rotation_euler=(-camera.location).to_track_quat("-Z","Y").to_euler()
    camera.data.type="ORTHO"
    camera.data.ortho_scale=max(hi-lo)*1.55
    scene.camera=camera
    span=max((hi-lo).length,0.1)
    for loc,power,size in [((2,-3,4),500,3),((-3,-1,1),280,2),((1,3,3),400,2)]:
        bpy.ops.object.light_add(type="AREA",location=Vector(loc)*span)
        light=bpy.context.object
        light.data.energy=power*span*span
        light.data.shape="DISK"
        light.data.size=size*span
        light.rotation_euler=(-light.location).to_track_quat("-Z","Y").to_euler()
    scene.world=bpy.data.worlds.new("Studio")
    scene.world.use_nodes=True
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value=.25
    scene.view_settings.view_transform="AgX"
    scene.render.filepath=str(out/(model+".png"))
    bpy.ops.render.render(write_still=True)
    print("THUMBNAIL",model,flush=True)
