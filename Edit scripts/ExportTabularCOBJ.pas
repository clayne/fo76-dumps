unit ExportTabularCOBJ;

uses ExportCore,
     ExportTabularCore,
     ExportJson;


var ExportTabularCOBJ_outputLines: TStringList;


function initialize(): Integer;
begin
    ExportTabularCOBJ_outputLines := TStringList.create();
    ExportTabularCOBJ_outputLines.add(
            '"File"'        // Name of the originating ESM
        + ', "Form ID"'     // Form ID
        + ', "Editor ID"'   // Editor ID
        + ', "Product"'     // Reference to product
        + ', "Recipe"'      // Reference to recipe
        + ', "Components"'  // Sorted JSON array of the components needed to craft. Each component is formatted as
                            // `[editor id] ([amount])`
    );
end;

function canProcess(el: IInterface): Boolean;
begin
    result := signature(el) = 'COBJ';
end;

function process(cobj: IInterface): Integer;
var product: IInterface;
    recipe: IInterface;
begin
    if not canProcess(cobj) then begin
        addWarning(name(cobj) + ' is not a COBJ. Entry was ignored.');
        exit;
    end;

    product := eBySign(cobj, 'CNAM');
    recipe := eBySign(cobj, 'GNAM');

    ExportTabularCOBJ_outputLines.add(
          escapeCsvString(getFileName(getFile(cobj))) + ', '
        + escapeCsvString(stringFormID(cobj)) + ', '
        + escapeCsvString(evBySign(cobj, 'EDID')) + ', '
        + escapeCsvString(ifThen(not assigned(linksTo(product)), '', gev(product))) + ', '
        + escapeCsvString(ifThen(not assigned(linksTo(recipe)), '', gev(recipe))) + ', '
        + escapeCsvString(getJsonComponentArray(cobj))
    );
end;

function finalize(): Integer;
begin
    createDir('dumps/');
    ExportTabularCOBJ_outputLines.saveToFile('dumps/COBJ.csv');
    ExportTabularCOBJ_outputLines.free();
end;


(**
 * Returns the components of [cobj] as a serialized JSON array of editor IDs and counts.
 *
 * @param cobj  the constructible object to return the components of
 * @return the components of [cobj] as a serialized JSON array of editor IDs and counts
 *)
function getJsonComponentArray(cobj: IInterface): String;
var i: Integer;
    components: IInterface;
    component: IInterface;
    resultList: TStringList;
begin
    resultList := TStringList.create();

    components := eBySign(cobj, 'FVPA');
    for i := 0 to eCount(components) - 1 do begin
        component := eByIndex(components, i);

        resultList.add(
            '{' +
             '"Component":"'   + escapeJson(evByName(component, 'Component'))   + '"' +
            ',"Count":"'       + escapeJson(evByName(component, 'Count'))       + '"' +
            ',"Curve Table":"' + escapeJson(evByName(component, 'Curve Table')) + '"' +
            '}'
        );
    end;

    resultList.sort();
    result := listToJsonArray(resultList);
    resultList.free();
end;


end.
