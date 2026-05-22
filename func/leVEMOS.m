function vemos = leVEMOS(arquivo)
%__________________________________________________________________________
% leVEMOS  -  Reads a VEMOS grid file (any version)
%
% Columns:
% 1) Latitude  [deg]
% 2) Longitude [deg]
% 3) vN        [m/year]
% 4) vE        [m/year]
% 5) sigmaN    [m/year] (optional)
% 6) sigmaE    [m/year] (optional)
%
% Output:
% vemos.lat
% vemos.lon
% vemos.vN
% vemos.vE
% vemos.vU
% vemos.sigN
% vemos.sigE
% vemos.sigU
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P. V. Zaupa
%__________________________________________________________________________

    if nargin < 1
        error('You must provide the VEMOS file (e.g., "VEMOS2022.txt").');
    end

    dados = readmatrix(arquivo);

    if size(dados,2) < 4
        error('VEMOS file must contain at least 4 columns: lat, lon, vN, vE.');
    end

    vemos.lat = dados(:,1);
    vemos.lon = dados(:,2);
    vemos.vN  = dados(:,3);
    vemos.vE  = dados(:,4);

    % Vertical component not provided by VEMOS
    vemos.vU = 0;

    % Uncertainties (optional)
    if size(dados,2) >= 6
        vemos.sigN = dados(:,5);
        vemos.sigE = dados(:,6);
    else
        vemos.sigN = NaN(size(vemos.vN));
        vemos.sigE = NaN(size(vemos.vE));
    end

    vemos.sigU = 0;

end
