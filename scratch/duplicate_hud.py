import re

with open('c:/Users/User/VideogiocoWW2/scenes/HUD.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

health_start = content.find('[node name="HealthRoot"')
weapon_start = content.find('[node name="WeaponRoot"')

health_block = content[health_start:weapon_start]

import random
def repl_uid(m):
    return f"unique_id={random.randint(1000000000, 9999999999)}"

armor_block = health_block
# Rename nodes and unique names
armor_block = armor_block.replace('name="HealthRoot"', 'name="ArmorRoot"')
armor_block = armor_block.replace('name="HealthPanel"', 'name="ArmorPanel"')
armor_block = armor_block.replace('name="HealthVBox"', 'name="ArmorVBox"')
armor_block = armor_block.replace('name="HealthHeader"', 'name="ArmorHeader"')
armor_block = armor_block.replace('name="HealthIcon"', 'name="ArmorIcon"')
armor_block = armor_block.replace('name="HealthTitle"', 'name="ArmorTitle"')
armor_block = armor_block.replace('name="HealthValue"', 'name="ArmorValue"')
armor_block = armor_block.replace('name="HealthBarFrame"', 'name="ArmorBarFrame"')
armor_block = armor_block.replace('name="HealthGlow"', 'name="ArmorGlow"')
armor_block = armor_block.replace('name="HealthSegments"', 'name="ArmorSegments"')

# Rename paths
armor_block = armor_block.replace('parent="HealthRoot', 'parent="ArmorRoot')
armor_block = armor_block.replace('HealthPanel/', 'ArmorPanel/')
armor_block = armor_block.replace('HealthVBox/', 'ArmorVBox/')
armor_block = armor_block.replace('HealthHeader/', 'ArmorHeader/')
armor_block = armor_block.replace('HealthBarFrame/', 'ArmorBarFrame/')
armor_block = armor_block.replace('HealthSegments/', 'ArmorSegments/')

# Replace texts
armor_block = armor_block.replace('text = "SALUTE"', 'text = "ARMATURA"')
armor_block = armor_block.replace('text = "100"', 'text = "0"')
armor_block = armor_block.replace('text = "✚"', 'text = "🛡️"')

# Move it down
armor_block = armor_block.replace('offset_top = 14.0', 'offset_top = 84.0')
armor_block = armor_block.replace('offset_bottom = 78.0', 'offset_bottom = 148.0')

# Generate new UIDs
armor_block = re.sub(r'unique_id=\d+', repl_uid, armor_block)

new_content = content[:weapon_start] + armor_block + content[weapon_start:]

with open('c:/Users/User/VideogiocoWW2/scenes/HUD.tscn', 'w', encoding='utf-8') as f:
    f.write(new_content)
