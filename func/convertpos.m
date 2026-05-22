function convertpos(info)
%__________________________________________________________________________
% CONVERTPOS  Converte coordenadas entre os sistemas geodésico (lat, lon, h)
% e cartesiano geocêntrico (X, Y, Z).
%
%   Esta função identifica automaticamente o tipo de coordenada de entrada
%   especificado em info.ctp:
%       - Se info.ctp == "XYZ", assume-se que as coordenadas fornecidas são
%         geocêntricas (X, Y, Z). A função então converte para latitude,
%         longitude e altura elipsoidal (lat, lon, h).
%
%       - Caso contrário, assume-se que as coordenadas fornecidas são
%         geodésicas (lat, lon, h). A função então realiza a conversão para
%         coordenadas geocêntricas (x, y, z).
%
%   A função utiliza parâmetros do elipsoide obtidos por meio de:
%       [a, ~, e2, ~] = refell_GT(info.elp);
%
%   Funções auxiliares utilizadas:
%       - refell_GT   : Obtém parâmetros do elipsoide de referência.
%       - xyz2ell_GT  : Conversão de coordenadas cartesianas (X,Y,Z)
%                       para geodésicas (lat, lon, h).
%       - ell2xyz_GT  : Conversão de coordenadas geodésicas (lat, lon, h)
%                       para cartesianas (X,Y,Z).
%
%   As funções refell_GT, xyz2ell_GT e ell2xyz_GT são de domínio de:
%
%       % Copyright (c) 2011, Michael R. Craymer
%       % All rights reserved.
%       % Email: mike@craymer.com
%
%   Entrada:
%       info : estrutura contendo os campos:
%              - ctp  : tipo de coordenada ('XYZ' ou outro)
%              - elp  : nome do elipsoide
%              - x, y, z  : coordenadas geocêntricas (se ctp == "XYZ")
%              - lat, lon, h : coordenadas geodésicas (caso contrário)
%
%   Saídas:
%       A função realiza a conversão correspondente e gera as coordenadas:
%
%       • Se info.ctp == "XYZ":
%           lat, lon, h   (em graus e metros)
%
%       • Caso contrário:
%           x, y, z       (em metros)
%
%       Observação: O usuário pode adaptar o código para retornar essas
%       variáveis explicitamente ou atualizar a própria estrutura info.
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________


[a,b,e2,~] = refell_GT(info.elp);

if info.ctp == "XYZ"
    x = info.x;
    y = info.y;
    z = info.z;

    [lat, lon, h] = xyz2ell3_GT(x,y,z,a,b,e2);

    % ---- Conversão para DMS ----
    [lat_d, lat_m, lat_s] = dec2dms(lat);
    [lon_d, lon_m, lon_s] = dec2dms(lon);

    fprintf("\n--------------------------------------------------\n");
    fprintf("\n    Conversion XYZ → Geodetic\n");
    fprintf("\nLatitude  : %.10f°\n", lat);
    fprintf("\nLongitude : %.10f°\n", lon);
    fprintf("\nEllipsoidal height : %.4f m\n", h);

    fprintf("\nLatitude  (DMS): %d° %d' %.5f\'' \n", lat_d, lat_m, lat_s);
    fprintf("\nLongitude (DMS): %d° %d' %.5f\'' \n", lon_d, lon_m, lon_s);
    fprintf("\n--------------------------------------------------\n\n");


else
    lat = info.lat;
    lon = info.lon;
    h = info.alt;

    [x, y, z] = ell2xyz_GT(lat,lon,h,a,e2);

    fprintf("\n--------------------------------------------------\n");
    fprintf("\n    Conversion Geodetic → XYZ \n\n");
    fprintf("X: %.4f m\n", x);
    fprintf("\nY: %.4f m\n", y);
    fprintf("\nZ: %.4f m\n", z);
    fprintf("\n--------------------------------------------------\n\n");
    
end

