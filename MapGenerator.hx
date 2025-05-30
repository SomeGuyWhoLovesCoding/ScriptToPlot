package;

import sys.io.File;
//import sys.FileSystem;

class MapGenerator {
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
		"/setfov" => "SetFov", // Can be between 0.5 and 1.5 as there is known evidence of it just by trying to go past 1.5 or below 0.5
		"/normal" => "PreviewBlit" // I gotta ask, why is /normal named PreviewBlit???
	];

	// This was generated with DeekSeek (AI)
	// I was too lazy to research
	static function generateGUID():String {
		/*
		My own version. Was scrapped.*/

		var hexChars = '0123456789abcdef';
		var result:StringBuf = new StringBuf();

		// 20453062-F902-9CDF-9C2N-9X2HF0K0F383

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
		

		/*var hexChars = "0123456789abcdef";
		var guid = new StringBuf();

		for (i in 0...32) {
			if (i == 12) { // Version 4 identifier
				guid.add('4');
			} else if (i == 16) { // Variant bits (8,9,a,b)
				var variantChars = ['8', '9', 'a', 'b'];
				guid.add(variantChars[Math.floor(Math.random() * 4)]);
			} else {
				guid.add(hexChars.charAt(Math.floor(Math.random() * 16)));
			}
		}

		var guidStr = guid.toString();
		return guidStr.substr(0, 8) 
			+ "-" + guidStr.substr(8, 4) 
			+ "-" + guidStr.substr(12, 4) 
			+ "-" + guidStr.substr(16, 4) 
			+ "-" + guidStr.substr(20, 12);*/
	}

	static function instructionModifyByActor(obj:PlotagonObject, actor:String, map:Map<String, String>) {
		obj.text = actor;
		var actorModified = actor;
		if (map.exists(actor)) actorModified = map[actor];
		obj.id = actorModified;
	}

	// The entry point, where all the logic goes
	static function main() {
		var args = Sys.args();
		var charMapPath = args[0];
		var scriptPath = args[1];

		// This is for presetting characters to guid's for actual plotagon plot files.
		// NOTE: Do not change this to File.getContent.
		// There was a bug in it that automatically added an "\r" at the end of each string in the map
		// and you cannot fix it no matter what, except for the change I just made.
		var map:Map<String, String> = [];
		var mapFile = File.read(charMapPath);
		while (!mapFile.eof()) {
			var parts = mapFile.readLine().split(" = ");
			map[parts[0]] = parts[1];
			//trace(map[parts[0]]);
		}

		var plotID:String = generateGUID();
		var plotTime = StringTools.replace(Date.now().toString(), " ", "T"); // This is naturally what plotagon uses
		var outputFile = File.write('$plotID.plotdoc', false);
		var inputFile = File.getContent(scriptPath);

		var plotagonPlot:PlotagonPlotFile = {
			id: plotID,
			name: "Generated with ScriptToPlot",
			dateCreated: plotTime,
			dateUpdated: plotTime,
			thumbnail: "",
			lengthSeconds: "0",
			contents: {
				selectedIndex: 1,
				instructions: [
					{
						type: "textPlate",
						parameters: {
							GUID: generateGUID(),
							extensiondata: true,
							isRecorded: false,
							playRecording: false,
							extrasEnabled: false,
							alignment: "center",
							text: "/settime 0.00001 THIS PLOT WAS MADE WITH SCRIPTTOPLOT"
						}
					}
				]
			}
		};

		var lines = inputFile.split('\n');
		for (line in lines) {
			var instruction:PlotagonPlotInstruction = {
				type: "textPlate",
				parameters: {
					GUID: generateGUID(),
					extensiondata: true,
					isRecorded: false,
					playRecording: false,
					extrasEnabled: false
				}
			};

			var split = line.split(']- ');
			if (split.length == 0) continue;
			switch (split[0]) {
				case "Effect":
					var split2 = split[1].split(" /");
					instruction.type = "effect";
					instruction.parameters.effectsName = [];
					for (i in 0...split2.length) {
						var currentEffect = StringTools.trim(split2[i]);
						var currentEffectProperties:Array<String> = currentEffect.split(" ");
						var hasMoreThanOneProperty = currentEffectProperties.length != 1;
						var effectName = (i != 0 ? '/' : '') + (hasMoreThanOneProperty ? currentEffectProperties[0] : currentEffect);
						//trace('$line: $effectName');
						instruction.parameters.effectsName.push({
							EffectName: effectNames[effectName],
							EffectValue: hasMoreThanOneProperty ? Std.string(currentEffectProperties[1]) : "1.0"
						});
					}
					instruction.parameters.character = {
						id: "",
						text: "EFFECT"
					}
					// If we only have one effect then why did we need to do this then!?
					// Cuz if you remove the check then the only effect command's text will output "/null".
					if (split[1] == "setfov") {
						split[2] = Std.string(Math.min(Math.max(Std.parseInt(split[2]), 1.5), 0.5));
					}
					instruction.parameters.text = {
						id: "",
						text: StringTools.trim(split2.length > 2 ? '/' + split2[1] : split[1])
					}
				case "Scene":
					var id = StringTools.trim(split[1]);
					instruction.type = "scene";
					instruction.parameters.scene = {
						id: id,
						text: id
					}
					if (split[2] != null && split[2] != 'none') {
						var location1 = StringTools.trim(split[2]);
						instruction.parameters.location1 = {
							id: location1,
							text: location1
						}
					}
					if (split[3] != null && split[3] != 'none') {
						var location2 = StringTools.trim(split[3]);
						instruction.parameters.location2 = {
							id: location2,
							text: location2
						}
					}
					if (split[4] != null && split[4] != 'none') {
						var actor1 = StringTools.replace(StringTools.trim(split[4]), '"', '\\"' /* For convenience */);
						instruction.parameters.actor1 = {
							id: map.exists(actor1) ? map[actor1] : actor1,
							text: actor1
						}
					}
					if (split[5] != null && split[5] != 'none') {
						var actor2 = StringTools.replace(StringTools.trim(split[5]), '"', '\\"' /* For convenience */);
						instruction.parameters.actor2 = {
							id: map.exists(actor2) ? map[actor2] : actor2,
							text: actor2
						}
					}
					if (split[6] != null && split[6] != 'none') {
						var id = Std.parseInt(StringTools.trim(split[6]));
						instruction.parameters.camera = {
							type: {
								id: id,
								text: cameraTypeNames[id]
							}
						}
						if (instruction.parameters.camera.type.id < 0 || instruction.parameters.camera.type.id > 9) instruction.parameters.camera = null;
					}
					if (split[7] != null && split[7] != 'none') instruction.parameters.volume = Std.parseFloat(split[7]);
					instruction.parameters.extrasEnabled = split[8].toLowerCase() == "true";
					instruction.parameters.extrasAttentive = split[9].toLowerCase() == "true";
				case "Textplate":
					instruction.type = "textPlate";
					var character = split[1];
					if (character != null && character != 'none') {
						instruction.parameters.character = {
							id: map.exists(character) ? map[character] : character,
							text: character
						}
					}
					instruction.parameters.alignment = StringTools.trim(split[2]);
					instruction.parameters.text = StringTools.replace(StringTools.trim(split[3]), '"', '\\"' /* For convenience */);
					if (split[4] != null && split[4] != 'none') instruction.parameters.volume = Std.parseFloat(split[4]);
				case "Sound":
					var id = split[1];
					if (id != "none") {
						instruction.type = "sound";
						instruction.parameters.sound = {
							id: id,
							text: id
						}
					}
					if (split[2] != null) instruction.parameters.volume = Std.parseFloat(split[2]);
				case "Music":
					var id = StringTools.trim(split[1]);
					if (id != "none") {
						instruction.type = "music";
						instruction.parameters.music = {
							id: id,
							text: id
						}
					}
					if (split[2] != null) instruction.parameters.volume = Std.parseFloat(split[2]);
				case "Action":
					instruction.type = "action";
					var action = split[1];
					instruction.parameters.action = {
						id: action,
						text: action
					}
					var character = StringTools.trim(split[2]);
					instruction.parameters.character = {
						id: map.exists(character) ? map[character] : character,
						text: character
					}
					var target = StringTools.trim(split[3]);
					instruction.parameters.target = {
						id: map.exists(target) ? map[target] : target,
						text: target
					}
					var id = Std.parseInt(split[4]);
					if (id != null) {
						instruction.parameters.camera = {
							type: {
								id: id,
								text: cameraTypeNames[id]
							},
							position: {
								id: "",
								name: "",
								useLocations: false
							},
							target: {
								id: "",
								name: "",
								useLocations: false
							}
						}

						var position = split[5];
						if (position != null) {
							instruction.parameters.camera.position.id = instruction.parameters.camera.position.name = position;
						} else {
							instruction.parameters.camera.position = null;
						}
						var target = split[6];
						if (target != null) {
							instruction.parameters.camera.target.id = instruction.parameters.camera.target.name = target;
						} else {
							instruction.parameters.camera.target = null;
						}
					}
				default:
					instruction.type = "dialogue";
					var character = StringTools.trim(split[0]);
					instruction.parameters.character = {
						id: map.exists(character) ? map[character] : character,
						text: character
					}
					var expression = StringTools.trim(split[1]);
					instruction.parameters.expression = {
						id: expression,
						text: expression
					}
					instruction.parameters.text = {
						id: "",
						text: split[2] != null ? StringTools.replace(StringTools.trim(split[2]), '"', '\\"' /* For convenience */) : ""
					}
					if (!Math.isNaN(Std.parseFloat(split[3]))) instruction.parameters.volume = Std.parseFloat(split[3]);
			}

			plotagonPlot.contents.instructions.push(instruction);
		}

		outputFile.writeString(myOwnStringifyCuzPlotagonForcesJsonOrdering(plotagonPlot));
		outputFile.close();
	}

	// The function name is intentionally long for a reason
	static function myOwnStringifyCuzPlotagonForcesJsonOrdering(plot:PlotagonPlotFile) {
		var result = "{";
		result += '\n  "id": "${plot.id}",';
		result += '\n  "name": "${plot.name}",';
		result += '\n  "dateCreated": "${plot.dateCreated}",';
		result += '\n  "dateUpdated": "${plot.dateUpdated}",';
		result += '\n  "thumbnail": "${plot.thumbnail}",';
		result += '\n  "lengthSeconds": "${plot.lengthSeconds}",';
		result += '\n  "voicerecordings": [],';
		result += '\n  "contents": {\n    "selectedIndex": ${plot.contents.selectedIndex},';
		result += '\n    "instructions": ${stringifyPlotagonInstructions(plot.contents.instructions)}';
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
			result += '\n        "type": "${instruction.type}",';
			result += '\n        "parameters": {';
			result += '\n          "GUID": "${parameters.GUID}",';
			result += '\n          "extensiondata": ${parameters.extensiondata},';
			result += '\n          "isRecorded": ${parameters.isRecorded},';
			result += '\n          "playRecording": ${parameters.playRecording}';
			result += ',\n          "extrasEnabled": ${parameters.extrasEnabled}';
			if (parameters.alignment != null) result += ',\n          "alignment": "${parameters.alignment}"';
			if (parameters.scene != null) result += ',\n          "scene": ${stringifyPlotagonObject(parameters.scene)}';
			if (parameters.music != null) result += ',\n          "music": ${stringifyPlotagonObject(parameters.music)}';
			if (parameters.sound != null) result += ',\n          "sound": ${stringifyPlotagonObject(parameters.sound)}';
			if (parameters.expression != null) result += ',\n          "expression": ${stringifyPlotagonObject(parameters.expression)}';
			if (parameters.text != null) result += ',\n          "text": ${(parameters.text is String ? '"${parameters.text}"' : stringifyPlotagonObject(parameters.text))}';
			if (parameters.effectsName != null) result += ',\n          "effectsName": ${stringifyPlotagonEffectObjects(parameters.effectsName)}';
			if (parameters.character != null) result += ',\n          "character": ${stringifyPlotagonObject(parameters.character)}';
			if (parameters.target != null) result += ',\n          "target": ${stringifyPlotagonObject(parameters.target)}';
			if (parameters.action != null) result += ',\n          "action": ${stringifyPlotagonObject(parameters.action)}';
			if (parameters.location1 != null) result += ',\n          "location1": ${stringifyPlotagonObject(parameters.location1)}';
			if (parameters.location2 != null) result += ',\n          "location2": ${stringifyPlotagonObject(parameters.location2)}';
			if (parameters.actor1 != null) result += ',\n          "actor1": ${stringifyPlotagonObject(parameters.actor1)}';
			if (parameters.actor2 != null) result += ',\n          "actor2": ${stringifyPlotagonObject(parameters.actor2)}';
			if (parameters.camera != null) result += ',\n          "camera": ${stringifyPlotagonCamera(parameters.camera)}';
			if (parameters.extrasAttentive != null) result += ',\n          "extrasAttentive": ${parameters.extrasAttentive}';
			if (parameters.volume != null) result += ',\n          "volume": ${parameters.volume}';
			result += '\n        }';
			result += '\n      }';
			if (i != instructions.length-1) result += ',';
		}
		result += '\n    ]';
		return result;
	}

	static function stringifyPlotagonObject(obj:PlotagonObject) {
		var result = '{';
		result += '\n            "id": "${obj.id}",';
		result += '\n            "text": "${obj.text}"\n          }';
		return result;
	}

	static function stringifyPlotagonCamera(camera:PlotagonCamera) {
		var result = '{';
		result += '\n            "type": {';
		result += '\n              "id": ${camera.type.id},';
		result += '\n              "text": "${camera.type.text}"';
		result += '\n            }';
		if (camera.position != null) result += ',\n            "position": ${stringifyPlotagonCameraAngleObject(camera.position)}';
		if (camera.target != null) result += ',\n            "target": ${stringifyPlotagonCameraAngleObject(camera.target)}';
		result += '\n          }';
		return result;
	}

	static function stringifyPlotagonCameraAngleObject(obj:PlotagonCameraAngleObject) {
		var result = '{';
		result += '\n              "id": "${obj.id}",';
		result += '\n              "name": "${obj.name}"';
		if (obj.useLocations != null) result += ',\n              "useLocations": ${obj.useLocations}\n            }';
		return result;
	}

	static function stringifyPlotagonEffectObjects(objs:Array<PlotagonEffectObject>) {
		var result = '[';
		for (i in 0...objs.length) {
			var obj = objs[i];
			result += '\n            {';
			result += '\n              "EffectName": "${obj.EffectName}",';
			result += '\n              "EffectValue": "${obj.EffectValue}"';
			result += '\n            }';
			if (i != objs.length - 1) result += ',';
		}
		result += '\n          ]';
		return result;
	}
}

typedef PlotagonPlotFile = {
	var id:String;
	var name:String;
	var dateCreated:String;
	var dateUpdated:String;
	var thumbnail:String;
	var lengthSeconds:String;
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
	@:optional var text:Dynamic; // Yes, the text is dynamic.
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