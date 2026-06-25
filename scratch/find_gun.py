import sys
from PIL import Image

def find_furthest_pixel():
    try:
        img = Image.open('c:\\Users\\User\\VideogiocoWW2\\assets\\Soldier_1\\Shot_1.png')
        img = img.convert('RGBA')
        width, height = img.size
        
        # The sprite sheet might have multiple frames side-by-side.
        # Let's just find the pixel with the max X in the entire image.
        # To avoid picking up the 4th frame, let's just find max X for each 128x128 block.
        num_frames = width // 128
        for frame in range(num_frames):
            max_x = -1
            best_y = -1
            for y in range(height):
                for x in range(frame * 128, (frame + 1) * 128):
                    r, g, b, a = img.getpixel((x, y))
                    if a > 0:
                        local_x = x - frame * 128
                        if local_x > max_x:
                            max_x = local_x
                            best_y = y
            print(f"Frame {frame}: Max X = {max_x}, Y = {best_y}")
    except Exception as e:
        print("Error:", e)

find_furthest_pixel()
