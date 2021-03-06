unit ExportTabularCLAS;

uses ExportCore,
     ExportTabularCore,
     ExportJson;


var ExportTabularCLAS_outputLines: TStringList;


function initialize(): Integer;
begin
    ExportTabularCLAS_outputLines := TStringList.create();
    ExportTabularCLAS_outputLines.add(
            '"File"'        // Name of the originating ESM
        + ', "Form ID"'     // Form ID
        + ', "Editor ID"'   // Editor ID
        + ', "Name"'        // Full name
        + ', "Properties"'  // Sorted JSON object of properties
    );
end;

function canProcess(el: IInterface): Boolean;
begin
    result := signature(el) = 'CLAS';
end;

function process(clas: IInterface): Integer;
var acbs: IInterface;
    rnam: IInterface;
    aidt: IInterface;
    cnam: IInterface;
begin
    if not canProcess(clas) then begin
        addWarning(name(clas) + ' is not a CLAS. Entry was ignored.');
        exit;
    end;

    acbs := eBySign(clas, 'ACBS');
    rnam := linkBySign(clas, 'RNAM');
    aidt := eBySign(clas, 'AIDT');
    cnam := linkBySign(clas, 'CNAM');

    ExportTabularCLAS_outputLines.add(
          escapeCsvString(getFileName(getFile(clas))) + ', '
        + escapeCsvString(stringFormID(clas)) + ', '
        + escapeCsvString(evBySign(clas, 'EDID')) + ', '
        + escapeCsvString(evBySign(clas, 'FULL')) + ', '
        + escapeCsvString(getJsonPropertyObject(clas))
    );
end;

function finalize(): Integer;
begin
    createDir('dumps/');
    ExportTabularCLAS_outputLines.saveToFile('dumps/CLAS.csv');
    ExportTabularCLAS_outputLines.free();
end;


end.
