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
verts = []
for i in range(count):
    offset = i * 12
    x, y, z = struct.unpack('<fff', pos_view[offset:offset+12])
    verts.append([x, y, z])
verts = np.array(verts)

dirs = verts / np.linalg.norm(verts, axis=1)[:, np.newaxis]

clusters = []
for i in range(len(dirs)):
    d = dirs[i]
    found = False
    for c in clusters:
        if np.dot(c['center'], d) > 0.96:
            c['verts'].append(verts[i])
            found = True
            break
    if not found:
        clusters.append({'center': d, 'verts': [verts[i]]})

for i, c in enumerate(clusters):
    v = np.array(c['verts'])
    normal = np.mean(v, axis=0)
    normal = normal / np.linalg.norm(normal)
    print(f"Face {i:02d}: Vertices={len(v):4d}, Normal={normal}")
