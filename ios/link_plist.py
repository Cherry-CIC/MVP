import sys

pbxproj_path = '/Users/user/Documents/Treea/Volunteer/MVP/ios/Runner.xcodeproj/project.pbxproj'

with open(pbxproj_path, 'r') as f:
    content = f.read()

# Build file and file ref definitions
build_file_entry = '\t\tD3F0F0F02DEC000100000000 /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = D3F0F0F02DEC000200000000 /* GoogleService-Info.plist */; };\n'
file_ref_entry = '\t\tD3F0F0F02DEC000200000000 /* GoogleService-Info.plist */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; name = "GoogleService-Info.plist"; path = "Runner/GoogleService-Info.plist"; sourceTree = "<group>"; };\n'

# Helper function to insert after a line marker, handling CRLF/LF
def insert_after_line_marker(text, marker, entry_to_insert):
    idx = text.find(marker)
    if idx == -1:
        return text, False
    
    # Find the end of the line containing the marker
    end_of_line_idx = text.find('\n', idx)
    if end_of_line_idx == -1:
        return text, False
    
    insert_pos = end_of_line_idx + 1
    # Check if entry is already present in this area
    marker_hash = entry_to_insert.split('/*')[0].strip()
    if marker_hash in text[idx:idx+2000]:
        return text, False
        
    return text[:insert_pos] + entry_to_insert + text[insert_pos:], True

# 1. Insert in PBXBuildFile section
content, inserted = insert_after_line_marker(content, '/* Begin PBXBuildFile section */', build_file_entry)
if inserted:
    print("Inserted PBXBuildFile entry.")

# 2. Insert in PBXFileReference section
content, inserted = insert_after_line_marker(content, '/* Begin PBXFileReference section */', file_ref_entry)
if inserted:
    print("Inserted PBXFileReference entry.")

# 3. Insert in Runner group children
# The Runner group can have different formatting, let's find the group and insert under its children list
runner_group_idx = content.find('97C146F01CF9000F007C117D /* Runner */')
if runner_group_idx != -1:
    children_idx = content.find('children = (', runner_group_idx)
    if children_idx != -1:
        end_of_line_idx = content.find('\n', children_idx)
        if end_of_line_idx != -1:
            insert_pos = end_of_line_idx + 1
            if 'D3F0F0F02DEC000200000000' not in content[runner_group_idx:runner_group_idx+500]:
                content = content[:insert_pos] + '\t\t\t\tD3F0F0F02DEC000200000000 /* GoogleService-Info.plist */,\n' + content[insert_pos:]
                print("Inserted GoogleService-Info.plist in Runner group.")

# 4. Insert in Resources build phase files
resources_phase_idx = content.find('97C146EC1CF9000F007C117D /* Resources */')
if resources_phase_idx != -1:
    files_idx = content.find('files = (', resources_phase_idx)
    if files_idx != -1:
        end_of_line_idx = content.find('\n', files_idx)
        if end_of_line_idx != -1:
            insert_pos = end_of_line_idx + 1
            if 'D3F0F0F02DEC000100000000' not in content[resources_phase_idx:resources_phase_idx+500]:
                content = content[:insert_pos] + '\t\t\t\tD3F0F0F02DEC000100000000 /* GoogleService-Info.plist in Resources */,\n' + content[insert_pos:]
                print("Inserted GoogleService-Info.plist in Resources phase.")

with open(pbxproj_path, 'w') as f:
    f.write(content)

print("Saved project.pbxproj successfully.")
