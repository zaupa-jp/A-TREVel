function [d, m, s] = dec2dms(decimal_deg)
    % Mantém o sinal
    sign_val = sign(decimal_deg);
    decimal_deg = abs(decimal_deg);

    d = floor(decimal_deg);
    m_float = (decimal_deg - d) * 60;
    m = floor(m_float);
    s = (m_float - m) * 60;

    % Reaplica o sinal ao grau
    d = d * sign_val;
end
