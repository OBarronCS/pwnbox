#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import sys
import glob
from pathlib import Path
import os

# Usage:
#  ./ghidra_settings.py [file_path_of_settings]
#   If not passed, will attempt to find the file automatically


file_path = ""

# Get the file path of settings file
if len(sys.argv) < 2:
    HOME_DIR = str(Path.home())
    print(HOME_DIR)

    # settings_file_names = glob.glob(f"{HOME_DIR}/.ghidra/.ghidra_*_PUBLIC/tools/_code_browser.tcd")
    settings_file_names = glob.glob(f"{HOME_DIR}/.config/ghidra/ghidra*/tools/_code_browser.tcd")

    os.system("ls -pla /home/ubuntu/.config/ghidra/ghidra*")


    if(len(settings_file_names) == 0):
        print("Could not find settings file. Run ghidra at least once")
        sys.exit(1)
    elif(len(settings_file_names) > 1):
        print("Found more than one settings file")
        print(f"Run again with: {sys.argv[0]} settings_file_path")
        print(settings_file_names)
        sys.exit(1)

    file_path = settings_file_names[0]
    print(f"Found settings file: {file_path}")
else:
    file_path = sys.argv[1]

    if not os.path.isfile(file_path):
       print(f"Cannot find file {file_path}")
       sys.exit(1)


# Change the settings
tree = ET.parse(file_path)
root = tree.getroot()

code_browser = root.find(".//*[@TOOL_NAME='CodeBrowser']")

if code_browser is None:
    print("Settings format has changed!")
    sys.exit(1)

options = code_browser.find("OPTIONS")
if options is not None:
    category = options.find("CATEGORY[@NAME='Listing Fields']")
    if category is None:
        category = ET.SubElement(options, "CATEGORY", NAME="Listing Fields")
    
    setting = category.find("ENUM[@NAME='Cursor Text Highlight.Mouse Button To Activate']")
    if setting is None:
        ET.SubElement(category, "ENUM", NAME="Cursor Text Highlight.Mouse Button To Activate", TYPE="enum", CLASS="ghidra.GhidraOptions$CURSOR_MOUSE_BUTTON_NAMES", VALUE="LEFT")
    else:
        setting.set("VALUE", "LEFT")
    
    setting = category.find("STATE[@NAME='Operands Field.Markup Register Variable References']")
    if setting is None:
        ET.SubElement(category, "STATE", NAME="Operands Field.Markup Register Variable References", TYPE="boolean", VALUE="false")
    else:
        setting.set("VALUE", "false")
    
    setting = category.find("STATE[@NAME='Operands Field.Markup Stack Variable References']")
    if setting is None:
        ET.SubElement(category, "STATE", NAME="Operands Field.Markup Stack Variable References", TYPE="boolean", VALUE="false")
    else:
        setting.set("VALUE", "false")

# Preferences, change Theme=Class\:generic.theme.builtin.FlatDarkTheme.
# Backup original
# shutil.copyfile(file_path, file_path + ".bak")

ET.indent(tree, space="    ")
tree.write(file_path, encoding="utf-8", xml_declaration=True)

