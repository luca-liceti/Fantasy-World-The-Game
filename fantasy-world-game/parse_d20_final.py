import json
import struct
import numpy as np

def parse_glb(file_path):
    with open(file_path, 'rb') as f:
        f.read(12)
        chunk0_len = struct.unpack('<I', f.read(4))[0]
        f.read(4)
        gltf = json.loads(f.read(chunk0_len).decode('utf-8'))
        chunk1_len = struct.unpack('<I', f.read(4))[0]
        f.read(4)
        bin_data = f.read(chunk1_len)
    return gltf, bin_data

gltf, bin_data = parse_glb('assets/models/d20-gold.glb')

def get_verts(mesh_name):
    mesh = next(m for m in gltf['meshes'] if mesh_name in m['name'])
    prim = mesh['primitives'][0]
    pos_acc = gltf['accessors'][prim['attributes']['POSITION']]
    view = gltf['bufferViews'][pos_acc['bufferView']]
    offset = view.get('byteOffset', 0)
    pos_view = bin_data[offset:offset+view['byteLength']]
    
    verts = []
    for i in range(pos_acc['count']):
        x, y, z = struct.unpack('<fff', pos_view[i*12:i*12+12])
        # Apply RotX(-90) which converts (x, y, z) into (x, -z, y)? No.
        # RotX(-90) quaternion is [-0.707, 0, 0, 0.707]
        # Equivalent transformation:
        # y_new = y * cos(-90) - z * sin(-90) = z
        # z_new = y * sin(-90) + z * cos(-90) = -y
        # Wait, the node hierarchy is:
        # die (RotX(-90)) -> cf44 (RotX(90)) -> RootNode -> Solid.002 (RotX(-90))
        # Total rotation on the mesh is exactly RotX(-90)
        # So we apply y_new = z, z_new = -y
        verts.append([x, z, -y])
    return np.array(verts)

body_verts = get_verts('Material')
body_faces = gltf['accessors'][gltf['meshes'][0]['primitives'][0]['indices']]
# To be fast, let's just group by faces
# Wait, GLTF indices:
import sys
if 'indices' in gltf['meshes'][0]['primitives'][0]:
    ind_acc = gltf['accessors'][gltf['meshes'][0]['primitives'][0]['indices']]
    view = gltf['bufferViews'][ind_acc['bufferView']]
    offset = view.get('byteOffset', 0)
    ind_view = bin_data[offset:offset+view['byteLength']]
    if ind_acc['componentType'] == 5123: # unsigned short
        indices = struct.unpack(f'<{ind_acc["count"]}H', ind_view)
    elif ind_acc['componentType'] == 5125: # unsigned int
        indices = struct.unpack(f'<{ind_acc["count"]}I', ind_view)
else:
    indices = range(len(body_verts))

normal_areas = {}
for i in range(0, len(indices), 3):
    v1, v2, v3 = body_verts[indices[i]], body_verts[indices[i+1]], body_verts[indices[i+2]]
    cross = np.cross(v2-v1, v3-v1)
    area = np.linalg.norm(cross) / 2.0
    if area < 0.0001: continue
    n = cross / np.linalg.norm(cross)
    center = (v1+v2+v3)/3.0
    if np.dot(n, center) < 0: n = -n
    
    matched = None
    for k, d in normal_areas.items():
        if np.dot(d['n'], n) > 0.995: # cos(5.7)
            matched = k
            break
    if matched is not None:
        normal_areas[matched]['area'] += area
    else:
        normal_areas[str(n)] = {'n': n, 'area': area}

# Get top 20
top_faces = sorted(normal_areas.values(), key=lambda x: -x['area'])[:20]
# Sort deterministically Y > X > Z
sorted_faces = sorted(top_faces, key=lambda f: (-round(f['n'][1], 2), -round(f['n'][0], 2), -round(f['n'][2], 2)))

letter_verts = get_verts('letters')
# Assign letter verts to faces
counts = [0]*20
for v in letter_verts:
    v_norm = v / np.linalg.norm(v)
    best_idx = -1
    best_dot = -1
    for j in range(20):
        d = np.dot(sorted_faces[j]['n'], v_norm)
        if d > best_dot:
            best_dot = d
            best_idx = j
    if best_dot > 0.9:
        counts[best_idx] += 1

print("Vertex Counts for 20 Sorted Faces:")
for i, c in enumerate(counts):
    n = sorted_faces[i]['n']
    print(f"Index {i:2d} (y={n[1]:.2f}, x={n[0]:.2f}, z={n[2]:.2f}): {c:4d} verts")

