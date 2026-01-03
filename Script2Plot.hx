package;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;


using StringTools;

// Command system class
class CommandProcessor {
	var commands:Map<String, Array<String>> = new Map();
	var characterGUIDs:Map<String, String> = new Map();
	var definedCharacters:Map<String, String> = new Map();
	
	public function new() {}
	
	public function addCommand(name:String, args:Array<String>) {
		commands.set(name, args);
	}
	
	public function executeCommands(script:String):String {
		var lines = script.split('\n');
		var output = new StringBuf();
		var inCommandBlock = false;
		var currentCommand = "";
		var commandArgs:Array<String> = [];
		
		for (line in lines) {
			var trimmed = line.trim();
			
			// Process @ commands
			if (trimmed.startsWith("@")) {
				var parts = trimmed.substring(1).split(" ").map(p -> p.trim()).filter(p -> p.length > 0);
				if (parts.length > 0) {
					switch (parts[0]) {
						case "char":
							if (parts.length >= 3) {
								var charName = parts[1];
								var charId = parts[2];
								definedCharacters.set(charName, charId);
								// If it's an alias, track it
								if (definedCharacters.exists(charId)) {
									characterGUIDs.set(charName, characterGUIDs.get(charId));
								}
							}
						case "title":
							if (parts.length >= 2) {
								output.add("# Title: " + parts.slice(1).join(" ") + "\n\n");
							}
					}
				}
			} else if (trimmed.length > 0 && !trimmed.startsWith("#")) {
				output.add(line + "\n");
			} else {
				output.add(line + "\n");
			}
		}
		
		return output.toString();
	}
}

// Main parser class
class ScriptParser {
	var parserErrors:Array<ParserError> = [];
	var characters:Map<String, Character> = new Map();
	var plotTitle:String = "Generated with Plot2Script";
	var commandProcessor:CommandProcessor;
	
	public function new() {
		commandProcessor = new CommandProcessor();
	}
	
	public function parseScript(script:String):PlotagonPlotFile {
		parserErrors = [];
		characters = new Map();
		
		var lines = script.split('\n');
		var instructions:Array<PlotagonPlotInstruction> = [];
		var i = 0;
		var lineNum = 0;
		
		// First pass: extract characters from @char commands
		for (line in lines) {
			var trimmed = line.trim();
			if (trimmed.startsWith("@char ")) {
				var defStr = trimmed.substring(6).trim();
				var parts = defStr.split("=").map(p -> p.trim());
				if (parts.length >= 2) {
					var name = parts[0];
					var id = parts[1];
					
					// Check if this is an alias to an existing character
					if (characters.exists(id)) {
						// It's an alias - use the existing character's GUID
						var existingChar = characters.get(id);
						characters.set(name, { name: name, id: id, guid: existingChar.guid });
					} else {
						// It's a new character definition with ID
						characters.set(name, { name: name, id: id, guid: Script2Plot.generateGUID() });
						// Also store by ID for alias resolution
						characters.set(id, characters.get(name));
					}
				}
			} else if (trimmed.startsWith("@title ")) {
				plotTitle = trimmed.substring(7).trim();
			}
		}
		
		// Second pass: parse instructions
		while (i < lines.length) {
			var line = lines[i];
			lineNum = i + 1;
			var trimmed = line.trim();
			
			// Skip empty lines
			if (trimmed.length == 0) {
				i++;
				continue;
			}
			
			// Skip @ commands (already processed)
			if (trimmed.startsWith("@")) {
				i++;
				continue;
			}
			
			// Check for comments - but be careful about dialogue lines
			// Dialogue lines have the pattern Character(expression)
			var dialoguePattern = ~/^\w+\([^)]+\)$/;
			if (trimmed.startsWith("#") && !dialoguePattern.match(trimmed)) {
				// Only skip if it's a standalone comment AND not a dialogue header
				i++;
				continue;
			}
			
			try {
				// Try to parse as dialogue first (most common)
				var dialogue = parseDialogueInstruction(lines, i);
				if (dialogue != null) {
					instructions.push(dialogue);
					// Skip lines that were consumed by dialogue parsing
					var consumedLines = countDialogueLines(lines, i);
					i += consumedLines;
					continue;
				}
				
				// If not dialogue, try other instruction types
				var cleanLine = line;
				// Remove end-of-line comments (but preserve # in middle like #BREATH02#)
				var commentIndex = line.indexOf("#");
				if (commentIndex != -1 && line.trim().startsWith("#")) {
					cleanLine = line.substring(0, commentIndex).trim();
				} else {
					cleanLine = line.trim();
				}

				var tocheck = cleanLine.toLowerCase();
				
				if (tocheck.startsWith("scene ")) {
					instructions.push(parseSceneInstruction(cleanLine.substring(6)));
				} else if (tocheck.startsWith("action ")) {
					instructions.push(parseActionInstruction(cleanLine.substring(7)));
				} else if (tocheck.startsWith("effect ")) {
					instructions.push(parseEffectInstruction(cleanLine.substring(7)));
				} else if (tocheck.startsWith("textplate ")) {
					instructions.push(parseTextplateInstruction(cleanLine.substring(10)));
				} else if (tocheck.startsWith("sound ")) {
					instructions.push(parseSoundInstruction(cleanLine.substring(6)));
				} else if (tocheck.startsWith("music ")) {
					instructions.push(parseMusicInstruction(cleanLine.substring(6)));
				} else if (tocheck.startsWith("/settime")) {
					// Handle standalone /settime lines
					var textInstruction:PlotagonPlotInstruction = {
						type: "textPlate",
						parameters: {
							GUID: Script2Plot.generateGUID(),
							extensiondata: true,
							isRecorded: false,
							playRecording: false,
							extrasEnabled: false,
							alignment: "center",
							text: cleanLine
						}
					};
					instructions.push(textInstruction);
				} else {
					// This line doesn't match any pattern
					// It might be malformed dialogue or unexpected content
					parserErrors.push({ line: lineNum, message: "Unrecognized instruction: " + trimmed });
				}
			} catch (e:Dynamic) {
				parserErrors.push({ line: lineNum, message: "Error parsing line: " + e });
			}
			
			i++;
		}
		
		// Add title card instruction
		var titleInstruction:PlotagonPlotInstruction = {
			type: "textPlate",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: false,
				alignment: "center",
				text: "/settime 0.00001 THIS PLOT WAS MADE WITH PLOT2SCRIPT"
			}
		};
		instructions.unshift(titleInstruction);
		
		var plotId = Script2Plot.generateGUID();

		// Converting `Date` to ISO 8601 standard format.
		var plotTime = getISO8601DateTimeNoMs();
		
		return {
			id: plotId,
			name: plotTitle,
			dateCreated: plotTime,
			dateUpdated: plotTime,
			thumbnail: "",
			lengthSeconds: "0",
			voicerecordings: [],
			contents: {
				selectedIndex: 1,
				instructions: instructions
			}
		};
	}

	function getISO8601DateTimeNoMs():String {
		var d = Date.now();
		var pad = function(v:Int, ?c:Int):String {
			return StringTools.lpad(Std.string(v), "0", c);
		};
		
		var year = pad(d.getFullYear(), 4);
		var month = pad(d.getMonth() + 1, 2);
		var day = pad(d.getDate(), 2);
		var hours = pad(d.getHours(), 2);
		var minutes = pad(d.getMinutes(), 2);
		var seconds = pad(d.getSeconds(), 2);
		
		// ISO 8601 without milliseconds
		return '${year}-${month}-${day}T${hours}:${minutes}:${seconds}';
	}
	
	function parseNamedParams(paramStr:String):Map<String, String> {
		var params = new Map<String, String>();
		var parts = paramStr.trim().split(" ");
		
		for (part in parts) {
			if (part.indexOf("=") != -1) {
				var keyValue = part.split("=");
				params.set(keyValue[0], keyValue.slice(1).join("="));
			}
		}
		
		return params;
	}
	
	function resolveCharacter(name:String):Character {
		if (characters.exists(name)) {
			var character = characters.get(name);
			var id = character.id;

			// Finds the parent character if it exists by the alias
			// NOTE: I had written this completely by myself without copying any code from deepseek that it gave me.
			if (characters.exists(id)) {
				var parentCharacter = characters.get(id);
				return { name: name, id: parentCharacter.id, guid: parentCharacter.guid };
			}

			return characters.get(name);
		}
		
		// If not found, create a new character with this name as both name and ID
		// The GUID will be generated
		return { name: name, id: name, guid: Script2Plot.generateGUID() };
	}
	
	function parseSceneInstruction(paramStr:String):PlotagonPlotInstruction {
		var params = parseNamedParams(paramStr);
		var instruction:PlotagonPlotInstruction = {
			type: "scene",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: params.exists("extras") && params.get("extras") == "true"
			}
		};
		
		if (params.exists("scene")) {
			var scene = params.get("scene");
			instruction.parameters.scene = { id: scene, text: scene };
		}
		if (params.exists("loc1")) {
			var loc1 = params.get("loc1");
			instruction.parameters.location1 = { id: loc1, text: loc1 };
		}
		if (params.exists("loc2")) {
			var loc2 = params.get("loc2");
			instruction.parameters.location2 = { id: loc2, text: loc2 };
		}
		if (params.exists("actor1")) {
			var actor1 = resolveCharacter(params.get("actor1"));
			instruction.parameters.actor1 = { id: actor1.id, text: actor1.name };
		}
		if (params.exists("actor2")) {
			var actor2 = resolveCharacter(params.get("actor2"));
			instruction.parameters.actor2 = { id: actor2.id, text: actor2.name };
		}
		if (params.exists("camera")) {
			var cameraId = Std.parseInt(params.get("camera"));
			if (cameraId != null) {
				instruction.parameters.camera = {
					type: { id: cameraId, text: Script2Plot.cameraTypeNames.get(cameraId) }
				};
			}
		}
		if (params.exists("volume")) {
			instruction.parameters.volume = Std.parseFloat(params.get("volume"));
		}
		if (params.exists("extrasAttentive")) {
			instruction.parameters.extrasAttentive = params.get("extrasAttentive") == "true";
		}
		
		return instruction;
	}
	
	function parseActionInstruction(paramStr:String):PlotagonPlotInstruction {
		var params = parseNamedParams(paramStr);
		var instruction:PlotagonPlotInstruction = {
			type: "action",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: false
			}
		};
		
		if (params.exists("type")) {
			var actionType = params.get("type");
			instruction.parameters.action = { id: actionType, text: actionType };
		}
		if (params.exists("char") || params.exists("character")) {
			var charName = params.exists("char") ? params.get("char") : params.get("character");
			var char = resolveCharacter(charName);
			instruction.parameters.character = { id: char.id, text: char.name };
		}
		if (params.exists("target") || params.exists("tgt")) {
			var targetName = params.exists("target") ? params.get("target") : params.get("tgt");
			var target = resolveCharacter(targetName);
			instruction.parameters.target = { id: target.id, text: target.name };
		}
		if (params.exists("camera") || params.exists("cam")) {
			var cameraId = Std.parseInt(params.exists("camera") ? params.get("camera") : params.get("cam"));
			if (cameraId != null) {
				instruction.parameters.camera = {
					type: { id: cameraId, text: Script2Plot.cameraTypeNames.get(cameraId) }
				};
			}
		}
		
		return instruction;
	}
	
	function parseEffectInstruction(paramStr:String):PlotagonPlotInstruction {
		// Split by space followed by /
		var effects = new Array<String>();
		var tempStr = paramStr.trim();
		var start = 0;
		
		while (start < tempStr.length) {
			var slashPos = tempStr.indexOf("/", start);
			if (slashPos == -1) break;
			
			// Find the end of this effect (next slash or end of string)
			var nextSlash = tempStr.indexOf("/", slashPos + 1);
			var end = (nextSlash == -1) ? tempStr.length : nextSlash;
			
			var effect = tempStr.substring(slashPos, end).trim();
			if (effect.length > 0) {
				effects.push(effect);
			}
			
			start = end;
		}
		
		var effectObjects:Array<PlotagonEffectObject> = [];
		
		for (effect in effects) {
			var parts = effect.split(":");
			var effectName = parts[0].trim();
			var effectValue = parts.length > 1 ? parts[1].trim() : "1.0";
			
			effectObjects.push({
				EffectName: Script2Plot.effectNames.get(effectName),
				EffectValue: effectValue
			});
		}

		var effectText = effects.join(" ").replace(":", " ");
		
		return {
			type: "effect",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: false,
				effectsName: effectObjects,
				character: { id: "", text: "EFFECT" },
				text: { id: "", text: effectText }
			}
		};
	}
	
	function parseTextplateInstruction(paramStr:String):PlotagonPlotInstruction {
		var colonIndex = paramStr.indexOf(":");
		if (colonIndex == -1) {
			throw "Textplate missing colon before text";
		}
		
		var paramStrPart = paramStr.substring(0, colonIndex);
		var text = paramStr.substring(colonIndex + 1).trim();
		var params = parseNamedParams(paramStrPart);
		
		var instruction:PlotagonPlotInstruction = {
			type: "textPlate",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: false,
				text: text
			}
		};
		
		instruction.parameters.alignment = params.exists("align") ? params.get("align") : "center";
		
		if (params.exists("char") || params.exists("character")) {
			if (params.exists("char") || params.exists("character")) {
				var charName = params.exists("char") ? params.get("char") : params.get("character");
				var char = resolveCharacter(charName);
				instruction.parameters.character = { id: char.id, text: char.name };
			} else {
				instruction.parameters.character = { id: "", text: "None" };
			}
		}
		if (params.exists("vol") || params.exists("volume")) {
			var vol = params.exists("vol") ? params.get("vol") : params.get("volume");
			instruction.parameters.volume = Std.parseFloat(vol);
		} else {
			instruction.parameters.volume = 1.0;
		}
		
		return instruction;
	}
	
	function parseSoundInstruction(paramStr:String):PlotagonPlotInstruction {
		var params = parseNamedParams(paramStr);
		
		var instruction:PlotagonPlotInstruction = {
			type: "sound",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: false
			}
		};
		
		if (params.exists("sound")) {
			var sound = params.get("sound");
			instruction.parameters.sound = { id: sound, text: sound };
		}
		if (params.exists("vol") || params.exists("volume")) {
			var vol = params.exists("vol") ? params.get("vol") : params.get("volume");
			instruction.parameters.volume = Std.parseFloat(vol);
		}
		
		return instruction;
	}
	
	function parseMusicInstruction(paramStr:String):PlotagonPlotInstruction {
		var params = parseNamedParams(paramStr);
		
		var instruction:PlotagonPlotInstruction = {
			type: "music",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: false
			}
		};
		
		if (params.exists("music")) {
			var track = params.get("music");
			instruction.parameters.music = { id: track, text: track };
		}
		if (params.exists("vol") || params.exists("volume")) {
			var vol = params.exists("vol") ? params.get("vol") : params.get("volume");
			instruction.parameters.volume = Std.parseFloat(vol);
		}
		
		return instruction;
	}
	
	function parseDialogueInstruction(lines:Array<String>, startIndex:Int):PlotagonPlotInstruction {
		if (startIndex >= lines.length) return null;
		
		var line = lines[startIndex];
		var trimmed = line.trim();
		
		// Match character(expression) pattern
		var dialogueMatch = ~/^(\w+)\(([^)]+)\)$/;
		
		if (!dialogueMatch.match(trimmed)) {
			return null;
		}
		
		var charName = dialogueMatch.matched(1);
		var expression = dialogueMatch.matched(2);
		
		// CHARACTER AUTOCOMPLETION: Find the best matching character name
		if (!characters.exists(charName)) {
			var bestMatch = findBestCharacterMatch(charName);
			if (bestMatch != null) {
				Sys.println('Warning: Character "$charName" not found. Did you mean "$bestMatch"? Using "$bestMatch" instead.');
				charName = bestMatch;
			}
		}
		
		// Now find the text line
		var lineIndex = startIndex + 1;
		var paramLine = "";
		var textLine = "";
		
		// Skip empty lines but NOT comments when looking for parameters/text
		// We need to be more careful about what we skip
		while (lineIndex < lines.length) {
			var currentLine = lines[lineIndex];
			var currentTrimmed = currentLine.trim();
			
			// Skip only truly empty lines (whitespace only)
			if (currentTrimmed.length == 0) {
				lineIndex++;
				continue;
			}
			
			// Check if this could be a parameter line (contains = and doesn't start with /)
			// BUT we should also check if it's actually part of dialogue text that happens to contain =
			if (currentTrimmed.indexOf("=") != -1 && !currentTrimmed.startsWith("/") && 
				!currentTrimmed.startsWith("#")) {
				// This looks like a parameter line - but we need to be sure it's not dialogue text
				// A simple check: if it has multiple = signs or contains common parameter names
				var looksLikeParams = ~/(^|\s)(vol|cam|volume|camera)=/;
				if (looksLikeParams.match(currentTrimmed)) {
					paramLine = currentTrimmed;
					lineIndex++;
					
					// Now find the text line
					while (lineIndex < lines.length) {
						currentLine = lines[lineIndex];
						currentTrimmed = currentLine.trim();
						
						if (currentTrimmed.length == 0) {
							lineIndex++;
							continue;
						}
						
						// Found text line - could start with # or anything
						textLine = currentLine; // Keep the original line with formatting
						break;
					}
					break;
				}
			}
			
			// If we get here, this is the text line (could start with #)
			textLine = currentLine; // Keep the original line with formatting
			break;
		}
		
		if (textLine == "") {
			// No text found - this might be invalid dialogue
			return null;
		}
		
		var params = parseNamedParams(paramLine);
		var char = resolveCharacter(charName);

		var fixedText = textLine.trim().replace('"', '\\"');
		
		var instruction:PlotagonPlotInstruction = {
			type: "dialogue",
			parameters: {
				GUID: Script2Plot.generateGUID(),
				extensiondata: true,
				isRecorded: false,
				playRecording: false,
				extrasEnabled: false,
				character: { id: char.id, text: char.name },
				expression: { id: expression, text: expression },
				text: { id: "", text: fixedText }
			}
		};
		
		if (params.exists("vol") || params.exists("volume")) {
			var vol = params.exists("vol") ? params.get("vol") : params.get("volume");
			instruction.parameters.volume = Std.parseFloat(vol);
		}
		if (params.exists("cam") || params.exists("camera")) {
			var camId = Std.parseInt(params.exists("cam") ? params.get("cam") : params.get("camera"));
			if (camId != null) {
				instruction.parameters.camera = {
					type: { id: camId, text: Script2Plot.cameraTypeNames.get(camId) }
				};
			}
		}
		
		return instruction;
	}

	// Damerau-Levenshtein distance algorithm for character name autocorrection
	function damerauLevenshteinDistance(a:String, b:String):Int {
		var lenA = a.length;
		var lenB = b.length;
		var INF = lenA + lenB;
		
		// Create distance matrix
		var score = new Array<Array<Int>>();
		for (i in 0...(lenA + 2)) {
			score[i] = new Array<Int>();
			for (j in 0...(lenB + 2)) {
				score[i][j] = 0;
			}
		}
		
		score[0][0] = INF;
		for (i in 0...lenA + 1) {
			score[i + 1][1] = i;
			score[i + 1][0] = INF;
		}
		for (j in 0...lenB + 1) {
			score[1][j + 1] = j;
			score[0][j + 1] = INF;
		}
		
		// Create character dictionary for transposition handling
		var da = new Map<String, Int>();
		for (i in 0...lenA) {
			da.set(a.charAt(i), 0);
		}
		for (j in 0...lenB) {
			da.set(b.charAt(j), 0);
		}
		
		// Calculate distance
		for (i in 1...lenA + 1) {
			var db = 0;
			for (j in 1...lenB + 1) {
				var i1 = da.get(b.charAt(j - 1));
				var j1 = db;
				var cost = (a.charAt(i - 1) == b.charAt(j - 1)) ? 0 : 1;
				
				if (cost == 0) {
					db = j;
				}
				
				// Find minimum of four operations
				var substitution = score[i][j] + cost;
				var insertion = score[i + 1][j] + 1;
				var deletion = score[i][j + 1] + 1;
				var transposition = INF;
				
				if (i1 > 0 && j1 > 0) {
					transposition = score[i1][j1] + (i - i1 - 1) + 1 + (j - j1 - 1);
				}
				
				score[i + 1][j + 1] = Math.floor(Math.min(
					Math.min(substitution, insertion),
					Math.min(deletion, transposition)
				));
			}
			da.set(a.charAt(i - 1), i);
		}
		
		return score[lenA + 1][lenB + 1];
	}

	// Find the best character match using multiple strategies
	function findBestCharacterMatch(inputName:String):String {
		// Count characters using iterator instead of .count()
		var charCount = 0;
		for (_ in characters.keys()) {
			charCount++;
		}
		
		if (charCount == 0) return null;
		
		var bestMatch:String = null;
		var bestScore:Float = Math.POSITIVE_INFINITY;
		var inputLower = inputName.toLowerCase();
		
		// Strategy 1: Exact case-insensitive match
		for (charName in characters.keys()) {
			if (charName.toLowerCase() == inputLower) {
				return charName;
			}
		}
		
		// Strategy 2: Damerau-Levenshtein distance with length normalization
		for (charName in characters.keys()) {
			var distance = damerauLevenshteinDistance(inputName.toLowerCase(), charName.toLowerCase());
			var maxLen = Math.max(inputName.length, charName.length);
			var normalizedScore = distance / maxLen;
			
			// Penalize matches that are too different in length
			var lengthDiff = Math.abs(inputName.length - charName.length);
			var lengthPenalty = lengthDiff / maxLen;
			var finalScore = normalizedScore * 0.7 + lengthPenalty * 0.3;
			
			if (finalScore < bestScore) {
				bestScore = finalScore;
				bestMatch = charName;
			}
		}
		
		// Only return a match if it's reasonably close
		// Threshold based on string length
		var threshold = if (inputName.length >= 1 && inputName.length <= 3) {
			0.4;  // Shorter names need stricter matching
		} else if (inputName.length >= 4 && inputName.length <= 6) {
			0.3;
		} else {
			0.25; // Longer names allow more flexibility
		}
		
		return (bestScore <= threshold) ? bestMatch : null;
	}

	function countDialogueLines(lines:Array<String>, startIndex:Int):Int {
		var count = 1; // The character(expression) line
		
		var lineIndex = startIndex + 1;
		
		// Skip to find text line
		while (lineIndex < lines.length) {
			var line = lines[lineIndex];
			var trimmed = line.trim();
			
			// Skip only truly empty lines
			if (trimmed.length == 0) {
				lineIndex++;
				count++;
				continue;
			}
			
			// Check if this could be a parameter line
			if (trimmed.indexOf("=") != -1 && !trimmed.startsWith("/") && !trimmed.startsWith("#")) {
				// Additional check for parameter-like content
				var looksLikeParams = ~/(^|\s)(vol|cam|volume|camera)=/;
				if (looksLikeParams.match(trimmed)) {
					lineIndex++;
					count++;
					
					// Skip to find text line after parameters
					while (lineIndex < lines.length) {
						line = lines[lineIndex];
						trimmed = line.trim();
						
						if (trimmed.length == 0) {
							lineIndex++;
							count++;
							continue;
						}
						
						// Found text line - could be anything including # at the start
						count++;
						return count;
					}
				}
			}
			
			// Found text line directly
			count++;
			return count;
		}
		
		return count;
	}
	
	public function getErrors():Array<ParserError> {
		return parserErrors;
	}
}

// Reverse conversion: PlotDoc to Script
class PlotDocConverter {
	public static function plotDocToScript(plotDoc:PlotagonPlotFile):String {
		var script = new StringBuf();
		var foundCharacters = new Map<String, String>();
		var characterGUIDs = new Map<String, String>();
		
		// Extract characters
		for (instruction in plotDoc.contents.instructions) {
			var params = instruction.parameters;
			
			if (params.character != null && params.character.id != "") {
				foundCharacters.set(params.character.text, params.character.id);
			}
			if (params.actor1 != null) {
				foundCharacters.set(params.actor1.text, params.actor1.id);
			}
			if (params.actor2 != null) {
				foundCharacters.set(params.actor2.text, params.actor2.id);
			}
			if (params.target != null) {
				foundCharacters.set(params.target.text, params.target.id);
			}
		}
		
		// Add character definitions
		if (foundCharacters.keys().hasNext()) {
			script.add("# Character definitions\n");
			for (charName in foundCharacters.keys()) {
				var charId = foundCharacters.get(charName);
				if (charId != charName) {
					script.add('@char $charName = $charId\n');
				}
			}
			script.add("\n");
		}
		
		// Add title if different from default
		if (plotDoc.name != "Generated with Plot2Script" && plotDoc.name != "Generated with ScriptToPlot") {
			script.add('@title ${plotDoc.name}\n\n');
		}
		
		// Convert instructions
		for (instruction in plotDoc.contents.instructions) {
			var params = instruction.parameters;
			
			switch (instruction.type) {
				case "scene":
					script.add("Scene");
					if (params.scene != null) script.add(' scene=${params.scene.id}');
					if (params.location1 != null) script.add(' loc1=${params.location1.id}');
					if (params.location2 != null) script.add(' loc2=${params.location2.id}');
					if (params.actor1 != null) script.add(' actor1=${params.actor1.text}');
					if (params.actor2 != null) script.add(' actor2=${params.actor2.text}');
					if (params.camera != null) script.add(' camera=${params.camera.type.id}');
					if (params.volume != null) script.add(' volume=${params.volume}');
					if (params.extrasEnabled) script.add(' extras=${params.extrasEnabled}');
					if (params.extrasAttentive != null) script.add(' extrasAttentive=${params.extrasAttentive}');
					script.add("\n\n");
					
				case "dialogue":
					script.add('${params.character.text}(${params.expression.id})\n');
					var hasParams = false;
					if (params.volume != null) {
						script.add('vol=${params.volume}');
						hasParams = true;
					}
					if (params.camera != null) {
						if (hasParams) script.add(" ");
						script.add('cam=${params.camera.type.id}');
						hasParams = true;
					}
					if (hasParams) script.add("\n");
					var text:Dynamic = params.text;
					var textStr = Std.isOfType(text, String) ? text : text.text;
					script.add('$textStr\n\n');
					
				case "action":
					script.add("Action");
					if (params.action != null) script.add(' type=${params.action.id}');
					if (params.character != null) script.add(' char=${params.character.text}');
					if (params.target != null) script.add(' target=${params.target.text}');
					if (params.camera != null) script.add(' cam=${params.camera.type.id}');
					script.add("\n\n");
					
				case "effect":
					script.add("Effect");
					if (params.effectsName != null) {
						for (effect in params.effectsName) {
							var effectCmd = Script2Plot.reverseEffectNames.get(effect.EffectName);
							if (effectCmd != null) {
								script.add(' $effectCmd');
								if (effect.EffectValue != "1.0") {
									script.add(':${effect.EffectValue}');
								}
							}
						}
					}
					script.add("\n\n");
					
				case "textPlate":
					var textStr = Std.string(params.text);
					if (textStr.indexOf("/settime 0.00001 THIS PLOT WAS MADE") == -1) {
						script.add("Textplate");
						if (params.character != null) script.add(' char=${params.character.text}');
						if (params.alignment != null) script.add(' align=${params.alignment}');
						if (params.volume != null) script.add(' vol=${params.volume}');
						script.add(': ${params.text}\n\n');
					}
					
				case "sound":
					script.add("Sound");
					if (params.sound != null) script.add(' sound=${params.sound.id}');
					if (params.volume != null) script.add(' vol=${params.volume}');
					script.add("\n\n");
					
				case "music":
					script.add("Music");
					if (params.music != null) script.add(' music=${params.music.id}');
					if (params.volume != null) script.add(' vol=${params.volume}');
					script.add("\n\n");
			}
		}
		
		return script.toString();
	}
}

@:publicFields
class Script2Plot {
    static var cameraTypeNames:Map<Int, String> = [
        1 => "establishing shot",
        2 => "in dialogue mode",
        3 => "in interaction mode",
        4 => "moving right",
        5 => "moving left",
        6 => "moving forward",
        7 => "moving backward",
        8 => "wide shot",
        9 => "still",
        10 => "skipping establishing shot"
    ];

    static var effectNames:Map<String, String> = [
        "/fadeinb" => "FadeInB",
        "/fadeoutb" => "FadeOutB",
        "/fadeinw" => "FadeInW",
        "/fadeoutw" => "FadeOutW",
        "/fadeinp" => "FadeInP",
        "/fadeoutp" => "FadeOutP",
        "/vignette" => "Vignette",
        "/retro" => "Sepia",
        "/old" => "BlackAndWhite",
        "/bloom" => "Bloom",
        "/setfov" => "SetFov",
        "/normal" => "PreviewBlit"
    ];

    static var reverseEffectNames:Map<String, String> = [
        "FadeInB" => "/fadeinb",
        "FadeOutB" => "/fadeoutb",
        "FadeInW" => "/fadeinw",
        "FadeOutW" => "/fadeoutw",
        "FadeInP" => "/fadeinp",
        "FadeOutP" => "/fadeoutp",
        "Vignette" => "/vignette",
        "Sepia" => "/retro",
        "BlackAndWhite" => "/old",
        "Bloom" => "/bloom",
        "SetFov" => "/setfov",
        "PreviewBlit" => "/normal"
    ];

    static var reverseCameraNames:Map<String, Int> = [
        "establishing shot" => 1,
        "in dialogue mode" => 2,
        "in interaction mode" => 3,
        "moving right" => 4,
        "moving left" => 5,
        "moving forward" => 6,
        "moving backward" => 7,
        "wide shot" => 8,
        "still" => 9,
        "skipping establishing shot" => 10
    ];

    static function generateGUID():String {
        var hexChars = '0123456789abcdef';
        var result:StringBuf = new StringBuf();

        for (i in 0...8) {
            result.add(hexChars.charAt(Std.int(Math.random() * 16)));
        }
        result.add('-');
        for (i in 0...4) {
            result.add(hexChars.charAt(Std.int(Math.random() * 16)));
        }
        result.add('-');
        for (i in 0...4) {
            result.add(hexChars.charAt(Std.int(Math.random() * 16)));
        }
        result.add('-');
        for (i in 0...4) {
            result.add(hexChars.charAt(Std.int(Math.random() * 16)));
        }
        result.add('-');
        for (i in 0...12) {
            result.add(hexChars.charAt(Std.int(Math.random() * 16)));
        }
        return result.toString();
    }

    static function main() {
        var args = Sys.args();
        
        if (args.length < 2) {
            Sys.println("Usage: Plot2Script <command> <input_file> [output_file *without extension]");
            Sys.println("Commands:");
            Sys.println("  parse     - Parse script file to Plotagon JSON");
            Sys.println("  convert   - Convert Plotagon JSON back to script");
            Sys.println("  syntax    - Show syntax reference");
            return;
        }
        
        var command = args[0];
        var inputFile = args[1];
        var outputFile = args.length > 2 ? args[2] : null;
        
        switch (command) {
            case "parse":
                try {
                    var script = File.getContent(inputFile);
                    var parser = new ScriptParser();
                    var plotDoc = parser.parseScript(script);
                    
                    var errors = parser.getErrors();
                    if (errors.length > 0) {
                        Sys.println("Parse errors:");
                        for (error in errors) {
                            Sys.println('Line ${error.line}: ${error.message}');
                        }
                    }
                    
                    var json = myOwnStringifyCuzPlotagonForcesJsonOrdering(plotDoc);
                    
                    if (outputFile == null)
						outputFile = '${plotDoc.id}.plotdoc';
					else
						plotDoc.id = outputFile;

					File.saveContent('$outputFile.plotdoc', json);
					Sys.println("Successfully parsed script to: " + outputFile);
                } catch (e:Dynamic) {
                    Sys.println("Error: " + e);
                }
                
            case "convert":
                try {
                    var json = File.getContent(inputFile);
                    var plotDoc:PlotagonPlotFile = Json.parse(json);
                    var script = PlotDocConverter.plotDocToScript(plotDoc);
                    
                    if (outputFile != null) {
                        File.saveContent(outputFile, script);
                        Sys.println("Successfully converted to script: " + outputFile);
                    } else {
                        Sys.println(script);
                    }
                    
                } catch (e:Dynamic) {
                    Sys.println("Error: " + e);
                }
                
            case "syntax":
                showSyntaxReference();
                
            default:
                Sys.println("Unknown command: " + command);
        }
    }
    
    static function showSyntaxReference() {
        Sys.println("=== Plot2Script Syntax Reference ===\n");
        Sys.println("Character Definitions:");
        Sys.println("  @char Name = character_id");
        Sys.println("  @char Alias = ExistingChar");
        Sys.println("  @title Plot Title\n");
        
        Sys.println("Scene:");
        Sys.println("  Scene scene=id loc1=l1 loc2=l2 actor1=A1 actor2=A2 camera=1 volume=0.8 extras=true");
        Sys.println("");
        
        Sys.println("Dialogue:");
        Sys.println("  Character(expression)");
        Sys.println("  vol=0.8 cam=2  (optional parameter line)");
        Sys.println("  Dialogue text here");
        Sys.println("");
        
        Sys.println("Action:");
        Sys.println("  Action type=wave char=C1 target=C2 cam=2");
        Sys.println("");
        
        Sys.println("Effect:");
        Sys.println("  Effect /fadeinb /fadeoutb /fadeinw /fadeoutw");
        Sys.println("  Effect /fadeinp /fadeoutp /vignette /retro");
        Sys.println("  Effect /old /bloom:0.5 /setfov:1.2 /normal");
        Sys.println("");
        
        Sys.println("Textplate:");
        Sys.println("  Textplate char=C1 align=center vol=0.7: Text content here");
        Sys.println("");
        
        Sys.println("Sound/Music:");
        Sys.println("  Sound sound=id vol=0.6");
        Sys.println("  Music music=id vol=0.4");
        Sys.println("");
        
        Sys.println("Comments start with #");
    }
    
    // Stringify functions (same as before but updated for new types)
    static function myOwnStringifyCuzPlotagonForcesJsonOrdering(plot:PlotagonPlotFile) {
        var result = "{";
        result += '\n  \"id\": \"${plot.id}\",';
        result += '\n  \"name\": \"${plot.name}\",';
        result += '\n  \"dateCreated\": \"${plot.dateCreated}\",';
        result += '\n  \"dateUpdated\": \"${plot.dateUpdated}\",';
        result += '\n  \"thumbnail\": \"${plot.thumbnail}\",';
        result += '\n  \"lengthSeconds\": \"${plot.lengthSeconds}\",';
        result += '\n  \"voicerecordings\": [],';
        result += '\n  \"contents\": {\n    \"selectedIndex\": ${plot.contents.selectedIndex},';
        result += '\n    \"instructions\": ${stringifyPlotagonInstructions(plot.contents.instructions)}';
        result += '\n  }';
        result += '\n}';
        return result;
    }
    
    static function stringifyPlotagonInstructions(instructions:Array<PlotagonPlotInstruction>) {
        var result = '[';
        for (i in 0...instructions.length) {
            var instruction = instructions[i];
            var parameters = instruction.parameters;
            result += '\n      {';
            result += '\n        \"type\": \"${instruction.type}\",';
            result += '\n        \"parameters\": {';
            result += '\n          \"GUID\": \"${parameters.GUID}\",';
            result += '\n          \"extensiondata\": ${parameters.extensiondata},';
            result += '\n          \"isRecorded\": ${parameters.isRecorded},';
            result += '\n          \"playRecording\": ${parameters.playRecording}';
            result += ',\n          \"extrasEnabled\": ${parameters.extrasEnabled}';
            if (parameters.alignment != null) result += ',\n          \"alignment\": \"${parameters.alignment}\"';
            if (parameters.scene != null) result += ',\n          \"scene\": ${stringifyPlotagonObject(parameters.scene)}';
            if (parameters.music != null) result += ',\n          \"music\": ${stringifyPlotagonObject(parameters.music)}';
            if (parameters.sound != null) result += ',\n          \"sound\": ${stringifyPlotagonObject(parameters.sound)}';
            if (parameters.expression != null) result += ',\n          \"expression\": ${stringifyPlotagonObject(parameters.expression)}';
            if (parameters.text != null) {
                var text = parameters.text;
                if (Std.isOfType(text, String)) {
                    result += ',\n          \"text\": \"${text}\"';
                } else {
                    result += ',\n          \"text\": ${stringifyPlotagonObject(text)}';
                }
            }
            if (parameters.effectsName != null) result += ',\n          \"effectsName\": ${stringifyPlotagonEffectObjects(parameters.effectsName)}';
            if (parameters.character != null) result += ',\n          \"character\": ${stringifyPlotagonObject(parameters.character)}';
            if (parameters.target != null) result += ',\n          \"target\": ${stringifyPlotagonObject(parameters.target)}';
            if (parameters.action != null) result += ',\n          \"action\": ${stringifyPlotagonObject(parameters.action)}';
            if (parameters.location1 != null) result += ',\n          \"location1\": ${stringifyPlotagonObject(parameters.location1)}';
            if (parameters.location2 != null) result += ',\n          \"location2\": ${stringifyPlotagonObject(parameters.location2)}';
            if (parameters.actor1 != null) result += ',\n          \"actor1\": ${stringifyPlotagonObject(parameters.actor1)}';
            if (parameters.actor2 != null) result += ',\n          \"actor2\": ${stringifyPlotagonObject(parameters.actor2)}';
            if (parameters.camera != null) result += ',\n          \"camera\": ${stringifyPlotagonCamera(parameters.camera)}';
            if (parameters.extrasAttentive != null) result += ',\n          \"extrasAttentive\": ${parameters.extrasAttentive}';
            if (parameters.volume != null) result += ',\n          \"volume\": ${parameters.volume}';
            result += '\n        }';
            result += '\n      }';
            if (i != instructions.length-1) result += ',';
        }
        result += '\n    ]';
        return result;
    }
    
    static function stringifyPlotagonObject(obj:PlotagonObject) {
        var result = '{';
        result += '\n            \"id\": \"${obj.id}\",';
        result += '\n            \"text\": \"${obj.text}\"\n          }';
        return result;
    }
    
    static function stringifyPlotagonCamera(camera:PlotagonCamera) {
        var result = '{';
        result += '\n            \"type\": {';
        result += '\n              \"id\": ${camera.type.id},';
        result += '\n              \"text\": \"${camera.type.text}\"';
        result += '\n            }';
        if (camera.position != null) result += ',\n            \"position\": ${stringifyPlotagonCameraAngleObject(camera.position)}';
        if (camera.target != null) result += ',\n            \"target\": ${stringifyPlotagonCameraAngleObject(camera.target)}';
        result += '\n          }';
        return result;
    }
    
    static function stringifyPlotagonCameraAngleObject(obj:PlotagonCameraAngleObject) {
        var result = '{';
        result += '\n              \"id\": \"${obj.id}\",';
        result += '\n              \"name\": \"${obj.name}\"';
        if (obj.useLocations != null) result += ',\n              \"useLocations\": ${obj.useLocations}';
        result += '\n            }';
        return result;
    }
    
    static function stringifyPlotagonEffectObjects(objs:Array<PlotagonEffectObject>) {
        var result = '[';
        for (i in 0...objs.length) {
            var obj = objs[i];
            result += '\n            {';
            result += '\n              \"EffectName\": \"${obj.EffectName}\",';
            result += '\n              \"EffectValue\": \"${obj.EffectValue}\"';
            result += '\n            }';
            if (i != objs.length - 1) result += ',';
        }
        result += '\n          ]';
        return result;
    }
}

// Type definitions
typedef Character = {
    var name:String;
    var id:String;
    var guid:String;
}

typedef ParserError = {
    var line:Int;
    var message:String;
}

typedef PlotagonPlotFile = {
    var id:String;
    var name:String;
    var dateCreated:String;
    var dateUpdated:String;
    var thumbnail:String;
    var lengthSeconds:String;
    var voicerecordings:Array<Dynamic>;
    var contents:PlotagonPlotContent;
}

typedef PlotagonPlotContent = {
    var selectedIndex:Int;
    var instructions:Array<PlotagonPlotInstruction>;
}

typedef PlotagonPlotInstruction = {
    var type:String;
    var parameters:PlotagonPlotInstructionParameters;
}

typedef PlotagonPlotInstructionParameters = {
    var GUID:String;
    var extensiondata:Bool;
    var isRecorded:Bool;
    var playRecording:Bool;
    var extrasEnabled:Bool;
    @:optional var extrasAttentive:Bool;
    @:optional var alignment:String;
    @:optional var sound:PlotagonObject;
    @:optional var music:PlotagonObject;
    @:optional var scene:PlotagonObject;
    @:optional var location1:PlotagonObject;
    @:optional var location2:PlotagonObject;
    @:optional var actor1:PlotagonObject;
    @:optional var actor2:PlotagonObject;
    @:optional var expression:PlotagonObject;
    @:optional var camera:PlotagonCamera;
    @:optional var effectsName:Array<PlotagonEffectObject>;
    @:optional var character:PlotagonObject;
    @:optional var target:PlotagonObject;
    @:optional var action:PlotagonObject;
    @:optional var text:Dynamic;
    @:optional var volume:Float;
}

typedef PlotagonEffectObject = {
    var EffectName:String;
    var EffectValue:String;
}

typedef PlotagonCamera = {
    var type:PlotagonCameraType;
    @:optional var position:PlotagonCameraAngleObject;
    @:optional var target:PlotagonCameraAngleObject;
}

typedef PlotagonCameraType = {
    var id:Int;
    var text:String;
}

typedef PlotagonCameraAngleObject = {
    var id:String;
    var name:String;
    @:optional var useLocations:Bool;
}

typedef PlotagonObject = {
    var id:String;
    var text:String;
}