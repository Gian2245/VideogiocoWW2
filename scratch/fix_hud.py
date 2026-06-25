with open('c:/Users/User/VideogiocoWW2/scenes/HUD.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('parent="ArmorRoot/HealthPanel"', 'parent="ArmorRoot/ArmorPanel"')
text = text.replace('parent="ArmorRoot/ArmorPanel/HealthVBox"', 'parent="ArmorRoot/ArmorPanel/ArmorVBox"')
text = text.replace('parent="ArmorRoot/ArmorPanel/ArmorVBox/HealthHeader"', 'parent="ArmorRoot/ArmorPanel/ArmorVBox/ArmorHeader"')
text = text.replace('parent="ArmorRoot/ArmorPanel/ArmorVBox/HealthBarFrame"', 'parent="ArmorRoot/ArmorPanel/ArmorVBox/ArmorBarFrame"')
text = text.replace('parent="ArmorRoot/ArmorPanel/ArmorVBox/ArmorBarFrame/HealthSegments"', 'parent="ArmorRoot/ArmorPanel/ArmorVBox/ArmorBarFrame/ArmorSegments"')

with open('c:/Users/User/VideogiocoWW2/scenes/HUD.tscn', 'w', encoding='utf-8') as f:
    f.write(text)
