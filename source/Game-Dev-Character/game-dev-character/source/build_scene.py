# Builds the cast + office for Godot from the Mixamo-rigged Idle.fbx (Thana).
# Run: blender.exe -b -P source/build_scene.py
#   characters/thana.glb  Thana (Mixamo mesh) + clipboard + "??%" bubble   anims: Stalk, Peek, Idle
#   characters/pim.glb    พี่พิม HR, turtleneck, frozen lipstick smile      anims: Type, Idle
#   characters/ton.glb    น้องต้น intern, sweating, lanyard                  anims: Bow, Idle
#   office/office.glb     night office, cubicles, glowing screens/panels
# All characters share Thana's Mixamo skeleton; new meshes copy Thana's skin weights.
import bpy, bmesh, math, os, random
from mathutils import Matrix, Vector, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
P = "mixamorig:"
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.edit.keyframe_new_interpolation_type = 'CONSTANT'  # stepped, jerky PSX motion
scn = bpy.context.scene
scn.render.fps = 30

# ---------------- palette + materials ----------------
COLORS = {
    "skin": (0.55, 0.38, 0.22), "skin2": (0.62, 0.45, 0.32), "skin3": (0.5, 0.33, 0.2),
    "suit": (0.22, 0.24, 0.32), "suit_dark": (0.10, 0.11, 0.16), "shirt": (0.9, 0.9, 0.88),
    "tie": (0.6, 0.03, 0.03), "black": (0.01, 0.01, 0.01), "white": (0.95, 0.95, 0.95),
    "hair": (0.03, 0.03, 0.05), "board": (0.35, 0.18, 0.07), "green": (0.05, 0.6, 0.1),
    "red": (0.8, 0.05, 0.05), "shoe": (0.05, 0.03, 0.02), "pink": (0.75, 0.25, 0.4),
    "turtle": (0.45, 0.05, 0.1), "bluesh": (0.45, 0.6, 0.8), "pants": (0.08, 0.08, 0.1),
    "lanyard": (0.05, 0.15, 0.6), "sweat": (0.5, 0.8, 1.0), "lip": (0.7, 0.0, 0.05),
    "blush": (0.8, 0.35, 0.35), "carpet1": (0.09, 0.12, 0.12), "carpet2": (0.07, 0.1, 0.1),
    "wall": (0.55, 0.52, 0.42), "wall_dark": (0.3, 0.28, 0.22), "partition": (0.2, 0.25, 0.3),
    "trim": (0.5, 0.5, 0.52), "desk": (0.45, 0.38, 0.28), "metal": (0.3, 0.3, 0.32),
    "ceiling": (0.6, 0.6, 0.58), "panel": (1.0, 1.0, 0.92), "screen": (0.2, 0.6, 0.9),
    "screen2": (0.3, 0.9, 0.4), "plant": (0.08, 0.3, 0.08), "pot": (0.35, 0.15, 0.08),
    "yellow": (0.9, 0.8, 0.1), "window": (0.02, 0.04, 0.1), "jug": (0.2, 0.4, 0.9),
    "door": (0.3, 0.2, 0.12), "gold": (0.7, 0.5, 0.1)}
NAMES = list(COLORS)
B = 16
img = bpy.data.images.new("palette_scene", len(NAMES) * B, B)
row = [c for n in NAMES for c in (*COLORS[n], 1) * B]
img.pixels = row * B
img.filepath_raw = os.path.join(HERE, "palette_scene.png")
img.file_format = 'PNG'
img.save()

def make_mat(name, glow):
    m = bpy.data.materials.new(name)
    nt = m.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image, tex.interpolation = img, 'Closest'
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if glow:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 2.5
    return m
MAT, GLOW = make_mat("PSX", False), make_mat("PSX_Glow", True)

# ---------------- mesh helpers (same kit as build_thana.py) ----------------
def paint(bm, faces, color, glow=False):
    uv = bm.loops.layers.uv.verify()
    c = ((NAMES.index(color) + 0.5) / len(NAMES), 0.5)
    for f in faces:
        f.smooth = False
        f.material_index = int(glow)
        for l in f.loops:
            l[uv].uv = c

def cube(bm, center, size, color, rot=(0, 0, 0), glow=False):
    m = (Matrix.Translation(center) @ Euler([math.radians(r) for r in rot]).to_matrix().to_4x4()
         @ Matrix.Diagonal((*size, 1)))
    verts = bmesh.ops.create_cube(bm, size=1, matrix=m)["verts"]
    paint(bm, {f for v in verts for f in v.link_faces}, color, glow)

def limb(bm, a, b, w, d, cuts, color, taper=1.0):
    a, b = Vector(a), Vector(b)
    ax = b - a
    if abs(ax.z) > abs(ax.x):
        u, v = Vector((w / 2, 0, 0)), Vector((0, d / 2, 0))
    else:
        u, v = Vector((0, d / 2, 0)), Vector((0, 0, w / 2))
    rings = []
    for i in range(cuts + 2):
        t = i / (cuts + 1)
        k = 1 + (taper - 1) * t
        rings.append([bm.verts.new(a + ax * t + (s * u + q * v) * k) for s, q in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    faces = [bm.faces.new((r0[i], r0[(i + 1) % 4], r1[(i + 1) % 4], r1[i]))
             for r0, r1 in zip(rings, rings[1:]) for i in range(4)]
    faces += [bm.faces.new(rings[0][::-1]), bm.faces.new(rings[-1])]
    paint(bm, faces, color)

def to_object(bm, name):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(MAT)
    me.materials.append(GLOW)
    ob = bpy.data.objects.new(name, me)
    scn.collection.objects.link(ob)
    return ob

def text_object(body, loc, size, color, rot=(90, 0, 0)):
    bpy.ops.object.text_add(location=loc, rotation=[math.radians(r) for r in rot])
    t = bpy.context.object
    t.data.body, t.data.align_x, t.data.size = body, 'CENTER', size
    bpy.ops.object.convert(target='MESH')
    bm = bmesh.new()
    bm.from_mesh(t.data)
    bmesh.ops.transform(bm, matrix=t.matrix_world, verts=bm.verts)
    bpy.data.objects.remove(t)
    paint(bm, bm.faces, color)
    return to_object(bm, body)

H = 1.97  # head centre on the shared skeleton

def base_body(bm, skin, top, sleeve, pants):
    """Same limb layout Thana was rigged with, so the Mixamo skeleton fits every character."""
    for s in (-1, 1):
        cube(bm, (s * 0.11, -0.04, 0.04), (0.13, 0.30, 0.08), "shoe")
        limb(bm, (s * 0.11, 0, 0.08), (s * 0.11, 0, 0.95), 0.14, 0.16, 5, pants, taper=1.25)
        limb(bm, (s * 0.22, 0, 1.41), (s * 0.80, 0, 1.41), 0.13, 0.14, 5, sleeve, taper=0.8)
        cube(bm, (s * 0.885, 0, 1.41), (0.14, 0.09, 0.05), skin)
        cube(bm, (s * 0.85, -0.06, 1.415), (0.05, 0.04, 0.035), skin)
    limb(bm, (0, 0, 0.86), (0, 0, 1.0), 0.40, 0.22, 1, pants)
    cube(bm, (0, 0, 1.0), (0.42, 0.235, 0.03), "black")
    limb(bm, (0, 0, 1.0), (0, 0, 1.48), 0.42, 0.24, 4, top, taper=1.15)
    limb(bm, (0, 0, 1.46), (0, 0, 1.83), 0.07, 0.07, 3, skin)
    cube(bm, (0, 0, H), (0.26, 0.24, 0.30), skin)
    cube(bm, (0, -0.13, H - 0.01), (0.03, 0.02, 0.04), skin)

# ---------------- import Thana (Mixamo) ----------------
bpy.ops.import_scene.fbx(filepath=os.path.join(ROOT, "Idle.fbx"))
thana = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
thana_body = next(o for o in bpy.data.objects if o.type == 'MESH')
thana_body.name, thana.name = "Thana_Body", "Thana"
idle = thana.animation_data.action
idle.name = "Idle"
thana.animation_data.action = None

def reset(rig):
    for pb in rig.pose.bones:
        pb.rotation_mode = 'QUATERNION'
        pb.rotation_quaternion, pb.location, pb.scale = (1, 0, 0, 0), (0, 0, 0), (1, 1, 1)
    bpy.context.view_layer.update()
reset(thana)

def new_rig(name):
    r = thana.copy()
    r.data = thana.data.copy()
    r.animation_data_clear()
    r.name = name
    scn.collection.objects.link(r)
    return r

def bind(ob, rig):
    ob.parent = rig
    ob.matrix_parent_inverse = rig.matrix_world.inverted()
    ob.modifiers.new("Armature", 'ARMATURE').object = rig

def skin_like_thana(ob, rig):
    """Copy Thana's Mixamo weights onto a new mesh by nearest surface."""
    for vg in thana_body.vertex_groups:
        ob.vertex_groups.new(name=vg.name)
    m = ob.modifiers.new("DT", 'DATA_TRANSFER')
    m.object, m.use_vert_data = thana_body, True
    m.data_types_verts = {'VGROUP_WEIGHTS'}
    m.vert_mapping = 'POLYINTERP_NEAREST'
    m.layers_vgroup_select_src, m.layers_vgroup_select_dst = 'ALL', 'NAME'
    with bpy.context.temp_override(object=ob, active_object=ob):
        bpy.ops.object.modifier_apply(modifier="DT")
    bind(ob, rig)

def rigid(ob, rig, bone):
    ob.vertex_groups.new(name=P + bone).add(range(len(ob.data.vertices)), 1.0, 'REPLACE')
    bind(ob, rig)

# ---------------- Thana props ----------------
bm = bmesh.new()  # clipboard in the T-pose right hand, paper on both faces so any wrist roll reads
cube(bm, (-0.95, 0, 1.40), (0.015, 0.22, 0.30), "board")
for x in (-0.94, -0.96):
    cube(bm, (x, 0, 1.39), (0.004, 0.19, 0.25), "white")
    cube(bm, (x, 0.02, 1.44), (0.005, 0.1, 0.025), "green")
cube(bm, (-0.95, 0, 1.54), (0.03, 0.08, 0.03), "black")
rigid(to_object(bm, "Thana_Clipboard"), thana, "RightHand")
bm = bmesh.new()
cube(bm, (0, -0.02, H + 0.33), (0.24, 0.01, 0.12), "white")
cube(bm, (0, -0.014, H + 0.33), (0.26, 0.01, 0.14), "black")
cube(bm, (0, -0.02, H + 0.25), (0.03, 0.01, 0.05), "white", rot=(0, 30, 0))
rigid(to_object(bm, "Thana_Bubble"), thana, "Head")
rigid(text_object("??%", (0, -0.028, H + 0.30), 0.1, "red"), thana, "Head")

# ---------------- พี่พิม (Pim) ----------------
pim = new_rig("Pim")
bm = bmesh.new()
base_body(bm, "skin2", "pink", "pink", "pants")
limb(bm, (0, 0, 1.46), (0, 0, 1.76), 0.1, 0.1, 3, "turtle")                  # turtleneck hides the long neck
cube(bm, (0, -0.14, 1.3), (0.1, 0.01, 0.3), "turtle")
for s in (-1, 1):
    cube(bm, (s * 0.8, 0, 1.41), (0.03, 0.12, 0.11), "turtle")               # cuffs
    cube(bm, (s * 0.07, -0.123, H + 0.03), (0.075, 0.005, 0.06), "white")    # too-wide eyes
    cube(bm, (s * 0.07, -0.127, H + 0.03), (0.012, 0.005, 0.02), "black")    # pin-prick pupils
    cube(bm, (s * 0.07, -0.126, H + 0.065), (0.085, 0.006, 0.012), "black")  # lashes
    cube(bm, (s * 0.09, -0.123, H - 0.03), (0.04, 0.004, 0.02), "blush")
    cube(bm, (s * 0.135, -0.02, H - 0.05), (0.01, 0.015, 0.03), "gold")      # earrings
cube(bm, (0, -0.123, H - 0.075), (0.21, 0.01, 0.045), "white")               # ear-to-ear smile
for i in range(9):
    cube(bm, (-0.088 + i * 0.022, -0.128, H - 0.075), (0.004, 0.004, 0.045), "black")
for z in (H - 0.051, H - 0.099):
    cube(bm, (0, -0.128, z), (0.22, 0.006, 0.01), "lip")
skin_like_thana(to_object(bm, "Pim_Body"), pim)
bm = bmesh.new()  # bob haircut, rigid to head
cube(bm, (0, 0.07, H - 0.01), (0.30, 0.14, 0.38), "hair")
cube(bm, (0, 0.0, H + 0.165), (0.29, 0.27, 0.05), "hair")
cube(bm, (0, -0.123, H + 0.125), (0.27, 0.02, 0.06), "hair")
for s in (-1, 1):
    cube(bm, (s * 0.148, -0.02, H - 0.02), (0.03, 0.22, 0.36), "hair")
rigid(to_object(bm, "Pim_Hair"), pim, "Head")

# ---------------- น้องต้น (Ton, intern) ----------------
ton = new_rig("Ton")
bm = bmesh.new()
base_body(bm, "skin3", "bluesh", "bluesh", "pants")
cube(bm, (0, 0, 1.49), (0.14, 0.14, 0.04), "bluesh")
for s in (-1, 1):
    cube(bm, (s * 0.8, 0, 1.41), (0.03, 0.11, 0.10), "bluesh")
    cube(bm, (s * 0.05, -0.14, 1.36), (0.015, 0.01, 0.24), "lanyard", rot=(0, s * 20, 0))
    cube(bm, (s * 0.065, -0.123, H + 0.03), (0.08, 0.005, 0.07), "white")    # huge panicked eyes
    cube(bm, (s * 0.065, -0.127, H + 0.03), (0.01, 0.005, 0.015), "black")
    cube(bm, (s * 0.065, -0.126, H - 0.015), (0.07, 0.004, 0.012), "suit_dark")  # eye bags
cube(bm, (0, -0.143, 1.2), (0.07, 0.01, 0.1), "white")                        # ID card
cube(bm, (0, -0.149, 1.21), (0.03, 0.004, 0.04), "skin3")
cube(bm, (0, -0.125, H - 0.08), (0.06, 0.006, 0.02), "black")                 # nervous mouth
cube(bm, (0.015, -0.129, H - 0.075), (0.012, 0.004, 0.008), "white")
cube(bm, (0.105, -0.125, H + 0.08), (0.02, 0.01, 0.035), "sweat")
cube(bm, (-0.11, -0.125, H + 0.1), (0.015, 0.01, 0.025), "sweat")
skin_like_thana(to_object(bm, "Ton_Body"), ton)
bm = bmesh.new()  # messy spiky hair
cube(bm, (0, 0.01, H + 0.16), (0.27, 0.25, 0.05), "hair")
for i in range(7):
    x = -0.1 + i * 0.033
    cube(bm, (x, random.uniform(-0.08, 0.06), H + 0.2), (0.05, 0.06, 0.08), "hair",
         rot=(random.uniform(-25, 25), random.uniform(-30, 30), 0))
for s in (-1, 1):
    cube(bm, (s * 0.135, 0.02, H + 0.07), (0.025, 0.18, 0.1), "hair")
rigid(to_object(bm, "Ton_Hair"), ton, "Head")

# ---------------- posing: world-space ops applied from rest, then keyed on every bone ----------------
def world_pb(rig, bone):
    pb = rig.pose.bones[P + bone]
    return pb, rig.matrix_world @ pb.matrix

def set_world(rig, pb, mw):
    pb.matrix = rig.matrix_world.inverted() @ mw
    bpy.context.view_layer.update()

def about_head(rig, bone, R):
    pb, mw = world_pb(rig, bone)
    h = mw.translation.copy()
    set_world(rig, pb, Matrix.Translation(h) @ R @ Matrix.Translation(-h) @ mw)

def apply(rig, op):
    kind, bone = op[0], op[1] if len(op) > 1 else None
    if kind == "aim":    # point bone along a world direction (character faces -Y, left = +X)
        pb = rig.pose.bones[P + bone]
        cur = (rig.matrix_world @ pb.tail) - (rig.matrix_world @ pb.head)
        about_head(rig, bone, cur.rotation_difference(Vector(op[2]).normalized()).to_matrix().to_4x4())
    elif kind == "rot":  # rotate about a world axis through the bone head
        about_head(rig, bone, Matrix.Rotation(math.radians(op[3]), 4, op[2]))
    elif kind == "loc":
        pb, mw = world_pb(rig, bone)
        set_world(rig, pb, Matrix.Translation(op[2]) @ mw)
    elif kind == "stretch":  # long-neck gag: scale neck, cancel it on the head (uniform: glTF can't store shear)
        rig.pose.bones[P + "Neck"].scale = (bone,) * 3
        rig.pose.bones[P + "Head"].scale = (1 / bone,) * 3
        bpy.context.view_layer.update()

def animate(rig, name, frames, ops_at):
    act = bpy.data.actions.new(name)
    rig.animation_data_create().action = act
    for f in frames:
        reset(rig)
        for op in ops_at(f):
            apply(rig, op)
        for pb in rig.pose.bones:
            for path in ("rotation_quaternion", "location", "scale"):
                pb.keyframe_insert(path, frame=f)
    rig.animation_data.action = None
    reset(rig)
    return act

def mirror(ops):  # left-side ops -> right side
    out = []
    for op in ops:
        if op[0] == "aim":
            out.append(("aim", op[1].replace("Left", "Right"), (-op[2][0], op[2][1], op[2][2])))
    return out

steps = lambda n: range(1, n + 2, 3)  # a key every 3 frames = 10fps choppiness

# Thana: fast shuffling stalk with creeping neck, and the partition peek.
LEFT_STIFF = [("aim", "LeftArm", (0.18, 0.03, -1)), ("aim", "LeftForeArm", (0.12, -0.15, -1)),
              ("aim", "LeftHand", (0.1, -0.1, -1))]
CLIPBOARD = [("aim", "RightArm", (-0.2, -0.3, -0.93)), ("aim", "RightForeArm", (0.45, -0.85, 0.25)),
             ("aim", "RightHand", (0.45, -0.85, 0.25))]

def stalk(f):
    p = 2 * math.pi * (f - 1) / 24
    turn = 35 if 25 <= f < 37 else -20 if 37 <= f < 49 else 0
    ops = LEFT_STIFF + CLIPBOARD
    for side, sgn in (("Left", 1), ("Right", -1)):
        ops += [("rot", side + "UpLeg", 'X', -28 * sgn * math.sin(p)),
                ("rot", side + "Leg", 'X', 45 * max(0, sgn * math.cos(p)))]
    return ops + [("rot", "Spine", 'X', 8), ("rot", "Spine1", 'Z', 6 * math.sin(p)),
                  ("loc", "Hips", (0, 0, -0.03 * abs(math.sin(p)))),
                  ("rot", "Neck", 'X', 10), ("rot", "Neck", 'Z', turn),
                  ("stretch", 1.45 if 13 <= f < 37 else 1.2)]

PEEK_S = {1: 1.0, 4: 1.15, 7: 1.3, 10: 1.5, 13: 1.7, 58: 1.6, 61: 1.3, 64: 1.1, 67: 1.0}
def peek(f):
    s = PEEK_S[max(k for k in PEEK_S if k <= f)] if not 16 <= f < 58 else 1.9
    tilt = 15 if 25 <= f < 37 else -12 if 37 <= f < 49 else 18 if 49 <= f < 58 else 0
    return LEFT_STIFF + CLIPBOARD + [("rot", "Spine2", 'X', 12 * (s - 1)), ("rot", "Neck", 'X', 40 * (s - 1)),
                                     ("rot", "Neck", 'Y', tilt), ("stretch", s)]

# Pim: seated typing; every few seconds her head snaps round to stare while her hands keep typing.
SEATED = [("aim", "LeftUpLeg", (0.04, -1, 0.02)), ("aim", "LeftLeg", (0, 0.08, -1)),
          ("aim", "LeftFoot", (0, -0.8, -0.6))]
TYPING = [("aim", "LeftArm", (0.12, -0.45, -0.88)), ("aim", "LeftForeArm", (-0.12, -1, 0.04)),
          ("aim", "LeftHand", (0, -1, -0.25))]
def typing(f):
    tap = 1 if (f // 3) % 2 else -1
    ops = SEATED + mirror(SEATED) + TYPING + mirror(TYPING) + [
        ("rot", "LeftHand", 'X', 12 * tap), ("rot", "RightHand", 'X', -12 * tap),
        ("rot", "LeftForeArm", 'X', -4 * tap), ("rot", "RightForeArm", 'X', 4 * tap),
        ("loc", "Hips", (0, 0.02, -0.45))]
    if 55 <= f < 82:
        return ops + [("rot", "Neck", 'Z', -15), ("rot", "Head", 'Z', -70), ("rot", "Head", 'Y', 12)]
    return ops + [("rot", "Head", 'X', 10)]

# Ton: frantic apologetic wai-bows, then trembling.
WAI = [("aim", "LeftArm", (0.25, -0.35, -0.9)), ("aim", "LeftForeArm", (-0.266, -0.11, 0.155)),
       ("aim", "LeftHand", (-0.05, -0.15, 1))]
BOW = {1: 0, 10: 25, 13: 45, 19: 20, 22: 0, 25: 25, 28: 45, 34: 20, 37: 0, 40: 30, 43: 55, 46: 60, 52: 30, 55: 0}
def bow(f):
    b = BOW[max(k for k in BOW if k <= f)] if f < 61 else 0
    shake = random.uniform(-1, 1) if b in (0, 60) else 0
    return WAI + mirror(WAI) + [
        ("rot", "Spine", 'X', b * 0.4), ("rot", "Spine1", 'X', b * 0.3), ("rot", "Spine2", 'X', b * 0.3),
        ("rot", "Head", 'Z', 6 * shake), ("rot", "LeftLeg", 'X', 3 * shake),
        ("loc", "Hips", (0, 0.12 * b / 60, -0.02 * b / 60))]

acts = {thana: [animate(thana, "Stalk", steps(48), stalk), animate(thana, "Peek", steps(72), peek)],
        pim: [animate(pim, "Type", steps(90), typing)],
        ton: [animate(ton, "Bow", steps(60), bow)]}

# ---------------- export characters ----------------
def select(obs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]

for rig, own in acts.items():
    ad = rig.animation_data_create()
    for act in own + [idle]:
        tr = ad.nla_tracks.new()
        tr.name = act.name
        st = tr.strips.new(act.name, int(act.frame_range[0]), act)
        if hasattr(st, "action_slot") and act.slots:
            st.action_slot = act.slots[0]
    select([rig] + list(rig.children))
    bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, "characters", rig.name.lower() + ".glb"),
                              export_format='GLB', use_selection=True, export_animation_mode='NLA_TRACKS')

# ---------------- office (Blender coords; Godot = (x, z, -y)) ----------------
bm = bmesh.new()
for i in range(-6, 6):
    for j in range(-5, 5):
        cube(bm, (i + 0.5, j + 0.5, -0.01), (1, 1, 0.02), "carpet1" if (i + j) % 2 else "carpet2")
cube(bm, (0, 0, 3.02), (12, 10, 0.04), "ceiling")
for x in (-2.5, 2.5):
    for y in (0.5, 3.5):
        cube(bm, (x, y, 2.99), (1.2, 0.6, 0.02), "panel", glow=True)
cube(bm, (0, 5.05, 1.5), (12.2, 0.1, 3), "wall")
for s in (-1, 1):
    cube(bm, (s * 6.05, 0, 1.5), (0.1, 10, 3), "wall")
    cube(bm, (s * 5.99, 0, 0.05), (0.02, 10, 0.1), "wall_dark")
cube(bm, (0, 4.99, 0.05), (12, 0.02, 0.1), "wall_dark")
cube(bm, (-5.99, 0.5, 1.8), (0.02, 5, 1.0), "window")                          # night window
for y in range(-2, 4):
    cube(bm, (-5.98, y, 1.8), (0.03, 0.05, 1.0), "metal")
cube(bm, (5.99, -2.5, 1.05), (0.02, 1.0, 2.1), "door")
cube(bm, (5.97, -2.15, 1.0), (0.03, 0.05, 0.05), "gold")

C = 2.2  # cubicle cluster centre (y)
cube(bm, (0, C, 0.65), (3.0, 0.06, 1.3), "partition")
cube(bm, (0, C, 0.65), (0.06, 3.0, 1.3), "partition")
for s in (-1, 1):
    cube(bm, (s * 1.5, C, 0.65), (0.06, 3.0, 1.3), "partition")               # outer walls Thana peeks over
    cube(bm, (s * 1.5, C, 1.315), (0.08, 3.0, 0.03), "trim")
cube(bm, (0, C, 1.315), (3.0, 0.08, 0.03), "trim")
cube(bm, (0, C, 1.315), (0.08, 3.0, 0.03), "trim")
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * 0.75, C + sy * 0.4
        cube(bm, (x, y, 0.72), (1.3, 0.7, 0.04), "desk")
        for lx in (-0.6, 0.6):
            cube(bm, (x + lx, y, 0.35), (0.04, 0.6, 0.7), "metal")
        cube(bm, (x, C + sy * 0.15, 0.95), (0.5, 0.06, 0.34), "black")
        cube(bm, (x, C + sy * 0.185, 0.96), (0.44, 0.01, 0.27), "screen" if sx == sy else "screen2", glow=True)
        cube(bm, (x, C + sy * 0.15, 0.76), (0.08, 0.08, 0.06), "black")
        cube(bm, (x, C + sy * 0.5, 0.75), (0.4, 0.14, 0.02), "black")
        cube(bm, (x + 0.45, C + sy * 0.4, 0.78), (0.2, 0.28, 0.08), "white")     # paper stack
        cube(bm, (x - 0.5, C + sy * 0.035, 1.0), (0.07, 0.005, 0.07), "yellow")  # sticky note
        cy = C + sy * 1.0
        cube(bm, (x, cy, 0.46), (0.45, 0.45, 0.08), "black")
        cube(bm, (x, cy + sy * 0.22, 0.8), (0.45, 0.06, 0.55), "black")
        cube(bm, (x, cy, 0.22), (0.05, 0.05, 0.42), "metal")

# Pim's desk (she sits at x=-4.3 facing +X)
cube(bm, (-3.4, 1.5, 0.72), (0.7, 1.4, 0.04), "desk")
for ly in (0.9, 2.1):
    cube(bm, (-3.4, ly, 0.35), (0.6, 0.04, 0.7), "metal")
cube(bm, (-3.2, 1.5, 0.95), (0.06, 0.5, 0.34), "black")
cube(bm, (-3.232, 1.5, 0.96), (0.01, 0.44, 0.27), "screen", glow=True)
cube(bm, (-3.2, 1.5, 0.76), (0.08, 0.08, 0.06), "black")
cube(bm, (-3.66, 1.5, 0.75), (0.14, 0.4, 0.02), "black")
cube(bm, (-3.5, 1.05, 0.79), (0.07, 0.07, 0.1), "white")                       # mug
cube(bm, (-3.235, 1.72, 1.08), (0.005, 0.07, 0.07), "yellow")
cube(bm, (-3.235, 1.3, 0.85), (0.005, 0.07, 0.07), "pink")
cube(bm, (-4.1, 1.5, 0.44), (0.45, 0.45, 0.08), "black")
cube(bm, (-4.38, 1.5, 0.78), (0.06, 0.45, 0.55), "black")
cube(bm, (-4.1, 1.5, 0.2), (0.05, 0.05, 0.4), "metal")

# back wall: filing cabinets, whiteboard, clock
for k in range(3):
    x = -4.2 + k * 0.55
    cube(bm, (x, 4.74, 0.65), (0.5, 0.5, 1.3), "metal")
    for z in (0.35, 0.75, 1.15):
        cube(bm, (x, 4.485, z), (0.12, 0.02, 0.03), "trim")
        cube(bm, (x, 4.488, z - 0.2), (0.46, 0.01, 0.01), "black")
cube(bm, (2.5, 4.99, 1.6), (2.5, 0.04, 1.3), "metal")
cube(bm, (2.5, 4.965, 1.6), (2.4, 0.02, 1.2), "white")
for k, (dz, ang) in enumerate([(0.0, 20), (0.12, 35), (0.35, 55)]):          # KPI line shooting up
    cube(bm, (1.8 + k * 0.4, 4.95, 1.25 + dz), (0.45, 0.01, 0.02), "red", rot=(0, -ang, 0))
cube(bm, (0, 4.98, 2.45), (0.4, 0.03, 0.4), "white")
cube(bm, (0, 4.96, 2.5), (0.02, 0.01, 0.14), "black")
cube(bm, (0.04, 4.96, 2.45), (0.1, 0.01, 0.02), "black", rot=(0, -30, 0))

# right side: water cooler, printer, plants
cube(bm, (5.4, 1.4, 0.45), (0.4, 0.4, 0.9), "white")
cube(bm, (5.4, 1.4, 1.1), (0.3, 0.3, 0.4), "jug")
cube(bm, (5.19, 1.4, 0.75), (0.03, 0.06, 0.06), "metal")
cube(bm, (5.3, 2.8, 0.4), (0.6, 0.7, 0.8), "trim")
cube(bm, (5.3, 2.8, 0.82), (0.5, 0.4, 0.04), "white")
cube(bm, (5.3, 2.8, 0.7), (0.62, 0.3, 0.02), "black")
for px, py in ((5.4, 4.5), (-5.4, 4.5), (5.4, -0.5)):
    cube(bm, (px, py, 0.2), (0.35, 0.35, 0.4), "pot")
    for k in range(5):
        cube(bm, (px + random.uniform(-0.1, 0.1), py + random.uniform(-0.1, 0.1), 0.6 + k * 0.12),
             (0.4 - k * 0.06, 0.4 - k * 0.06, 0.12), "plant", rot=(0, 0, k * 25))
office = [to_object(bm, "Office"), text_object("KPI 200%", (2.5, 4.94, 1.9), 0.22, "red")]
select(office)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, "office", "office.glb"), export_format='GLB', use_selection=True)

# ---------------- Blender preview of the posed cast ----------------
for rig, x, act, f in ((thana, -1.2, "Peek", 25), (pim, 0, "Type", 61), (ton, 1.2, "Bow", 46)):
    rig.location.x += x
    rig.animation_data.action = bpy.data.actions[act]
    if hasattr(rig.animation_data, "action_slot") and bpy.data.actions[act].slots:
        rig.animation_data.action_slot = bpy.data.actions[act].slots[0]
    for tr in rig.animation_data.nla_tracks:
        tr.mute = True
for o in office:
    o.hide_render = True
scn.frame_set(61)  # Pim staring; others hold their pose from the keyed frame below
for rig, f in ((thana, 25), (ton, 46)):
    rig.animation_data.action_extrapolation = 'HOLD'
bpy.ops.object.camera_add(location=(1.2, -5.5, 1.3), rotation=(math.radians(88), 0, math.radians(12)))
scn.camera = bpy.context.object
scn.camera.data.lens = 35
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(50), math.radians(-20), math.radians(-30)))
bpy.context.object.data.energy = 3
scn.world = bpy.data.worlds.new("W")
scn.world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
scn.render.engine = 'BLENDER_EEVEE'
scn.render.resolution_x, scn.render.resolution_y = 480, 320
scn.render.filter_size = 0.0
scn.render.filepath = os.path.join(HERE, "cast_preview.png")
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "scene.blend"))
