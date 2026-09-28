# หัวหน้าธนา (The Micromanager) — full-body low-poly PSX character, Mixamo/Godot ready
# Run: blender.exe -b -P build_thana.py
# Outputs next to this file:
#   thana_mixamo.fbx  single T-pose mesh, no rig, palette texture embedded -> upload to Mixamo
#   palette.png, thana.blend, preview.png
import bpy, bmesh, math, os
from mathutils import Matrix, Vector, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True)

# --- palette texture: one 16px block per colour, UVs point at block centres (no bleed even with linear filtering) ---
COLORS = {
    "skin": (0.55, 0.38, 0.22), "suit": (0.22, 0.24, 0.32), "suit_dark": (0.10, 0.11, 0.16),
    "shirt": (0.9, 0.9, 0.88), "tie": (0.6, 0.03, 0.03), "black": (0.01, 0.01, 0.01),
    "white": (0.95, 0.95, 0.95), "hair": (0.03, 0.03, 0.05), "board": (0.35, 0.18, 0.07),
    "green": (0.05, 0.6, 0.1), "red": (0.8, 0.05, 0.05), "shoe": (0.05, 0.03, 0.02)}
NAMES = list(COLORS)
B = 16
img = bpy.data.images.new("palette", len(NAMES) * B, B)
px = []
for y in range(B):
    for n in NAMES:
        px += [*COLORS[n], 1] * B
img.pixels = px
img.filepath_raw = os.path.join(HERE, "palette.png")
img.file_format = 'PNG'
img.save()

mat = bpy.data.materials.new("Thana_Palette")
nt = mat.node_tree
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image, tex.interpolation = img, 'Closest'
bsdf = nt.nodes["Principled BSDF"]
bsdf.inputs["Roughness"].default_value = 1.0
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

def paint(bm, faces, color):
    uv = bm.loops.layers.uv.verify()
    c = ((NAMES.index(color) + 0.5) / len(NAMES), 0.5)
    for f in faces:
        f.smooth = False
        for l in f.loops:
            l[uv].uv = c

def cube(bm, center, size, color, rot=(0, 0, 0)):
    m = (Matrix.Translation(center) @ Euler([math.radians(r) for r in rot]).to_matrix().to_4x4()
         @ Matrix.Diagonal((*size, 1)))
    verts = bmesh.ops.create_cube(bm, size=1, matrix=m)["verts"]
    paint(bm, {f for v in verts for f in v.link_faces}, color)

def limb(bm, a, b, w, d, cuts, color, taper=1.0):
    """Box from a to b with `cuts` edge loops so Mixamo skinning can bend it. Axis is Z or X."""
    a, b = Vector(a), Vector(b)
    ax = b - a
    if abs(ax.z) > abs(ax.x):
        u, v = Vector((w / 2, 0, 0)), Vector((0, d / 2, 0))
    else:  # horizontal (T-pose arm): w = height, d = depth
        u, v = Vector((0, d / 2, 0)), Vector((0, 0, w / 2))
    rings = []
    for i in range(cuts + 2):
        t = i / (cuts + 1)
        k = 1 + (taper - 1) * t
        c = a + ax * t
        rings.append([bm.verts.new(c + (s * u + q * v) * k) for s, q in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    faces = [bm.faces.new((r0[i], r0[(i + 1) % 4], r1[(i + 1) % 4], r1[i]))
             for r0, r1 in zip(rings, rings[1:]) for i in range(4)]
    faces += [bm.faces.new(rings[0][::-1]), bm.faces.new(rings[-1])]
    paint(bm, faces, color)

def to_object(bm, name):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob

# ---------------- body (metres, Z up, facing -Y, T-pose) ----------------
bm = bmesh.new()
for s in (-1, 1):
    cube(bm, (s * 0.11, -0.04, 0.04), (0.13, 0.30, 0.08), "shoe")
    limb(bm, (s * 0.11, 0, 0.08), (s * 0.11, 0, 0.95), 0.14, 0.16, 5, "suit", taper=1.25)   # knee = middle loop
    limb(bm, (s * 0.22, 0, 1.41), (s * 0.80, 0, 1.41), 0.13, 0.14, 5, "suit", taper=0.8)    # elbow = middle loop
    cube(bm, (s * 0.80, 0, 1.41), (0.03, 0.11, 0.10), "shirt")                                # cuff
    cube(bm, (s * 0.885, 0, 1.41), (0.14, 0.09, 0.05), "skin")                                # mitten hand
    cube(bm, (s * 0.85, -0.06, 1.415), (0.05, 0.04, 0.035), "skin")                          # thumb
limb(bm, (0, 0, 0.86), (0, 0, 1.0), 0.40, 0.22, 1, "suit")                                    # hips
cube(bm, (0, 0, 1.0), (0.42, 0.235, 0.03), "black")                                           # belt
limb(bm, (0, 0, 1.0), (0, 0, 1.48), 0.42, 0.24, 4, "suit", taper=1.15)                         # torso
cube(bm, (0, -0.137, 1.36), (0.12, 0.01, 0.2), "shirt")
cube(bm, (0, -0.143, 1.44), (0.035, 0.012, 0.03), "tie")
cube(bm, (0, -0.143, 1.33), (0.045, 0.012, 0.2), "tie")
cube(bm, (-0.085, -0.14, 1.37), (0.07, 0.01, 0.24), "suit_dark", rot=(0, -25, 0))
cube(bm, (0.085, -0.14, 1.37), (0.07, 0.01, 0.24), "suit_dark", rot=(0, 25, 0))
cube(bm, (0, 0, 1.49), (0.14, 0.14, 0.04), "shirt")                                           # collar
limb(bm, (0, 0, 1.46), (0, 0, 1.83), 0.07, 0.07, 3, "skin")                                   # the long neck

H = 1.97  # head centre
cube(bm, (0, 0, H), (0.26, 0.24, 0.30), "skin")
cube(bm, (0, -0.13, H - 0.01), (0.03, 0.02, 0.04), "skin")                                    # nose
for s in (-1, 1):
    cube(bm, (s * 0.135, 0, H + 0.05), (0.025, 0.17, 0.08), "hair")
    cube(bm, (s * 0.06, -0.125, H + 0.03), (0.095, 0.012, 0.075), "black")                    # thick lens frame
    cube(bm, (s * 0.06, -0.131, H + 0.03), (0.07, 0.005, 0.05), "white")                      # unblinking eye
    cube(bm, (s * 0.06, -0.134, H + 0.03), (0.018, 0.005, 0.026), "black")                    # pupil
cube(bm, (0, 0.02, H + 0.155), (0.17, 0.13, 0.02), "hair")
cube(bm, (0, -0.125, H + 0.04), (0.035, 0.01, 0.013), "black")                                # bridge
cube(bm, (0, -0.125, H + 0.08), (0.22, 0.012, 0.018), "hair")                                 # brow
cube(bm, (0, -0.123, H - 0.07), (0.18, 0.01, 0.055), "white")                                 # frozen grin
for i in range(7):
    cube(bm, (-0.078 + i * 0.026, -0.128, H - 0.07), (0.005, 0.005, 0.055), "black")
for z in (H - 0.041, H - 0.098):
    cube(bm, (0, -0.128, z), (0.19, 0.005, 0.007), "black")
body = to_object(bm, "Thana")

# ---------------- props (preview only; the rigged versions live in build_scene.py) ----------------
bm = bmesh.new()
cube(bm, (0, 0, 0), (0.24, 0.01, 0.12), "white")
cube(bm, (0, 0.006, 0), (0.26, 0.01, 0.14), "black")
bubble = to_object(bm, "SpeechBubble")
bpy.ops.object.text_add(location=(0, -0.008, -0.03), rotation=(math.radians(90), 0, 0))
txt = bpy.context.object
txt.data.body, txt.data.align_x, txt.data.size = "??%", 'CENTER', 0.1
bpy.ops.object.convert(target='MESH')
bm = bmesh.new()
bm.from_mesh(txt.data)
bmesh.ops.transform(bm, matrix=txt.matrix_world, verts=bm.verts)
bpy.data.objects.remove(txt)
paint(bm, bm.faces, "red")
text = to_object(bm, "BubbleText")
bpy.ops.object.select_all(action='DESELECT')
text.select_set(True); bubble.select_set(True)
bpy.context.view_layer.objects.active = bubble
bpy.ops.object.join()
bubble.location = (0, 0, H + 0.33)  # preview placement only; exported at origin below

bm = bmesh.new()
cube(bm, (0, 0, 0), (0.22, 0.015, 0.30), "board")
cube(bm, (0, -0.01, -0.01), (0.19, 0.005, 0.25), "white")
cube(bm, (0.01, -0.014, 0.05), (0.1, 0.005, 0.025), "green")
cube(bm, (0, -0.01, 0.14), (0.08, 0.02, 0.03), "black")                                        # clip
clip = to_object(bm, "Clipboard")
clip.location = (0.55, -0.35, 1.2)

# ---------------- preview ----------------
scn = bpy.context.scene
bpy.ops.object.camera_add(location=(1.6, -4.2, 1.15), rotation=(math.radians(90), 0, math.radians(21)))
scn.camera = bpy.context.object
scn.camera.data.lens = 38
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(50), math.radians(-20), math.radians(-30)))
bpy.context.object.data.energy = 3
scn.world = bpy.data.worlds.new("W")
scn.world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
scn.render.engine = 'BLENDER_EEVEE'
scn.render.resolution_x, scn.render.resolution_y = 320, 400
scn.render.filter_size = 0.0
scn.render.filepath = os.path.join(HERE, "preview.png")
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "thana.blend"))

# ---------------- export ----------------
def only(*obs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]

only(body)
bpy.ops.export_scene.fbx(filepath=os.path.join(HERE, "thana_mixamo.fbx"), use_selection=True,
                         object_types={'MESH'}, mesh_smooth_type='FACE', path_mode='COPY', embed_textures=True)
