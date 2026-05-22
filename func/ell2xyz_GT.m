function [x, y, z] = ell2xyz_GT(lat, lon, h, a, e2)
% ell2xyz_GT  Converts ellipsoidal coordinates to cartesian (ECEF).
%   Vectorized.
%
% Input:
%   lat - ellipsoidal latitude (°)
%   lon - ellipsoidal longitude (°)
%   h   - ellipsoidal height (m)
%   a   - semi-major axis (default GRS80)
%   e2  - eccentricity squared (default GRS80)
%
% Output:
%   x, y, z - ECEF coordinates (m)
% 
% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com
% 
% Modifications made by Zaupa, 2025
% jp.zaupa@unesp.br

 % Número de argumentos
    if nargin ~= 3 && nargin ~= 5
        error('ell2xyz_GT: wrong number of arguments (need 3 or 5)');
    end

    % Carregar GRS80 se não vier a,e2
    if nargin == 3
        [a, ~, e2, ~] = refell_GT('GRS80');
    end

    % Raio de curvatura na normal
    v = a ./ sqrt(1 - e2 .* sind(lat).^2);

    % Conversão
    x = (v + h) .* cosd(lat) .* cosd(lon);
    y = (v + h) .* cosd(lat) .* sind(lon);
    z = (v .* (1 - e2) + h) .* sind(lat);

end