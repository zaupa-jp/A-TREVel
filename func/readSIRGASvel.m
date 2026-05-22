function S = readSIRGASvel(arquivo, info)
%__________________________________________________________________________
% Leitura do arquivo SIRGAS2022_XYZ.VEL (velocidades geocêntricas)
%
% Seleciona automaticamente a solução multi-anual adequada
% conforme a época info.t0s.
%
% Entrada:
%   arquivo       -> nome do arquivo (ex: 'SIRGAS2022_vel.txt')
%   info.st       -> nome da estação (4 letras)
%   info.t0s      -> época inicial em ano decimal
%
% Saída:
%   S             -> estrutura única contendo vx,vy,vz e sigmas
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    station_name = info.st;

    fid = fopen(arquivo,'r');
    if fid < 0
        error('Não foi possível abrir o arquivo: %s', arquivo);
    end
    
    S = struct([]);
    i = 0;
    
    while ~feof(fid)
    
        linha = strtrim(fgetl(fid));
        if isempty(linha), continue; end
    
        % deve começar com número
        if isempty(regexp(linha,'^\d+','once')), continue; end
    
        % Expressão regular completa (inclui DOMES)
        padrao = ['^\s*(\d+)\s+' ...               % NUM
                  '([A-Z0-9]{4})\s+' ...           % NAME
                  '([0-9A-Z]{9})\s+' ...           % DOMES
                  '([\-\d\.]+)\s+([\d\.]+)\s+' ... % VX sigVX
                  '([\-\d\.]+)\s+([\d\.]+)\s+' ... % VY sigVY
                  '([\-\d\.]+)\s+([\d\.]+)\s+' ... % VZ sigVZ
                  '([A-Z])\s+(\d+)\s+' ...         % ID-SNX e SOL
                  '(\d{4}-\d{2}-\d{2})\s+' ...     % START
                  '(\d{4}-\d{2}-\d{2})$'];         % END
    
        tokens = regexp(linha,padrao,'tokens');
        if isempty(tokens), continue; end
        t = tokens{1};
    
        % Filtrar estação
        name = t{2};
        if ~strcmpi(name, station_name)
            continue;
        end
    
        % Armazenar
        i = i + 1;
    
        S(i).num      = str2double(t{1});
        S(i).name     = name;
        S(i).domes    = t{3};
    
        S(i).vx       = str2double(t{4});
        S(i).sigvx    = str2double(t{5});
        S(i).vy       = str2double(t{6});
        S(i).sigvy    = str2double(t{7});
        S(i).vz       = str2double(t{8});
        S(i).sigvz    = str2double(t{9});
    
        S(i).id_snx   = t{10};
        S(i).solution = str2double(t{11});
    
        S(i).start_date = datetime(t{12}, 'InputFormat','yyyy-MM-dd');
        S(i).end_date   = datetime(t{13}, 'InputFormat','yyyy-MM-dd');
    end
    
    fclose(fid);
    
    if isempty(S)
        error('Estação %s não encontrada no arquivo.', station_name);
    end

    % ======================================================================
    % Selecionar solução temporal única
    % ======================================================================
    nsol = length(S);
    t0 = info.t0s;

    % Converter datas para ano decimal
    year_start = zeros(nsol,1);
    year_end   = zeros(nsol,1);

    for k = 1:nsol
        year_start(k) = date2year(S(k).start_date);
        year_end(k)   = date2year(S(k).end_date);
    end

    % Caso 1 — antes de todas as soluções
    if t0 < min(year_start)
        idx = 1;

    % Caso 2 — dentro do intervalo de uma solução
    elseif any(t0 >= year_start & t0 <= year_end)
        idx = find(t0 >= year_start & t0 <= year_end, 1, 'first');

    % Caso 3 — depois de todas as soluções
    else
        idx = nsol;
    end

    % Reduz para apenas uma solução
    S = S(idx);
end
