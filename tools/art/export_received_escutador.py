"""Re-export the saved high-detail Blender scene without rebuilding anatomy."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets/source/received_escutador/escutador_refined.blend'))
rig=bpy.data.objects['Received_Escutador'];body=bpy.data.objects['Received_Escutador_SkinnedMesh']
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);body.select_set(True);bpy.context.view_layer.objects.active=rig
export=dict(export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True,export_materials='EXPORT',export_image_format='NONE',export_cameras=False,export_lights=False)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/escutador_received.glb'),**export)
bpy.context.view_layer.objects.active=body;rig.select_set(False)
m=body.modifiers.new('Android low detail','DECIMATE');m.ratio=.44;bpy.ops.object.modifier_move_up(modifier=m.name);bpy.ops.object.modifier_apply(modifier=m.name);rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/escutador_received_low.glb'),**export)
