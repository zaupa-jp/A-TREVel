function [Ra, sRa, Va] = IERS_auto(Rr, Vr, info, unc)
%==========================================================================
% IERS_auto - Escolhe automaticamente entre transformação direta e corrente
%
% Usa IERS direta quando existe ligação direta no arquivo de parâmetros.
% Usa IERS_chain apenas quando não há ligação direta para o par solicitado.
%==========================================================================

    if nargin < 4
        unc = [];
    end

    doUnc = ~isempty(unc);
    doVel = nargout > 2;

    % Resolve aliases SIRGAS -> ITRF somente para verificar o par
    rf = resolve_sirgas_to_itrf(info.rf);
    of = resolve_sirgas_to_itrf(info.of);

    % Verifica se existe ligação direta no arquivo
    hasDirect = has_direct_itrf_link('itrfparameters.txt', rf, of);

    if hasDirect
        fprintf("\n>>> Direct IERS transformation available: %s -> %s\n", rf, of);

        param = readITRFparams('itrfparameters.txt', info);

        if doUnc
            [Ra, sRa] = IERS(Rr, Vr, param, info, unc);
        else
            Ra = IERS(Rr, Vr, param, info);
            sRa = [];
        end

        Va = [];

    else
        fprintf("\n>>> Direct transformation not available. Using IERS chain: %s -> %s\n", rf, of);

        if doUnc && doVel
            [Ra, sRa, Va] = IERS_chain(Rr, Vr, info, unc);
        elseif doUnc
            [Ra, sRa] = IERS_chain(Rr, Vr, info, unc);
            Va = [];
        elseif doVel
            [Ra, ~, Va] = IERS_chain(Rr, Vr, info);
            sRa = [];
        else
            Ra = IERS_chain(Rr, Vr, info);
            sRa = [];
            Va = [];
        end
    end
end
function tf = has_direct_itrf_link(filename, rf, of)
%==========================================================================
% Verifica se existe ligação direta entre dois referenciais ITRF.
%
% Como a tabela é do tipo:
%   SOLUTION ... EPOCH
%
% uma linha com:
%   ITRF2008 ... ITRF2014
%
% representa uma transformação direta entre ITRF2008 e ITRF2014.
%==========================================================================

    rf = string(rf);
    of = string(of);

    txt = fileread(filename);
    lines = splitlines(txt);

    tf = false;

    for i = 1:numel(lines)
        line = strtrim(lines{i});

        if startsWith(line, "ITRF")
            parts = split(line);

            if numel(parts) >= 9
                sol = string(parts{1});
                epc = string(parts{end});

                % Aceita ligação nos dois sentidos, desde que sua
                % readITRFparams consiga inverter os parâmetros quando necessário
                if (sol == rf && epc == of) || (sol == of && epc == rf)
                    tf = true;
                    return;
                end
            end
        end
    end
end

