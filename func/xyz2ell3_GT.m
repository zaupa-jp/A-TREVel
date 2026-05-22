function [lat,lon,h]=xyz2ell3_GT(X,Y,Z,a,b,e2)
% xyz2ell3_GT  Converts cartesian coordinates to ellipsoidal.
%   Uses direct algorithm in B.R. Bowring, "The accuracy of
%   geodetic latitude and height equations", Survey
%   Review, v28 #218, October 1985, pp.202-206.  Vectorized.
%   See also xyz2ell_GT, xyz2ell2_GT.
% Version: 2011-02-19
% Useage:  [lat,lon,h]=xyz2ell3_GT(X,Y,Z,a,b,e2)
%          [lat,lon,h]=xyz2ell3_GT(X,Y,Z)
% Input:   X \
%          Y  > vectors of cartesian coordinates in CT system (m)
%          Z /
%          a   - ref. ellipsoid major semi-axis (m); default GRS80
%          b   - ref. ellipsoid minor semi-axis (m); default GRS80
%          e2  - ref. ellipsoid eccentricity squared; default GRS80
% Output:  lat - vector of ellipsoidal latitudes (°)
%          lon - vector of ellipsoidal longitudes (°)
%          h   - vector of ellipsoidal heights (m)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com
% 
% Modifications made by Zaupa, 2025
% jp.zaupa@unesp.br

 % Verificação dos argumentos
    if nargin ~= 3 && nargin ~= 6
        error('xyz2ell3_GT: incorrect number of input arguments');
    end

    % Carregar elipsoide padrão GRS80
    if nargin == 3
        [a, b, e2] = refell_GT('GRS80');
    end

    % Longitudade
    lon = atan2(Y, X);

    % Parâmetros
    p = hypot(X, Y);
    e1_sq = (a^2 - b^2) / b^2;

    % Bowring improved formula
    theta = atan2(Z * a, p * b);

    sin_theta = sin(theta);
    cos_theta = cos(theta);

    lat = atan2(Z + e1_sq * b * sin_theta^3, ...
                p - e2 * a * cos_theta^3);

    % Raio de curvatura na normal
    v = a ./ sqrt(1 - e2 * sin(lat).^2);

    % Altitude correta
    h = p ./ cos(lat) - v;

    lat = rad2deg(lat); % Passar para ° sexagesimais

    lon = rad2deg(lon); % Passar para ° sexagesimais
end