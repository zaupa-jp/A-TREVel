function tf = isHTMLfile(fname)
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________
    tf = false;
    fid = fopen(fname, 'r');
    if fid < 0, return; end
    firstLine = fgetl(fid);
    fclose(fid);

    if contains(upper(firstLine), "<HTML") || contains(upper(firstLine), "<!DOCTYPE")
        tf = true;
    end
end
