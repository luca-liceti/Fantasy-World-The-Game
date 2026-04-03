import json
import struct
import numpy as np

def parse_glb(file_path):
    with open(file_path, 'rb') as f:
        magic = f.read(4)
        version = struct.unpack('<I', f.read(4))[0]
        length = struct.unpack('<I', f.read(4))[0]
        
        chunk0_len = struct.unpack('<I', f.read(4))[0]
        chunk0_type = f.read(4)
        json_data = f.read(chunk0_len)
        gltf = json.loads(json_data.decode('utf-8'))
        
        chunk1_len = struct.unpack('<I', f.read(4))[0]
        chunk1_type = f.read(4)
        bin_data = f.read(chunk1_len)
        
    return gltf, bin_data

def get_buffer_view(gltf, bin_data, view_idx):
    view = gltf['bufferViews'][view_idx]
    offset = view.get('byteOffset', 0)
    length = view['byteLength']
    return bin_data[offset:offset+length]

gltf, bin_data = parse_glb('assets/models/d20-gold.glb')

# 1. Get letters vertices
letters_mesh = next(m for m in gltf['meshes'] if 'letters' in m['name'])
prim = letters_mesh['primitives'][0]
pos_acc = gltf['accessors'][prim['attributes']['POSITION']]
pos_view = get_buffer_view(gltf, bin_data, pos_acc['bufferView'])

count = pos_acc['count']
letter_verts = []
for i in range(count):
    offset = i * 12
    x, y, z = struct.unpack('<fff', pos_view[offset:offset+12])
    letter_verts.append([x, y, z])
letter_verts = np.array(letter_verts)

# We need to apply the inner nodes transforms (-90 X rotation on Solid.002, +90 on cf44, -90 on Sketchfab)
# Let's apply -90 on X as a global to all verts (matches what we discovered).
def rotX(deg):
    th = np.radians(deg)
    return np.array([[1,0,0],[0,np.cos(th),-np.sin(th)],[0,np.sin(th),np.cos(th)]])

# Apply -90 deg X rotation to map local to what godot sees before basis
letter_verts = np.dot(letter_verts, rotX(-90).T)

# 2. Get body faces
body_mesh = next(m for m in gltf['meshes'] if 'Material' in m['name'])
prim = body_mesh['primitives'][0]
pos_acc = gltf['accessors'][prim['attributes']['POSITION']]
pos_view = get_buffer_view(gltf, bin_data, pos_acc['bufferView'])
ind_acc = gltf['accessors'][prim['indices']]
ind_view = get_buffer_view(gltf, bin_data, ind_acc['bufferView'])

body_verts = []
for i in range(pos_acc['count']):
    offset = i * 12
    x, y, z = struct.unpack('<fff', pos_view[offset:offset+12])
    body_verts.append([x, y, z])
body_verts = np.array(body_verts)
body_verts = np.dot(body_verts, rotX(-90).T)

indices = []
for i in range(ind_acc['count']):
    offset = i * 2 # unsigned short
    idx = struct.unpack('<H', ind_view[offset:offset+2])[0]
    indices.append(idx)

faces = []
for i in range(0, len(indices), 3):
    faces.append([indices[i], indices[i+1], indices[i+2]])

# 3. Find 20 main face normals
normal_areas = {}
for f in faces:
    v1, v2, v3 = body_verts[f[0]], body_verts[f[1]], body_verts[f[2]]
    cross = np.cross(v2-v1, v3-v1)
    area = np.linalg.norm(cross) / 2.0
    if area < 0.0001: continue
    n = cross / np.linalg.norm(cross)
    center = (v1+v2+v3)/3.0
    if np.dot(n, center) < 0: n = -n
    
    matched = None
    for k in normal_areas:
        if np.dot(normal_areas[k]['normal'], n) > 0.995:
            matched = k
            break
    if matched:
        normal_areas[matched]['area'] += area
    else:
        normal_areas[str(n)] = {'normal': n, 'area': area}

area_list = list(normal_areas.values())
area_list.sort(key=lambda x: x['area'], reverse=True)
normals = [x['normal'] for x in area_list[:20]]

normals.sort(key=lambda a: (-a[1], -a[0], -a[2]))

# 4. Generate ASCII art for each normal!
for idx, up in enumerate(normals):
    # Basis:
    right = np.cross(np.array([0,1,0]), up)
    if np.linalg.norm(right) < 0.1: right = np.array([1,0,0])
    else: right = right / np.linalg.norm(right)
    fwd = np.cross(right, up)
    fwd = fwd / np.linalg.norm(fwd)
    basis = np.row_stack((right, up, fwd))
    
    # Target basis is basis.inverse() since it maps 'up' to [0,1,0]
    basis_inv = basis.T
    
    # Rotate all letter vertices
    v_rot = np.dot(letter_verts, basis_inv.T)
    max_y = np.max(v_rot[:, 1])
    
    # Filter top vertices
    top_verts = v_rot[v_rot[:, 1] > max_y - 0.1]
    
    # Project to XZ and scale to 40x20 text grid
    if len(top_verts) == 0: continue
    
    min_x, max_x = np.min(top_verts[:, 0]), np.max(top_verts[:, 0])
    min_z, max_z = np.min(top_verts[:, 2]), np.max(top_verts[:, 2])
    
    w, h = 30, 15
    grid = [[' ' for _ in range(w)] for _ in range(h)]
    for v in top_verts:
        # map X to 0..w
        px = int((v[0] - min_x) / (max_x - min_x + 1e-5) * (w - 1))
        # map Z to 0..h
        pz = int((v[2] - min_z) / (max_z - min_z + 1e-5) * (h - 1))
        grid[pz][px] = '#'
        
    print(f"\n--- INDEX {idx} ---")
    for row in grid:
        print("".join(row))

