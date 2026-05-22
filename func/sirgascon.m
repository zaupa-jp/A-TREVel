function Rr = sirgascon(info)
%__________________________________________________________________________
% SIRGASCON  Automatically retrieves weekly SIRGAS-CON coordinates.
%
% Input:
%   info.t0   -> datetime of the desired day
%   info.st   -> station code (4 characters)
%   info.path -> folder where the file will be saved
%
% Output:
%   Rr        -> structure containing XYZ coordinates
%
% All operations follow the official SIRGAS-CON standard:
%   https://www.sirgas.org/archive/gps/SIRGAS/<WEEK>/sirYYPWWWW.crd
%
% Implemented controls:
%   - ensures folder creation
%   - prevents saving HTML files in case of download errors
%   - converts .crd -> .txt only when the file is valid
%   - handles GPS weeks that start in the previous year
%
%   Copyright (c) 2025, João P. V. Zaupa
%__________________________________________________________________________

    %----------------------------------------------------------------------
    % 1) Create output folder if it does not exist
    %----------------------------------------------------------------------
    if ~isfolder(info.path)
        mkdir(info.path);
    end

    %----------------------------------------------------------------------
    % 2) Extract year, month, and day
    %----------------------------------------------------------------------
    year0 = year(info.t0);
    month0 = month(info.t0);
    day0 = day(info.t0);

    %----------------------------------------------------------------------
    % 3) Compute GPS week and DOY
    %----------------------------------------------------------------------
    [gpsWeek, weekDay, doy] = clc_week_number(day0, month0, year0);

    fprintf(">> GPS Week: %d | DOY = %d | Week day = %d\n", ...
        gpsWeek, doy, weekDay);

    %----------------------------------------------------------------------
    % 4) Adjust GPS year correctly
    %----------------------------------------------------------------------
    if doy <= 7 && weekDay > (doy - 1)
        fileYear = year0 - 1;
    else
        fileYear = year0;
    end

    %----------------------------------------------------------------------
    % 5) Build remote file name
    %----------------------------------------------------------------------
    yy = mod(fileYear, 100);
    fnameCRD = sprintf("sir%02dP%04d.crd", yy, gpsWeek);

    urlBase = sprintf("https://www.sirgas.org/archive/gps/SIRGAS/%d/", gpsWeek);
    urlFile = urlBase + fnameCRD;

    fprintf(">> Base URL: %s\n", urlBase);
    fprintf(">> Remote file name: %s\n", fnameCRD);

    %----------------------------------------------------------------------
    % 6) Local file paths
    %----------------------------------------------------------------------
    fileCRD  = fullfile(info.path, fnameCRD);
    fileHTML = fileCRD + ".html";
    fileTXT  = replace(fileCRD, ".crd", ".txt");

    %----------------------------------------------------------------------
    % 7) Safe CRD download
    %----------------------------------------------------------------------
    if ~isfile(fileCRD)
        fprintf(">> Downloading weekly file...\n");

        % Remove leftovers from previous failed downloads
        if isfile(fileHTML)
            delete(fileHTML);
        end

        try
            websave(fileCRD, urlFile);
        catch
            Rr = [];
            warning("Failed to access SIRGAS-CON server.\nURL: %s", urlFile);
            return;
        end

        % After download, check for false HTML file
        if ~isfile(fileCRD)
            if isfile(fileHTML)
                delete(fileHTML);
                warning("No weekly SIRGAS-CON solution available for this date.\nURL: %s", urlFile);
                Rr = [];
                return;
            else
                warning("Download did not produce the expected (.crd) file.\nURL: %s", urlFile);
                Rr = [];
                return;
            end
        end
    else
        fprintf(">> File already exists locally: %s\n", fnameCRD);
    end

    %----------------------------------------------------------------------
    % 8) Ensure the file is not HTML
    %----------------------------------------------------------------------
    if isHTMLfile(fileCRD)
        delete(fileCRD);
        warning("Invalid CRD file (HTML content). URL: %s", urlFile);
        Rr = [];
        return;
    end

    %----------------------------------------------------------------------
    % 9) Convert CRD → TXT if needed
    %----------------------------------------------------------------------
    if ~isfile(fileTXT)
        fprintf(">> Converting CRD to TXT...\n");
        copyfile(fileCRD, fileTXT);
    else
        fprintf(">> TXT file already exists: %s\n", fnameCRD);
    end

    %----------------------------------------------------------------------
    % 10) Read station coordinates
    %----------------------------------------------------------------------
    Rr = readSIRGASconCRD(fileTXT, info.st);

    if isempty(Rr)
        warning("Station %s not found in weekly file.", info.st);
    else
        fprintf(">> Station %s successfully loaded.\n", info.st);
    end

end
