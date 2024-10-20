unit ExportWikiTERM;

uses ExportCore,
     ExportWikiCore,
     ExportLargeFile;


var ExportWikiTERM_buffer: TStringList;
var ExportWikiTERM_size: Integer;
var ExportWikiTERM_maxSize: Integer;


function initialize(): Integer;
begin
    ExportWikiTERM_buffer := TStringList.create();
    ExportWikiTERM_size := 0;
    ExportWikiTERM_maxSize := 10000000;

    createDir('dumps/');
    clearLargeFiles('dumps/TERM.wiki');
end;

function process(el: IInterface): Integer;
begin
    if signature(el) <> 'TERM' then begin exit; end;

    _process(el);
end;

function _process(term: IInterface): Integer;
var header: String;
    contents: String;
    history: TStringList;
begin
    header := escapeWiki(trim(getEditValue(elementBySignature(term, 'WNAM'))));
    if not (header = '') then begin
        header := header + #10;
    end;

    history := TStringList.create();
    contents := trim(getTerminalContents(term, history));
    history.free();
    if not (contents = '') then begin
        contents := '' + #10 + contents + #10 + #10;
    end;

    appendLargeFile(
        'dumps/TERM.wiki',
        ExportWikiTERM_buffer,
        ExportWikiTERM_size,
        ExportWikiTERM_maxSize,
        '==[' + getFileName(getFile(term)) + '] ' +
            getEditValue(elementBySignature(term, 'FULL')) + ' (' + stringFormID(term) + ')==' + #10 +
            '{{Transcript|text=' + #10 +
            'Welcome to ROBCO Industries (TM) Termlink' + #10 +
            header +
            '}}' + #10 +
            contents
    );
end;

function finalize(): Integer;
begin
    flushLargeFile('dumps/TERM.wiki', ExportWikiTERM_buffer, ExportWikiTERM_size);
    freeLargeFile(ExportWikiTERM_buffer);
end;


function getTerminalContents(el: IInterface; history: TStringList): String;
var body: IInterface;
    bodyItem: IInterface;

    menu: IInterface;
    menuItem: IInterface;
    menuItemType: String;

    i: Integer;
begin
    history.add(stringFormID(el));

    body := elementByName(el, 'Body Text');
    for i := 0 to elementCount(body) - 1 do begin
        bodyItem := elementByIndex(body, i);

        if elementCount(elementByName(bodyItem, 'Conditions')) > 0 then begin
            result := result + '{{Info: The following body is conditional}}' + #10;
        end;
        result := result +
            '{{Transcript|text=' + #10 +
            escapeWiki(trim(getEditValue(elementBySignature(bodyItem, 'BTXT')))) + #10 +
            '}}' + #10;
    end;

    menu := elementByName(el, 'Menu Items');
    for i := 0 to elementCount(menu) - 1 do begin
        menuItem := elementByIndex(menu, i);
        menuItemType := getEditValue(elementBySignature(menuItem, 'ANAM'));

        if (menuItemType = 'Submenu - Return to Top Level') or (menuItemType = 'Submenu - Force Redraw') then begin
            continue;
        end;

        result := result + #10;
        if elementCount(elementByPath(menuItem, 'Conditions')) > 0 then begin
            result := result + '{{Info: The following header is conditional}}' + #10;
        end;

        if menuItemType = 'Display Text' then begin
            result := result +
                createWikiHeader(escapeWiki(getEditValue(elementBySignature(menuItem, 'ITXT'))), history.count) + #10 +
                '{{Transcript|text=' + #10 +
                escapeWiki(trim(getEditValue(elementBySignature(menuItem, 'UNAM')))) + #10 +
                '}}' + #10;
        end else if menuItemType = 'Submenu - Terminal' then begin
            if history.indexOf(stringFormID(linksTo(elementBySignature(menuItem, 'TNAM')))) >= 0 then begin
                if getEditValue(elementBySignature(menuItem, 'RNAM')) <> '' then begin
                    result := result +
                        createWikiHeader(
                            escapeWiki(getEditValue(elementBySignature(menuItem, 'ITXT'))),
                            history.count
                        ) + #10 +
                        '{{Transcript|text=' + #10 +
                        trim(escapeWiki(getEditValue(elementBySignature(menuItem, 'RNAM')))) + #10 +
                        '}}' + #10;
                end;
            end else begin
                result := result +
                    createWikiHeader(
                        escapeWiki(getEditValue(elementBySignature(menuItem, 'ITXT'))),
                        history.count
                    ) + #10 +
                    trim(getTerminalContents(linksTo(elementBySignature(menuItem, 'TNAM')), history)) + #10;
            end;
        end else if menuItemType = 'Display Image' then begin
            result := result + '{{Image: ' + getEditValue(elementBySignature(menuItem, 'VNAM')) + '}}' + #10;
        end else begin
            // Non-fatal error
            result := result +
                createWikiHeader(escapeWiki(getEditValue(elementBySignature(menuItem, 'ITXT'))), history.count) + #10 +
                addError('Unexpected menu item type `' + menuItemType + '`') + #10;
        end;
    end;
end;


end.
