function y = date2year(t)
%__________________________________________________________________________
% DATE2YEAR  Converte um datetime para ano sexagesimal (ano decimal).
%
%   y = DATE2YEAR(t) converte a data t (do tipo datetime) para o formato
%   de ano sexagesimal (ano decimal), utilizando apenas dia, mês e ano.
%   A precisão é diária — horas, minutos e segundos não são considerados.
%
%   Exemplo:
%       t = datetime(2024, 3, 15);
%       y = date2year(t);
%
%   Resultado:
%       y = 2024.2022   (aprox.)
%
%   Fórmula utilizada:
%       y = ano + (DOY - 1) / (nDiasAno)
%
%   onde:
%       - DOY é o dia do ano (1–365/366)
%       - nDiasAno = 365 ou 366 (caso bissexto)
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    % Garantir que t é datetime
    if ~isa(t, "datetime")
        error('A entrada deve ser do tipo datetime.');
    end

    % Dia do ano
    doy = day(t, 'dayofyear');

    % Verificar ano bissexto
    isLeap = eomday(year(t),2) == 29;
    daysInYear = 365 + isLeap;

    % Ano sexagesimal
    y = year(t) + (doy - 1) / daysInYear;
end
