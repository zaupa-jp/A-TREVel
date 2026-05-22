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