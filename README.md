# Plot2Script & ScriptToPlot

#### Not ScriptToPlot 2, not ScriptToPlot Version 2, it's Script2Plot.

A powerful tool for creating Plotagon animations using a simple script format. Convert text scripts into Plotagon `.plotdoc` files and vice versa.

## What's New

This version introduces character projections for filesize optimization and improved character management:

- **Character Projections** - Reuse character definitions across scripts with `@chpjtl`
- **New script syntax** with `@commands`, named parameters (`key=value`), and flexible formatting
- **Character autocompletion** - smart suggestions for character names with fuzzy matching
- **Alias support** - create character aliases: `@char Sidekick = Hero`
- **Bidirectional conversion** - convert scripts to Plotagon files AND Plotagon files back to scripts
- **Better error handling** with detailed parser error messages
- **Simplified usage** with command-line interface

## Installation

Just download the newest whole source and extract it so you can put both your Script2Plot and CharacterGrabber onto C:/Windows/System32 so it can be used universally!

## Compilation

1. Install [Haxe](https://haxe.org/download/)
2. Install required libraries:
```bash
haxelib install hxcpp
```

```bash
haxe --main Script2Plot --cpp bin
```

## Quick Start

### 1. Create a character projection file (`common_chars.s2ps`)

```s2ps
# Reusable character definitions
@char a = id_a
@char b = id_b  
@char c = id_c
@char d = id_d
```

### 2. Create your main script (`story.s2ps`)

```s2ps
@title My Awesome Plot
@chpjtl common_chars.s2ps

# Create aliases to projection characters
@char Hero = a
@char Sidekick = b
@char Villain = c

Scene scene=park loc1=bench actor1=Hero actor2=Villain camera=2

Hero(smiling)
vol=0.8 cam=2
Hello there!

Villain(angry)
I've been expecting you, Hero!

# 'd' is also available directly from the projection
d(neutral)
Should I be concerned about this?
```

### 3. Convert to Plotagon file

```bash
./bin/Script2Script parse story.s2ps
```
This creates `[GUID].plotdoc` that you can import into Plotagon.

Do note that the output file (third argument) is completely optional and is not required.

### 4. Convert Plotagon file back to script

```bash
./bin/Script2Script convert myplot.plotdoc recovered.s2ps
```

## Script Syntax Reference

### Processing Order
Commands are processed in this order:
1. `@title Plot Title`
2. `@chpjtl filename.s2ps` (load character projections)
3. `@char` definitions (main script overrides projections)
4. Script instructions (Scene, Dialogue, Action, etc.)

### Character Projections (Filesize Optimization)
```s2ps
# Projection files contain ONLY @char commands
# Example: common_chars.s2ps
@char a = id_a
@char b = id_b
@char c = id_c
@char d = id_d

# Main script loads them
@chpjtl common_chars.s2ps
@char Hero = a      # Create alias
@char Sidekick = b  # Another alias
# Characters 'c' and 'd' are also available directly
```

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

### Character Projections
- **Filesize optimization**: Store common character definitions once
- **Simple override**: Main script `@char` commands override projection characters
- **Flat structure**: No nested projections to keep it simple
- **Clean separation**: Projection files contain only `@char` commands

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

1. **Use character projections** for reusable character libraries across multiple scripts
2. **Define characters first** using `@char` commands at the top of your script
3. **Use aliases** for characters that appear multiple times or have different names in dialogue
4. **Keep parameter lines simple** - one `key=value` pair per parameter
5. **Test with short scripts** before creating hour-long plots
6. **Use the `syntax` command** when unsure about formatting
7. **Check parser errors** - they provide line numbers and specific issues

## Character Projection Examples

**Basic Projection File:**
```s2ps
# heroes.s2ps
@char hero = hero_id
@char sidekick = sidekick_id
@char mentor = mentor_id
```

**Using Projections:**
```s2ps
@title The Adventure Begins
@chpjtl heroes.s2ps
@chpjtl villains.s2ps

# Create readable aliases
@char MainHero = hero
@char LoyalFriend = sidekick
@char WiseTeacher = mentor

# All projection characters are now available
Scene scene=tavern actor1=MainHero actor2=WiseTeacher camera=2

MainHero(excited)
I'm ready for the quest!

WiseTeacher(wise)
Remember what I taught you...
```

## Troubleshooting

**"Character not found" warnings**: Use `@char` definitions or check for typos. The autocompletion will suggest similar names.

**Parse errors**: Run `Plot2Script syntax` to see the correct format for each instruction type.

**Projection loading errors**: Ensure projection files exist and contain only `@char` commands.

**Import issues in Plotagon**: Ensure you're using the correct Plotagon data folder GUID for your installation.

## Legacy Format Support

The old format with `[Character]]- [Expression]]- [Dialogue]` syntax is no longer supported, as it was ScriptToPlot format and was a pretty bad format.

Use the new named parameter format instead. It's definitely much nicer and more flexible.

---

*Note: This tool is for use with Plotagon Studio. Plotagon is a trademark of Plotagon AB.*