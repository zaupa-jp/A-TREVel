function S = readSIRGASconCRD(arquivo, station_name)
%__________________________________________________________________________
% Leitor de arquivos semanais SIRGAS-CON no formato:
%
% NUM  NAME  DOMES       X(M)          Y(M)          Z(M)       FLAG
%
% Exemplo:
%   1  AACR 40612M001  644009.12283 -6251064.21748 1093781.04451  A
%
% Entrada:
%   arquivo       -> caminho completo do arquivo .crd ou .txt
%   station_name  -> ex: "PPTE"
%
% Saída:
%   S(k).name, domes, X, Y, Z, flag
%
% Observações:
%   Arquivos semanais não possuem sigmas nem datas.
%__________________________________________________________________________

    fid = fopen(arquivo, 'r');
    if fid < 0
        error("Não foi possível abrir: %s", arquivo);
    end

    S = struct([]);   % evitar warnings
    k = 0;            % índice controlador
    found = false;

    % Padrão real SIRGAS-CON
    padrao = ['^\s*(\d+)\s+' ...              % NUM
              '([A-Z0-9]{4})\s+' ...          % NAME
              '([0-9A-Z]{9})\s+' ...          % DOMES
              '([\-\d\.]+)\s+' ...            % X
              '([\-\d\.]+)\s+' ...            % Y
              '([\-\d\.]+)\s+' ...            % Z
              '([A-Z])\s*$'];                 % FLAG

    while ~feof(fid)

        linha = strtrim(fgetl(fid));
        if isempty(linha)
            continue;
        end

        tok = regexp(linha, padrao, 'tokens');

        % Linha não corresponde ao formato → ignorar
        if isempty(tok)
            continue;
        end

        t = tok{1};
        name = string(t{2});

        % Apenas a estação desejada
        if ~strcmpi(name, station_name)
            continue;
        end

        found = true;
        k = k + 1; % sempre indexar

        % Preencher corretamente a struct com índice
        S(k).name  = name;
        S(k).domes = string(t{3});
        S(k).X     = str2double(t{4});
        S(k).Y     = str2double(t{5});
        S(k).Z     = str2double(t{6});
        S(k).flag  = string(t{7});

        break; % encontrou → não precisa continuar lendo
    end

    fclose(fid);

    if ~found
        error("Estação %s não encontrada no arquivo %s", station_name, arquivo);
    end
end
