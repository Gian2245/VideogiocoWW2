import struct

def get_png_size(file_path):
    with open(file_path, 'rb') as f:
        data = f.read(24)
        if data[:8] == b'\x89PNG\r\n\x1a\n':
            w, h = struct.unpack('>II', data[16:24])
            return w, h
    return None

paths = [
    'c:/Users/User/VideogiocoWW2/assets/Raider_1/Idle.png'
]

for p in paths:
    print(p, get_png_size(p))
