function vel = interpolaVemos(vemos, lat0, lon0)
%__________________________________________________________________________
% interpolaVemos - Interpola velocidades do VEMOS2022 via IDW
%
% Entrada:
%   vemos = estrutura retornada por leVEMOS()
%   lat0, lon0 = coordenadas do ponto de interesse (graus)
%
% Saída:
%   vel.vN  = velocidade N-S interpolada (m/ano)
%   vel.vE  = velocidade W-E interpolada (m/ano)
%   vel.sigN = incerteza interpolada (m/ano)
%   vel.sigE = incerteza interpolada (m/ano)
%
% Método:
%   IDW (Inverse Distance Weighting), mesmo método do TREVel
%   descrito em Prol et al., 2014 (Eq. 12).
%
%__________________________________________________________________________   
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    % Extração dos vetores
    lat = vemos.lat;
    lon = vemos.lon;
    vN  = vemos.vN;
    vE  = vemos.vE;
    vU  = vemos.vU;
    sN  = vemos.sigN;
    sE  = vemos.sigE;
    sU  = vemos.sigU;

    % Converter graus → radianos
    lat0_rad = deg2rad(lat0);
    lon0_rad = deg2rad(lon0);
    lat_rad  = deg2rad(lat);
    lon_rad  = deg2rad(lon);

    % -----------------------------------------------------------
    % 1) Calcular distância geodésica simples (aprox. esférica)
    % -----------------------------------------------------------

    % Fórmula da distância esférica (Lei dos Cossenos Esféricos)
    R = 6371000; % raio médio da Terra (m) - serve para ordenar vizinhos

    dist = acos( sin(lat0_rad).*sin(lat_rad) + ...
                 cos(lat0_rad).*cos(lat_rad).*cos(lon0_rad - lon_rad) );
    dist = R * dist;  % distância em metros

    % -----------------------------------------------------------
    % 2) Selecionar os 4 vizinhos mais próximos
    % -----------------------------------------------------------
    [~, idx] = sort(dist);
    viz = idx(1:4);

    d = dist(viz);
    
    % -----------------------------------------------------------
    % 3) Tratar caso especial: ponto coincide exatamente com um nó do grid
    % -----------------------------------------------------------
    if any(d == 0)
        % Pega o índice do ponto exato
        idx0 = viz(d == 0);
    
        % Retorna diretamente as velocidades desse ponto
        vel.vN   =  vN(idx0);
        vel.vE   =  vE(idx0);
        vel.vU   =  vU;
        vel.sigN =  sN(idx0);
        vel.sigE =  sE(idx0);
        vel.sigU =  sU;
    
        return;   % encerra a função
    end
    
    % -----------------------------------------------------------
    % 4) Interpolação IDW tradicional
    % -----------------------------------------------------------
    w = 1 ./ d;
    
    vel.vN      = sum(w .* vN(viz))  / sum(w);
    vel.vE      = sum(w .* vE(viz))  / sum(w);
    vel.sigN    = sum(w .* sN(viz)) / sum(w);
    vel.sigE    = sum(w .* sE(viz)) / sum(w);
    vel.vU      = vU;
    vel.sigU    = sU;

end
