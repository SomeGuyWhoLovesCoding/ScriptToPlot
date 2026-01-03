# Plot2Script & ScriptToPlot

#### Not ScriptToPlot 2, now ScriptToPlot Version 2, it's Script2Plot.

A powerful tool for creating Plotagon animations using a simple script format. Convert text scripts into Plotagon `.plotdoc` files and vice versa.

## What's New

This version introduces a completely redesigned script format with named parameters and improved character management:

- **New script syntax** with `@commands`, named parameters (`key=value`), and flexible formatting
- **Character autocompletion** - smart suggestions for character names with fuzzy matching
- **Alias support** - create character aliases: `@char Sidekick = Hero`
- **Bidirectional conversion** - convert scripts to Plotagon files AND Plotagon files back to scripts
- **Better error handling** with detailed parser error messages
- **Simplified usage** with command-line interface

## Installation

1. Install [Haxe](https://haxe.org/download/)
2. Install required libraries:
```bash
haxelib install hxcpp
```

## Compilation

```bash
haxe --main Script2Plot --cpp bin
```

## Quick Start

### 1. Create a script file (`myscript.s2ps`)

```s2ps
@title My Awesome Plot
@char Hero = protagonist
@char Villain = antagonist
@char Sidekick = Hero  # Alias to Hero

Scene scene=park loc1=bench actor1=Hero actor2=Villain camera=2

Hero(smiling)
vol=0.8 cam=2
Hello there!

Villain(angry)
I've been expecting you, Hero!

Action type=push char=Villain target=Hero
```

### 2. Convert to Plotagon file

```bash
./bin/Script2Script parse myscript.s2ps
```
This creates `[GUID].plotdoc` that you can import into Plotagon.

Do note that the output file (third argument) is completely optional and is not required.

### 3. Convert Plotagon file back to script

```bash
./bin/Script2Script convert myplot.plotdoc recovered.s2ps
```

## Script Syntax Reference

### Character Definitions
```s2ps
@char Name = character_id      # Define character with Plotagon ID
@char Alias = ExistingChar     # Create alias to existing character
@title Plot Title             # Set plot title
```

### Scene Instruction
```s2ps
Scene scene=id loc1=l1 loc2=l2 actor1=A1 actor2=A2 camera=1 volume=0.8 extras=true
```

### Dialogue
```s2ps
Character(expression)         # Character name with expression
vol=0.8 cam=2                 # Optional parameters line
Dialogue text here            # Dialogue text (can start with #)
```

### Actions
```s2ps
Action type=hug char=C1 target=C2 cam=2
```

### Effects
```s2ps
Effect /fadeinb /fadeoutb /fadeinw /fadeoutw
Effect /fadeinp /fadeoutp /vignette /retro
Effect /old /bloom:0.5 /setfov:1.2 /normal
```

### Textplates
```s2ps
Textplate char=C1 align=center vol=0.7: Text content here
```

### Sound & Music
```s2ps
Sound sound=id vol=0.6
Music music=id vol=0.4
```

## Command Line Usage

```bash
# Parse script to Plotagon JSON
Plot2Script parse <script_file> [output_name]

# Convert Plotagon JSON back to script
Plot2Script convert <plotdoc_file> [output_script]

# Show syntax reference
Plot2Script syntax
```

## Advanced Features

### Character Autocompletion
The parser automatically suggests corrections for misspelled character names using fuzzy matching.

### Parameter Flexibility
- All parameters are optional and can be in any order
- Most parameters have shorthand forms: `vol`, `cam`, `char`, `tgt`
- Comments start with `#` and can appear anywhere

### Supported Camera Types
```
1 = establishing shot
2 = in dialogue mode
3 = in interaction mode
4 = moving right
5 = moving left
6 = moving forward
7 = moving backward
8 = wide shot
9 = still
10 = skipping establishing shot
```

### Available Effects
- `/fadeinb`, `/fadeoutb` - Black fade in/out
- `/fadeinw`, `/fadeoutw` - White fade in/out
- `/fadeinp`, `/fadeoutp` - Custom fade in/out
- `/vignette` - Vignette effect
- `/retro` - Sepia filter
- `/old` - Black and white
- `/bloom` - Bloom effect (with intensity: `/bloom:0.5`)
- `/setfov` - Field of view adjustment (with value: `/setfov:1.2`)
- `/normal` - Reset to normal

## Importing to Plotagon

1. Generate your `.plotdoc` file using `Plot2Script parse`
2. Copy the file to:
   `C:\ProgramData\PLOTAGON_PROGRAMDATA_[GUID]\Plots\`
3. Open Plotagon Studio - your plot should appear in the list

## Tips & Best Practices

1. **Define characters first** using `@char` commands at the top of your script
2. **Use aliases** for characters that appear multiple times or have different names in dialogue
3. **Keep parameter lines simple** - one `key=value` pair per parameter
4. **Test with short scripts** before creating hour-long plots
5. **Use the `syntax` command** when unsure about formatting
6. **Check parser errors** - they provide line numbers and specific issues

## Troubleshooting

**"Character not found" warnings**: Use `@char` definitions or check for typos. The autocompletion will suggest similar names.

**Parse errors**: Run `Plot2Script syntax` to see the correct format for each instruction type.

**Import issues in Plotagon**: Ensure you're using the correct Plotagon data folder GUID for your installation.

## Legacy Format Support

The old format with `[Character]]- [Expression]]- [Dialogue]` syntax is no longer supported, as it was ScriptToPlot format and was a pretty bad format.

Use the new named parameter format instead. It's definitely much nicer and more flexible.

---

*Note: This tool is for use with Plotagon Studio. Plotagon is a trademark of Plotagon AB.*