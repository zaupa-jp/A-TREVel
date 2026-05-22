function out = itrf2020_station_at_date(stationId, dateIn, frameTag)
%__________________________________________________________________________
%ITRF2020_STATION_AT_DATE  Get ITRF2020 (or u2023/u2024) station 
%coordinates/velocities for a given date
%
%   out = itrf2020_station_at_date(stationId, dateIn)
%   out = itrf2020_station_at_date(stationId, dateIn, frameTag)
%
% Inputs
%   stationId : 4-char code (e.g. 'GRAS') OR DOMES (e.g. '10002M006')
%   dateIn    : date of interest (datetime, 'yyyy-mm-dd', or 'dd/mm/yyyy')
%   frameTag  : 'ITRF2020' (default), 'u2023', 'u2024',
%               or 'ITRF2020-u2023', 'ITRF2020-u2024'
%
% Output (struct): same as before, plus:
%   out.frameTag : which frame update was used
%   out.filePath : URL used
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    if nargin < 3 || isempty(frameTag)
        frameTag = "ITRF2020";
    end

    frameTag = upper(strtrim(string(frameTag)));

    % --- Map tag -> URL ---
    switch frameTag
        case "ITRF2020"
            filePath = "https://itrf.ign.fr/ftp/pub/itrf/itrf2020/ITRF2020_GNSS.SSC.txt";
            outFrame = "ITRF2020";
			t0_ref = 2015.0;

        case {"U2023","ITRF2020-U2023"}
            filePath = "https://itrf.ign.fr/ftp/pub/itrf/itrf2020-u2023/ITRF2020-u2023_GNSS.SSC.txt";
            outFrame = "ITRF2020-u2023";
			t0_ref = 2015.0;

        case {"U2024","ITRF2020-U2024"}
            filePath = "https://itrf.ign.fr/ftp/pub/itrf/itrf2020-u2024/ITRF2020-u2024_GNSS.SSC.txt";
            outFrame = "ITRF2020-u2024";
			t0_ref = 2020.0;

        otherwise
            error('frameTag inválido: "%s". Use "ITRF2020", "u2023", "u2024", "ITRF2020-u2023" ou "ITRF2020-u2024".', frameTag);
    end

    % --- Reference epoch of ITRF2020 positions in this SSC file ---
    

    % --- Parse date input to datetime ---
    if isa(dateIn,'datetime')
        dtDate = dateIn;
        if isempty(dtDate.TimeZone)
            dtDate.TimeZone = 'UTC';
        else
            dtDate = datetime(dtDate,'TimeZone','UTC');
        end
    else
        dtDate = datetime(dateIn,'InputFormat','yyyy-MM-dd','TimeZone','UTC');
        if isnat(dtDate)
            dtDate = datetime(dateIn,'InputFormat','dd/MM/yyyy','TimeZone','UTC');
        end
    end
    if isnat(dtDate)
        error('Could not parse dateIn. Use datetime or "2024-06-20" or "20/06/2024".');
    end

    % --- Read SSC file (web with local fallback cache) ---
    cacheDir = fullfile(tempdir, 'ITRF_SSC_CACHE');
    if ~exist(cacheDir, 'dir')
        mkdir(cacheDir);
    end
    
    cacheFile = fullfile(cacheDir, replace(outFrame, "-", "_") + "_GNSS.SSC.txt");
    
    txt = "";
    try
        opts = weboptions('Timeout', 60);
        txt  = webread(filePath, opts);
    
        % Save/update cache
        fid = fopen(cacheFile, 'w');
        fwrite(fid, txt);
        fclose(fid);
    
    catch ME
        % Fallback to cache if available
        if exist(cacheFile, 'file')
            txt = fileread(cacheFile);
        else
            error("Could not download SSC file and no cache is available." + newline + ...
                  "URL: " + filePath + newline + ...
                  "Original error: " + ME.message);
        end
    end
    
    lines = regexp(txt, '\r\n|\n|\r', 'split');

    % Normalize stationId
    stationId = upper(string(stationId));
    stationId = strtrim(stationId);

    % Determine if it looks like DOMES or 4-char code
    isDomes = strlength(stationId) >= 7 && contains(stationId,"M"); % heuristic
    isCode4 = strlength(stationId) == 4;

    if ~(isDomes || isCode4)
        error('stationId must be a 4-char code (e.g. "GRAS") or a DOMES id (e.g. "10002M006").');
    end

    % --- Gather candidate solutions ---
    candidates = struct('domes',{},'code4',{},'soln',{}, ...
                        'X0',{},'Y0',{},'Z0',{},'sX0',{},'sY0',{},'sZ0',{}, ...
                        'Vx',{},'Vy',{},'Vz',{},'sVx',{},'sVy',{},'sVz',{}, ...
                        'tStart',{},'tEnd',{});

    i = 1;
    while i <= numel(lines)
        L1 = strtrim(lines{i});
        if L1 == ""
            i = i + 1;
            continue;
        end

        patPos = "^(?<domes>\S+)\s+.*?\s+(?<code4>[A-Z0-9]{4})\s+" + ...
         "(?<X>-?\d+\.\d+)\s+(?<Y>-?\d+\.\d+)\s+(?<Z>-?\d+\.\d+)\s+" + ...
         "(?<sX>\d+\.\d+)\s+(?<sY>\d+\.\d+)\s+(?<sZ>\d+\.\d+)" + ...
         "(?:\s+(?<soln>\d+)\s+(?<start>\d{2}:\d{3}:\d{5})\s+(?<end>\d{2}:\d{3}:\d{5}))?\s*$";

        m1 = regexp(L1, patPos, 'names');

        if ~isempty(m1)
            domesStr = upper(string(m1.domes));
            code4Str = upper(string(m1.code4));

            match = (isDomes && domesStr == stationId) || (isCode4 && code4Str == stationId);

            if match
                % Next non-empty line: velocity line
                j = i + 1;
                while j <= numel(lines) && strtrim(lines{j}) == ""
                    j = j + 1;
                end
                if j > numel(lines)
                    error('Reached EOF while expecting velocity line after a position line.');
                end
                L2 = strtrim(lines{j});

                % Parse velocity line
                C = textscan(L2, '%s %f %f %f %f %f %f', ...
                    'Delimiter', ' ', 'MultipleDelimsAsOne', true);

                if isempty(C{1}) || any(cellfun(@isempty, C(2:7)))
                    error('Could not parse velocity line for station %s near line %d.\nL2=%s', stationId, i, L2);
                end

                c.Vx  = C{2}; c.Vy  = C{3}; c.Vz  = C{4};
                c.sVx = C{5}; c.sVy = C{6}; c.sVz = C{7};

                % Validity to datetime
                if isfield(m1,'start') && ~isempty(m1.start) && ...
                   isfield(m1,'end')   && ~isempty(m1.end)
                    tS = yydddsssss_to_datetime(m1.start, "start");
                    tE = yydddsssss_to_datetime(m1.end,   "end");
                else
                    tS = datetime(0000,1,1,0,0,0,'TimeZone','UTC');
                    tE = datetime(9999,12,31,23,59,59,'TimeZone','UTC');
                end
                
                % Store
                c.domes = domesStr;
                c.code4 = code4Str;
                
                if isfield(m1,'soln') && ~isempty(m1.soln)
                    c.soln = str2double(m1.soln);
                else
                    c.soln = NaN;
                end

                c.X0 = str2double(m1.X); c.Y0 = str2double(m1.Y); c.Z0 = str2double(m1.Z);
                c.sX0 = str2double(m1.sX); c.sY0 = str2double(m1.sY); c.sZ0 = str2double(m1.sZ);

                c.tStart = tS;
                c.tEnd   = tE;

                candidates(end+1) = c; %#ok<AGROW>
                i = j; % jump
            end
        end

        i = i + 1;
    end

    if isempty(candidates)
        error('Station "%s" not found in file (%s).', stationId, outFrame);
    end

    % Choose candidate valid for requested date
    validMask = false(size(candidates));
    for k = 1:numel(candidates)
        validMask(k) = (dtDate >= candidates(k).tStart) && (dtDate <= candidates(k).tEnd);
    end

    if ~any(validMask)
        [~, idx] = min(arrayfun(@(c) min(abs(days(dtDate - c.tStart)), abs(days(dtDate - c.tEnd))), candidates));
    else
        idx = find(validMask, 1, 'last');
    end

    c = candidates(idx);

    % Propagate coordinates
    t_dec = datetime_to_decimal_year(dtDate);
    dt_years = t_dec - t0_ref;

    XYZ_ref = [c.X0, c.Y0, c.Z0];
    VXYZ    = [c.Vx, c.Vy, c.Vz];

    XYZ_date = XYZ_ref + VXYZ .* dt_years;

    sig_ref = [c.sX0, c.sY0, c.sZ0];
    sigV    = [c.sVx, c.sVy, c.sVz];
    sig_date = sqrt(sig_ref.^2 + (dt_years .* sigV).^2);

    % Output
    out = struct();
    out.frameTag = outFrame;
    out.filePath = filePath;

    out.domes = c.domes;
    out.code4 = c.code4;
    out.soln  = c.soln;

    out.tStart = c.tStart;
    out.tEnd   = c.tEnd;

    out.epoch_ref = t0_ref;

    out.XYZ_ref    = XYZ_ref;
    out.sigXYZ_ref = sig_ref;

    out.VXYZ    = VXYZ;
    out.sigVXYZ = sigV;

    out.XYZ_date    = XYZ_date;
    out.sigXYZ_date = sig_date;

    out.dateIn   = dtDate;
    out.dt_years = dt_years;
end

% ========================================================================
% Helper: Convert YY:DDD:SSSSS to datetime (UTC)
% Treat 00:000:00000 as open interval:
%  - for start -> very early
%  - for end   -> very late
% ========================================================================
function dt = yydddsssss_to_datetime(token, whichEnd)
    token = char(token);
    whichEnd = lower(string(whichEnd));

    if strcmp(token, '00:000:00000')
        if whichEnd == "start"
            dt = datetime(0000,1,1,0,0,0,'TimeZone','UTC');
        else
            dt = datetime(9999,12,31,23,59,59,'TimeZone','UTC');
        end
        return;
    end

    YY  = str2double(token(1:2));
    DDD = str2double(token(4:6));
    SSSSS = str2double(token(8:12));

    if YY >= 80
        yearFull = 1900 + YY;
    else
        yearFull = 2000 + YY;
    end

    base = datetime(yearFull,1,1,0,0,0,'TimeZone','UTC');
    dt = base + days(DDD-1) + seconds(SSSSS);
end

function y = datetime_to_decimal_year(dt)
    dt = datetime(dt,'TimeZone','UTC');

    year0 = year(dt);
    startY = datetime(year0,1,1,0,0,0,'TimeZone','UTC');
    startNext = datetime(year0+1,1,1,0,0,0,'TimeZone','UTC');

    y = year0 + seconds(dt - startY) / seconds(startNext - startY);
end