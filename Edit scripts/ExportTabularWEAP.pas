unit ExportTabularWEAP;

uses ExportCore,
     ExportTabularCore,
     ExportJson,
     ExportTabularLOC;


var ExportTabularWEAP_outputLines: TStringList;
var ExportTabularWEAP_LOC_outputLines: TStringList;


function initialize(): Integer;
begin
    ExportTabularWEAP_outputLines := TStringList.create();
    ExportTabularWEAP_outputLines.add(
        '"File", ' +                  // Name of the originating ESM
        '"Form ID", ' +               // Form ID
        '"Editor ID", ' +             // Editor ID
        '"Name", ' +                  // Full name
        '"Weight", ' +                // Item weight in pounds
        '"Value", ' +                 // Item value in bottlecaps
        '"Health", ' +                // Item health in points
        '"Levels", ' +                // Sorted JSON array of possible weapon levels
        '"DR curve", ' +              // Damage Resistance curve
        '"Durability min curve", ' +  // Min durability curve
        '"Durability max curve", ' +  // Max durability curve
        '"Condition dmg curve", ' +   // Condition damage scale factor curve
        '"Attach slots", ' +          // Sorted JSON array of attachment slots available to the weapon
        '"Equipment type", ' +        // Equipment type
        '"Keywords"'                  // Sorted JSON array of keywords. Each keyword is represented as
                                      // `{EditorID} [KYWD:{FormID}]`
    );

    ExportTabularWEAP_LOC_outputLines := initLocList();
end;

function process(el: IInterface): Integer;
begin
    if signature(el) <> 'WEAP' then begin exit; end;

    _process(el);
end;

function _process(weap: IInterface): Integer;
var data: IInterface;
    locations: TStringList;
begin
    data := elementBySignature(weap, 'DNAM');

    ExportTabularWEAP_outputLines.add(
        escapeCsvString(getFileName(getFile(weap))) + ', ' +
        escapeCsvString(stringFormID(weap)) + ', ' +
        escapeCsvString(getEditValue(elementBySignature(weap, 'EDID'))) + ', ' +
        escapeCsvString(getEditValue(elementBySignature(weap, 'FULL'))) + ', ' +
        escapeCsvString(getEditValue(elementByName(data, 'Weight'))) + ', ' +
        escapeCsvString(getEditValue(elementByName(data, 'Value'))) + ', ' +
        escapeCsvString(getEditValue(elementByName(data, 'Health'))) + ', ' +
        escapeCsvString(getJsonChildArray(elementBySignature(weap, 'EILV'))) + ',' +
        escapeCsvString(getEditValue(elementBySignature(weap, 'CVT0'))) + ',' +
        escapeCsvString(getEditValue(elementBySignature(weap, 'CVT1'))) + ',' +
        escapeCsvString(getEditValue(elementBySignature(weap, 'CVT3'))) + ',' +
        escapeCsvString(getEditValue(elementBySignature(weap, 'CVT2'))) + ',' +
        escapeCsvString(getJsonChildArray(elementBySignature(weap, 'APPR'))) + ',' +
        escapeCsvString(getEditValue(elementBySignature(weap, 'ETYP'))) + ', ' +
        escapeCsvString(getJsonChildArray(elementByPath(weap, 'Keywords\KWDA')))
    );

    appendLocationData(ExportTabularWEAP_LOC_outputLines, weap);
end;

function finalize(): Integer;
begin
    createDir('dumps/');

    ExportTabularWEAP_outputLines.saveToFile('dumps/WEAP.csv');
    ExportTabularWEAP_outputLines.free();

    ExportTabularWEAP_LOC_outputLines.saveToFile('dumps/WEAP_LOC.csv');
    ExportTabularWEAP_LOC_outputLines.free();
end;


end.
