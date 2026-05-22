function [semanaGPS, diaSemana, doy] = clc_week_number(dia, mes, ano)
%__________________________________________________________________________
%   FUNÇÃO PARA CALCULAR O DIA DA SEMANA
%   Input:
%   dia         -   Dia do processamento
%   mes			-   Mês do processamento
%   ano		    -   Ano do processamento
%
%   Output:
%   semanaGPS	-	Semana GPS
%   diaSemana	-	Dia da Semana GPS
%   doy     	-	Dia do ano (1-365/366)
%__________________________________________________________________________   
%
%   ZAUPA, J. P. V. 2025
%   FCT UNESP - Presidente Prudente, SP.
%   E-mail: jp.zaupa@unesp.br
%__________________________________________________________________________

    % Verifica se as entradas são do tipo double
    if ~isnumeric(dia) || ~isnumeric(mes) || ~isnumeric(ano)
        error('As entradas devem ser do tipo double.');
    end

    % Cria um vetor datetime a partir dos valores de entrada
    data = datetime(ano, mes, dia);

    % Data de referência do início da contagem GPS
    inicioGPS = datetime(1980, 1, 6);

    % Calcula a diferença entre a data fornecida e a data de início do GPS
    diasDesdeInicio = days(data - inicioGPS);

    % Calcula a semana GPS e o dia da semana (0 = domingo, 6 = sábado)
    semanaGPS = floor(diasDesdeInicio / 7);
    diaSemana = mod(diasDesdeInicio, 7);

    % Calcula o DOY (Day of Year)
    doy = day(data, 'dayofyear');
end
