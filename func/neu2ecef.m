function [Vx, Vy, Vz] = neu2ecef(vN, vE, vU, lat, lon, h)
%__________________________________________________________________________
%   Converte velocidades locais para velocidades ECEF
%
%   Método geodésico correto baseado em:
%   - Derivadas parciais da conversão geodésica
%   - Curvaturas meridiana e do primeiro vertical
%   - Formulação de Hofmann-Wellenhof (2008), Monico (2008)
%
%   Inputs:
%       lat  - latitude  (graus)
%       lon  - longitude (graus)
%       h    - altitude elipsoidal (m)
%       vN   - velocidade direção Norte (m/ano)
%       vE   - velocidade direção Leste (m/ano)
%       vU   - velocidade vertical (m/ano)
%
%   Output:
%       Vx, Vy, Vz - velocidades em ECEF (m/ano)
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    %---------------------------------------------------------------
    % 1. Converter graus → radianos
    %---------------------------------------------------------------
    phi = deg2rad(lat);
    lam = deg2rad(lon);

    %---------------------------------------------------------------
    % 2. Parâmetros do elipsoide GRS80 (mesmo do SIRGAS)
    %---------------------------------------------------------------
    a  = 6378137.0;                 % semi-eixo maior
    f  = 1/298.257222101;           % achatamento
    e2 = 2*f - f^2;                 % excentricidade ao quadrado

    %---------------------------------------------------------------
    % 3. Raio de curvatura da meridiana (M)
    %---------------------------------------------------------------
    M = a*(1 - e2) / (1 - e2*sin(phi).^2)^(3/2);

    %---------------------------------------------------------------
    % 4. Raio de curvatura do primeiro vertical (N)
    %---------------------------------------------------------------
    N = a / sqrt(1 - e2*sin(phi).^2);

    %---------------------------------------------------------------
    % 5. Converter velocidades N/E para taxas angulares
    %---------------------------------------------------------------
    % vN = M * d(phi)/dt
    dphi = vN / M;

    % vE = (N + h)*cos(phi)*d(lambda)/dt
    dlam = vE / ((N + h)*cos(phi));

    % velocidade vertical é direta
    dh = vU;

    %---------------------------------------------------------------
    % 6. Derivadas parciais da conversão geodésica
    %---------------------------------------------------------------

    dN_dphi = (a*e2*sin(phi)*cos(phi)) / (1 - e2*sin(phi).^2)^(3/2);
    % Posição ECEF (necessária para derivadas)
    % ---- X ----
    dXdphi =  dN_dphi*cos(phi)*cos(lam) ...
            - (N+h)*sin(phi)*cos(lam);

    dXdlam = -(N+h)*cos(phi)*sin(lam);
    dXdh   =  cos(phi)*cos(lam);

    % ---- Y ----
    dYdphi =  dN_dphi*cos(phi)*sin(lam) ...
            - (N+h)*sin(phi)*sin(lam);

    dYdlam =  (N+h)*cos(phi)*cos(lam);
    dYdh   =  cos(phi)*sin(lam);

    % ---- Z ----
    dZdphi = (dN_dphi*(1-e2))*sin(phi) ...
            + (N*(1-e2)+h)*cos(phi);

    dZdlam = 0;
    dZdh   = sin(phi);

    %---------------------------------------------------------------
    % 7. Velocidades ECEF via fórmula geodésica
    %---------------------------------------------------------------
    Vx = dXdphi*dphi + dXdlam*dlam + dXdh*dh;
    Vy = dYdphi*dphi + dYdlam*dlam + dYdh*dh;
    Vz = dZdphi*dphi + dZdlam*dlam + dZdh *dh;

end