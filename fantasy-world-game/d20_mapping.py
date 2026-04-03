import numpy as np

# Coordinates of an icosahedron with vertices at the poles
# If standard icosahedron is rotated so a vertex is at +Y
# Let's generate it
phi = (1 + np.sqrt(5)) / 2
verts_raw = np.array([
    [0, 1, phi], [0, -1, phi], [0, 1, -phi], [0, -1, -phi],
    [1, phi, 0], [-1, phi, 0], [1, -phi, 0], [-1, -phi, 0],
    [phi, 0, 1], [-phi, 0, 1], [phi, 0, -1], [-phi, 0, -1]
])

faces_raw = [
    [0,1,8], [0,8,4], [0,4,5], [0,5,9], [0,9,1],
    [2,3,10], [2,10,4], [2,4,5], [2,5,11], [2,11,3],
    [1,6,8], [8,6,10], [10,6,3], [3,7,11], [11,7,9],
    [9,7,1], [1,7,6], [4,8,10], [5,4,2], [9,5,11]
]

# In d20-gold.glb, it is rotated RotX(-90) and has a vertex at +Y
# Wait. The base vertices above: vertex [1, phi, 0] is at +1, 1.618, 0. Not exactly on Y axis.
# To put a vertex exactly on the Y axis, we rotate it.
# Let's just use the vertices from the Blender screenshots.
# Actually, we don't need Blender. We can build it locally!
# An icosahedron with vertex at (0, 1, 0).
# The 5 neighbors have Y = 1/sqrt(5) = 0.447
# The 5 neighbors forming the pentagon.
# The polar vertices are (0,1,0) and (0,-1,0)
# Top ring: Y = 1/sqrt(5). X = r*cos(th), Z = r*sin(th) where r = 2/sqrt(5). th = n*72 deg.
# Bottom ring: Y = -1/sqrt(5). Offset by 36 deg.

r = 2 / np.sqrt(5)
y_ring = 1 / np.sqrt(5)

verts = []
verts.append([0, 1, 0])
for i in range(5):
    th = np.pi/2 - i * 2 * np.pi / 5  # start at Z? Let's just use standard
    # To match Blender... let's say one vertex is at X=0, Z>0.
    verts.append([r*np.sin(th), y_ring, r*np.cos(th)])
for i in range(5):
    th = np.pi/2 - (i + 0.5) * 2 * np.pi / 5
    verts.append([r*np.sin(th), -y_ring, r*np.cos(th)])
verts.append([0, -1, 0])

# Top 5 faces
normals = []
for i in range(5):
    v1, v2, v3 = np.array(verts[0]), np.array(verts[i+1]), np.array(verts[1 + (i+1)%5])
    n = np.cross(v2-v1, v3-v1)
    normals.append(n / np.linalg.norm(n))

# Upper equator faces
for i in range(5):
    v1, v2, v3 = np.array(verts[1+i]), np.array(verts[1+(i+1)%5]), np.array(verts[6+i])
    n = np.cross(v2-v1, v3-v1)
    if np.dot(n, v1) < 0: n = -n
    normals.append(n / np.linalg.norm(n))

# Lower equator faces
for i in range(5):
    v1, v2, v3 = np.array(verts[6+i]), np.array(verts[6+(i+1)%5]), np.array(verts[1+(i+1)%5])
    n = np.cross(v2-v1, v3-v1)
    if np.dot(n, v1) < 0: n = -n
    normals.append(n / np.linalg.norm(n))

# Bottom faces
for i in range(5):
    v1, v2, v3 = np.array(verts[11]), np.array(verts[6+i]), np.array(verts[6+(i+1)%5])
    n = np.cross(v2-v1, v3-v1)
    if np.dot(n, v1) < 0: n = -n
    normals.append(n / np.linalg.norm(n))

normals = np.array(normals)
normals_list = [{'id': i, 'n': normals[i]} for i in range(20)]

def sort_key(item):
    n = item['n']
    # Round to avoid float issues
    return (round(n[1], 2), round(n[0], 2), round(n[2], 2))

sorted_normals = sorted(normals_list, key=sort_key, reverse=True)

for i, item in enumerate(sorted_normals):
    n = item['n']
    print(f"Index {i:2d} (Face orig {item['id']:2d}): [{n[0]:5.2f}, {n[1]:5.2f}, {n[2]:5.2f}]")
