function S = readSIRGAScrd(info)
%__________________________________________________________________________
% Leitura das coordenadas SIRGAS (CRD) baseada no Reference Frame informado
%
% Entrada:
%   rf            - string: 'SIRGAS2022' ou 'SIRGAS2000'
%   station_name  - código de 4 letras da estação (ex: 'AACR')
%
% O nome do arquivo deve seguir o padrão:
%   <rf>_XYZ.CRD
%
% Ex:
%   rf = "SIRGAS2022";
%   readSIRGAScrd(rf, "ALGO");
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________


    % --------------------------------------------------------------
    % Construir nome do arquivo automaticamente
    % --------------------------------------------------------------
    rf = info.rf;
    station_name = info.st;
    arquivo = rf + "_XYZ.txt";
    
    if ~isfile(arquivo)
        error('Arquivo "%s" não encontrado.', arquivo);
    end

    % Abrir arquivo
    fid = fopen(arquivo, 'r');
    if fid < 0
        error('Não foi possível abrir o arquivo: %s', arquivo);
    end

    S = struct([]);
    i = 0;

    % --------------------------------------------------------------
    % Escolher parser conforme o RF
    % --------------------------------------------------------------

    rf = upper(string(rf));

    % ==============================================================
    % ======================= SIRGAS 2022 ==========================
    % ==============================================================
    if rf == "SIRGAS2022"

        padrao = ['^\s*(\d+)\s+' ...                % NUM
                  '([A-Z0-9]{4})\s+' ...            % NAME
                  '([0-9A-Z]{9})\s+' ...            % DOMES
                  '([\-\d\.]+)\s+([\d\.]+)\s+' ...  % X sigX
                  '([\-\d\.]+)\s+([\d\.]+)\s+' ...  % Y sigY
                  '([\-\d\.]+)\s+([\d\.]+)\s+' ...  % Z sigZ
                  '([A-Z])\s+(\d+)\s+' ...          % ID-SNX e SOL
                  '(\d{4}-\d{2}-\d{2})\s+' ...      % START
                  '(\d{4}-\d{2}-\d{2})$'];          % END

        while ~feof(fid)

            linha = strtrim(fgetl(fid));
            if isempty(linha), continue; end
            if isempty(regexp(linha,'^\d+','once')), continue; end

            tokens = regexp(linha, padrao, 'tokens');
            if isempty(tokens), continue; end
            t = tokens{1};

            name = t{2};
            if ~strcmpi(name, station_name)
                continue;
            end

            i = i + 1;

            S(i).name = name;
            S(i).X    = str2double(t{4});
            S(i).sigX = str2double(t{5});
            S(i).Y    = str2double(t{6});
            S(i).sigY = str2double(t{7});
            S(i).Z    = str2double(t{8});
            S(i).sigZ = str2double(t{9});

            S(i).start_date = datetime(t{12}, 'InputFormat','yyyy-MM-dd');
            S(i).end_date   = datetime(t{13}, 'InputFormat','yyyy-MM-dd');
        end

    % ==============================================================
    % ======================= SIRGAS 2000 ==========================
    % ==============================================================
    elseif rf == "SIRGAS2000"

        padrao1 = ['^\s*([A-Z0-9]{4})\s+[A-Z]{2}\s+' ...
                    '([\-\d\.]+)\s+([\-\d\.]+)\s+([\-\d\.]+)'];

        while ~feof(fid)

            linha = strtrim(fgetl(fid));
            if isempty(linha), continue; end

            tokens = regexp(linha, padrao1, 'tokens');
            if isempty(tokens), continue; end
            t = tokens{1};

            name = t{1};
            if ~strcmpi(name, station_name)
                continue;
            end

            % Próxima linha contém sigmas
            linha2 = strtrim(fgetl(fid));
            padrao2 = '([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)';
            sig = regexp(linha2, padrao2, 'tokens');
            sig = sig{1};

            i = i + 1;
            S(i).name = name;

            S(i).X    = str2double(t{2});
            S(i).Y    = str2double(t{3});
            S(i).Z    = str2double(t{4});

            S(i).sigX = str2double(sig{1});
            S(i).sigY = str2double(sig{2});
            S(i).sigZ = str2double(sig{3});

            S(i).start_date = NaT;
            S(i).end_date   = NaT;
        end

    else
        error('RF "%s" não suportado. Escolha SIRGAS2000 ou SIRGAS2022.', rf);
    end

    fclose(fid);

    if isempty(S)
        error('Estação %s não encontrada no arquivo.', station_name);
    end

        % ======================================================================
    % SELECIONAR APENAS UMA SOLUÇÃO (somente para SIRGAS2022)
    % ======================================================================
    if rf == "SIRGAS2022"

        nsol = length(S);

        % Converter datas para ano decimal
        year_start = zeros(nsol,1);
        year_end   = zeros(nsol,1);

        for k = 1:nsol
            year_start(k) = date2year(S(k).start_date);
            year_end(k)   = date2year(S(k).end_date);
        end

        t0 = info.t0s;

        % --------------------------------------------------------------
        % Caso 1) info.t0s é anterior a todas as datas do SIRGAS
        % --------------------------------------------------------------
        if t0 < min(year_start)
            idx = 1;

        % --------------------------------------------------------------
        % Caso 2) info.t0s cai dentro de um intervalo start–end
        % --------------------------------------------------------------
        elseif any(t0 >= year_start & t0 <= year_end)
            idx = find(t0 >= year_start & t0 <= year_end, 1, 'first');

        % --------------------------------------------------------------
        % Caso 3) info.t0s é posterior ao último intervalo
        % --------------------------------------------------------------
        else
            idx = nsol;
        end

        % Reduz para apenas uma solução
        S = S(idx);
    end


end
