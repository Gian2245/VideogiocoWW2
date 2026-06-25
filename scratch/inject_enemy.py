import re

with open('c:/Users/User/VideogiocoWW2/scenes/game1.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Add ext_resource if not present
if 'enemy_raider_1.tscn' not in content:
    resource_line = '[ext_resource type="PackedScene" path="res://scenes/enemy_raider_1.tscn" id="5_enemy"]\n'
    # Find last ext_resource
    match = list(re.finditer(r'\[ext_resource.*\]\n', content))[-1]
    insert_idx = match.end()
    content = content[:insert_idx] + resource_line + content[insert_idx:]

# Add node instance
if 'name="EnemyRaider1"' not in content:
    node_block = """
[node name="EnemyRaider1" parent="." instance=ExtResource("5_enemy")]
position = Vector2(2900, 368)
"""
    content += node_block

with open('c:/Users/User/VideogiocoWW2/scenes/game1.tscn', 'w', encoding='utf-8') as f:
    f.write(content)
