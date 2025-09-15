#!/usr/bin/env python3
"""
Simple script to add missing type properties to animation tracks
"""

import re

def add_missing_type_properties(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Find tracks that have imported/enabled but no type
    lines = content.split('\n')
    fixed_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this line starts a track without type
        if re.match(r'tracks/\d+/imported = ', line):
            # Look back to see if there's a type property for this track
            track_num = re.search(r'tracks/(\d+)/', line).group(1)
            
            # Check if type exists in previous lines for this track
            has_type = False
            for j in range(max(0, i-10), i):
                if f'tracks/{track_num}/type = ' in lines[j]:
                    has_type = True
                    break
            
            if not has_type:
                # Add type property before this line
                # Determine type based on path (look ahead)
                track_type = '"rotation"'  # default
                for j in range(i, min(len(lines), i+10)):
                    if f'tracks/{track_num}/path = ' in lines[j]:
                        if 'TorsoBone")' in lines[j] and not any(bone in lines[j] for bone in ['HeadBone', 'LeftArmBone', 'RightArmBone', 'CloakBone']):
                            track_type = '"position"'
                        break
                
                fixed_lines.append(f'tracks/{track_num}/type = {track_type}')
        
        fixed_lines.append(line)
        i += 1
    
    # Write back the fixed content
    with open(file_path, 'w') as f:
        f.write('\n'.join(fixed_lines))
    
    print(f"Added missing type properties in {file_path}")

if __name__ == '__main__':
    add_missing_type_properties('/Users/mac/shadows-fo-the-drum/soymabascn.tscn')