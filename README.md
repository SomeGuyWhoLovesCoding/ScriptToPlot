# ScriptToPlot
This tool helps pump our your own hour-long raw plots faster! This was made because Plotagon Studio eventually lags when there are so many instructions (dialogue prompts/scene prompts/whatever) being rendered to the app.

*Please ignore the Main filename*

## How to compile

Install haxe (whenever it's the latest version or not) and do `haxelib install hxcpp`.

Then, you should be able to just:

```
haxe --main MapGenerator --cpp bin
```

Every time you make changes to it.

## How to use

Dialogue prompts:

```
[Character from Map]]- [Character's Expression]]- [Dialogue]]- [Dialogue Volume]]- [Dialogue Camera Property]
```

Action prompts:

```
Action]- [typeofactioninlowercasefromplotagonfiles]]- [Actor 1 from Map]]- [Actor 2 from Map]]- 
```

Textplate prompts:

```
Textplate]- [Actor from Map]]- [Textplate Alignment]]- [Dialogue]
```

Sound prompts:

```
Sound]- [soundinlowercasefromplotagonfiles]]- [Sound Volume]
```

Music prompts:

```
Music]- [musicinlowercasefromplotagonfiles]]- [Music Volume]
```

Scene prompts:

```
Scene]- [sceneidinlowercasefromplotagonfiles]]- [Location 1]]- [Location 2]]- [Actor 1 from Map]]- [Actor 2 from map]]- [Scene Ambience Volume]]- [Scene Camera Property]
```

Create a blank txt file and write your script there.

## How's the script formatted?

1. Make sure you don't make any blank lines. Just lines full of instruction scripts that translate directly into a .plotdoc instruction structure.

2. Don't mix up the volume and camera property. You'll end up with the volume being the camera's id (whenever it's wide shot, or whatever)

Your script should look like this:

Scene]- spaces.greenroom]- middle1]- middle2]- android.androidmale]- android.androidfemale]- 1
android.androidmale]- waving]- Hi! I'm android male.
android.androidfemale]- waving]- And I'm female android!

## What's all this "Map" about!?

Here's an example of a character Map.

## And how do I use it?

Simple. Create a "Map.txt" and write this:

```
[CharacterName] = [CharacterGUID]
```

(A Map should contin your personal plotagon character dictionary of the character names and their guid's)

If you want to import all your own characters to the file, read over every one of the pcd files at the root of C:\ProgramData\PLOTAGON_PROGRAMDATA_[GUID]\Bundles

```bat
ScriptToPlot Map.txt "Demo Script.txt"
```

Replace the string with your txt file.

Then import the .plotdoc file onto C:\ProgramData\PLOTAGON_PROGRAMDATA_be8b8328-7944-4d8b-af02-de4033b549ba\Plots and load the plotagon app! You should see your imported plot right at the start.
