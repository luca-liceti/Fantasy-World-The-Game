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

def rotX(deg):
    th = np.radians(deg)
    return np.array([[1,0,0],[0,np.cos(th),-np.sin(th)],[0,np.sin(th),np.cos(th)]])

letter_verts = np.dot(letter_verts, rotX(-90).T)

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
    offset = i * 2
    idx = struct.unpack('<H', ind_view[offset:offset+2])[0]
    indices.append(idx)

faces = []
for i in range(0, len(indices), 3):
    faces.append([indices[i], indices[i+1], indices[i+2]])

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

svg = ['<svg width="1000" height="800" xmlns="http://www.w3.org/2000/svg">']
svg.append('<style>circle { fill: black; } text { font-family: sans-serif; font-size: 10px; }</style>')

for idx, up in enumerate(normals):
    right = np.cross(np.array([0,1,0]), up)
    if np.linalg.norm(right) < 0.1: right = np.array([1,0,0])
    else: right = right / np.linalg.norm(right)
    fwd = np.cross(right, up)
    fwd = fwd / np.linalg.norm(fwd)
    basis = np.row_stack((right, up, fwd))
    basis_inv = basis.T
    
    v_rot = np.dot(letter_verts, basis_inv.T)
    max_y = np.max(v_rot[:, 1])
    top_verts = v_rot[v_rot[:, 1] > max_y - 0.1]
    
    if len(top_verts) == 0: continue
    
    # 5 rows, 4 columns
    col = idx % 5
    row = idx // 5
    
    ox = col * 200 + 100
    oy = row * 200 + 100
    
    scale = 300 # scale up the (-0.2, 0.2) coordinates
    
    svg.append(f'<g transform="translate({ox}, {oy})">')
    svg.append(f'<rect x="-90" y="-90" width="180" height="180" fill="none" stroke="blue"/>')
    svg.append(f'<text x="-85" y="-75">IDX {idx}</text>')
    
    # Just draw circles for the vertices! This will draw the number visually!
    for v in top_verts:
        # Z is down in 2D
        cx = v[0] * scale
        cy = v[2] * scale
        svg.append(f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="1.5"/>')
        
    svg.append('</g>')

svg.append('</svg>')

# Save SVG to local artifacts folder so browser subagent can open it via file://
with open('faces.svg', 'w') as f:
    f.write("\n".join(svg))

print("Created faces.svg")
