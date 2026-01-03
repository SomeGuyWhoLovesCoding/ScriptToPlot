package;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;

using StringTools;

typedef PlotagonCharacterJSON = {
    var id:String;
    var name:String;
    var defaultName:String;
    var gender:String; // Can be "male" or "female"
    var definition:PlotagonCharacterJSONDefinition;
    var backgroundColor:RGBAJson;
    var icon:String;
}

typedef PlotagonCharacterJSONDefinition = {
    var head:PlotagonCharacterPartJSON;
    var hair:PlotagonCharacterPartJSON;
    var skincolor:PlotagonCharacterPartJSON;
    var eyes:PlotagonCharacterPartJSON;
    var eyebrows:PlotagonCharacterPartJSON;
    var makeup:PlotagonCharacterPartJSON;
    var lips:PlotagonCharacterPartJSON;
    var top:PlotagonCharacterPartJSON;
    var bottom:PlotagonCharacterPartJSON;
    var shoes:PlotagonCharacterPartJSON;
    var accessories:PlotagonCharacterPartJSON;
    var facialhair:PlotagonCharacterPartJSON;
    var gums:PlotagonCharacterPartJSON;
    var voice:PlotagonCharacterPartJSON;
}

typedef PlotagonCharacterPartJSON = {
    @:optional var id:String;
    var variation:String;
}

typedef RGBAJson = {
    var r:Float;
    var g:Float;
    var b:Float;
    var a:Float;
}

class CharacterGrabber {
    static function main() {
        var sysEnvForAppData = Sys.getEnv('AppData');
        trace('%AppData% is $sysEnvForAppData');
        var programdatapathparent = '$sysEnvForAppData/Plotagon Studio_DATAPATH/Plotagon_ProgramData.json';

        if (!FileSystem.exists(programdatapathparent))
            throw "Plotagon Studio Desktop has not been installed, ever. Please install it in order for this to work.";

        var json = Json.parse(File.getContent(programdatapathparent));
        var programdatapath = json.Plotagon_programData_path; // yes that's really the variable lol
        var plotagonprogramdata = 'C:/ProgramData/$programdatapath/Bundles';
        var characters = FileSystem.readDirectory(plotagonprogramdata);
        var output = File.write("charactersToUse.s2ps");

        for (character in characters) {
            var fullPath = '$plotagonprogramdata/$character';

            if (!character.endsWith(".pcd") || FileSystem.isDirectory(fullPath))
                continue;

            /*
            // We only did this to get the character pcd's real name
            // But unfortunately there was no way to get the json out of there in the easy way so might as well give up and not do it in the first place
            var input = File.read(fullPath);
            input.seek(16, SeekBegin); // PCD has metadata that is 16 bytes long as it is
            input.readUntil('}');
            var length = input.tell() - 16;
            input.seek(16, SeekBegin); // Prepare to read to haxe.io.bytes

            var jsonBytes = input.readFullBytes(length);
            var json = jsonBytes.getString(16, length);

            var parsed:PlotagonCharacterJSON = Json.parse(json);
            */

            output.writeString('@char ${character.split("_").join(" ").replace("_", " = ").replace(".pcd", "")}\n');
            Sys.println('Map out character'/* + '${parsed.name} (${parsed.gender})'*/ + ' ($character)\n');
        }

        output.close();
    }
}