function ITRF = readITRFparams(arquivo, info)
%__________________________________________________________________________
% Leitura dos parâmetros de transformação entre realizações ITRF
% conforme tabela oficial ITRF (Tx,Ty,Tz,D,Rx,Ry,Rz + rates)
%
% Formato de saída:
%   ITRF.Tx, Ty, Tz         (m)
%   ITRF.D                  (ppb)
%   ITRF.Rx, Ry, Rz         (mas)
%   ITRF.Txd ... Rzd        (rates)
%   ITRF.name               (ITRF de origem)
%   ITRF.epoch              (ITRF alvo)
%
% Funcionamento:
%   Seleciona automaticamente as linhas corretas para:
%       info.if  → info.op
%   ou, se for inverso, aplica sinal negativo.
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    ITRF = struct([]);

    % ======================================================================
    % REALIZAÇÃO DE ENTRADA (from)
    % ======================================================================
    if info.rf == "SIRGAS2022"
        info.if = "ITRF2014";
    elseif info.rf == "SIRGAS2000"
        info.if = "ITRF2000";
    else
        info.if = info.rf;
    end

    % ======================================================================
    % REALIZAÇÃO DE SAÍDA (to)
    % ======================================================================
    if info.of == "SIRGAS2022"
        info.op = "ITRF2014";
    elseif info.of == "SIRGAS2000"
        info.op = "ITRF2000";
    else
        info.op = info.of;
    end

    % Definir com nomes claros
    info.from = info.if;
    info.to   = info.op;

    % ======================================================================
    % Determinar sinal (ordem da transformação)
    % ======================================================================
    % Pegar ano numérico das realizações
    ep_from = str2double(regexp(info.from, '\d+', 'match', 'once'));
    ep_to   = str2double(regexp(info.to,   '\d+', 'match', 'once'));

    if ep_from < ep_to
        % Ex: queremos 2000 -> 2020, mas arquivo tem 2020->2000
        signal = -1;    
        info.search_from = info.from;
        info.search_to   = info.to;     
    else
        % Ex: queremos 2020 -> 2000, arquivo também tem 2020->2000
        signal = +1;    
        info.search_from = info.to;
        info.search_to   = info.from;
    end

    % Caso trivial: mesmas realizações
    if strcmp(info.if, info.op)
        ITRF(1).Tx  = 0;       ITRF(1).Ty  = 0; ITRF(1).Tz  = 0;
        ITRF(1).D   = 0;       
        ITRF(1).Rx  = 0;       ITRF(1).Ry  = 0; ITRF(1).Rz  = 0;
        ITRF(1).Txd = 0;       ITRF(1).Tyd = 0; ITRF(1).Tzd = 0;
        ITRF(1).Dd  = 0;       
        ITRF(1).Rxd = 0;       ITRF(1).Ryd = 0; ITRF(1).Rzd = 0;
        ITRF(1).name  = [];
        ITRF(1).epoch = [];
		ITRF(1).epochRef = epoch_ref_from_frame(info.rf);
        return;
    end

    % ======================================================================
    % Abrir arquivo
    % ======================================================================
    fid = fopen(arquivo,'r');
    if fid < 0
        error('Não foi possível abrir o arquivo %s', arquivo);
    end

    i = 0;

    % ======================================================================
    % LOOP PRINCIPAL: ler somente linhas corretas
    % ======================================================================
    while ~feof(fid)

        line = strtrim(fgetl(fid));
        if isempty(line), continue; end

        % Procurar linhas do tipo:
        %
        %   ITRFxxxx   Tx Ty ...   ITRFyyyy
        %
        if startsWith(line, info.search_from) && endsWith(line, info.search_to)

            i = i + 1;

            % -------------------------------------------------------------
            % Ler linha principal
            % -------------------------------------------------------------
            C = textscan(line, '%s %f %f %f %f %f %f %f %s');

            ITRF(i).name  = C{1}{1};
            ITRF(i).Tx    = signal*C{2}/1000;               % mm → m
            ITRF(i).Ty    = signal*C{3}/1000;
            ITRF(i).Tz    = signal*C{4}/1000;
            ITRF(i).D     = signal*C{5}/1000000000;         % ppb → escala adimensional
            ITRF(i).Rx    = signal*C{6}*pi*.001/(180*3600); % mas → rad
            ITRF(i).Ry    = signal*C{7}*pi*.001/(180*3600);
            ITRF(i).Rz    = signal*C{8}*pi*.001/(180*3600);
            % -----------------------------------------------------------------
            % O último token do seu arquivo atual é a REALIZAÇÃO de referência,
            % não o epoch numérico. Então:
            %   - refFrame = "ITRF2020", "ITRF2014", ...
            %   - epochRef = 2015.0, 2010.0, ... (via cases)
            % -----------------------------------------------------------------
            ITRF(i).refFrame = string(C{9}{1});
            ITRF(i).epochRef = epoch_ref_from_frame(ITRF(i).refFrame);

            % -------------------------------------------------------------
            % Ler linha de rates
            % -------------------------------------------------------------
            rate_line = strtrim(fgetl(fid));

            R = textscan(rate_line, '%s %f %f %f %f %f %f %f');

            ITRF(i).Txd = signal*R{2}/1000;
            ITRF(i).Tyd = signal*R{3}/1000;
            ITRF(i).Tzd = signal*R{4}/1000;
            ITRF(i).Dd  = signal*R{5}/1000000000;
            ITRF(i).Rxd = signal*R{6}*pi*.001/(180*3600);
            ITRF(i).Ryd = signal*R{7}*pi*.001/(180*3600);
            ITRF(i).Rzd = signal*R{8}*pi*.001/(180*3600);

        end

    end

    fclose(fid);

end
function epochRef = epoch_ref_from_frame(refFrame)
    refFrame = upper(string(refFrame));

    switch refFrame
        case "ITRF2020"
            epochRef = 2015.0;
        case "ITRF2014"
            epochRef = 2010.0;
        case "ITRF2008"
            epochRef = 2005.0;
        case "ITRF2005"
            epochRef = 2000.0;
        case "ITRF2000"
            epochRef = 1997.0;
        case "SIRGAS2000"
            epochRef = 2000.4;
        case "SIRGAS2022"
            epochRef = 2015.0;
        otherwise
            error("Epoch-of-parameters not defined for reference frame: %s", refFrame);
    end
end
