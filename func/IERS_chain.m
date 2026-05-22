function [Ra, sRa, Va] = IERS_chain(Rr, Vr, info, unc)
%==========================================================================
% IERS_chain - Transformação ITRF/SIRGAS em CADEIA (coords) usando modelo IERS
%
% Coordenadas:
%   - Propaga r(t0)->r(tf) no frame de entrada usando velocidade
%   - Aplica cadeia ITRF passo-a-passo no epoch tf
%
% Velocidades (opcional, se nargout>2):
%   - Propaga pela cadeia com v_out = Td + Ad*r + A*v
%
% Incerteza (opcional, se nargout>1 e 'unc' fornecido):
%   - Propaga covariância pela MESMA cadeia (consistente)
%
% Inputs:
%   Rr(i).X,Y,Z e (opcional) sigX,sigY,sigZ
%   Vr(i).vx,vy,vz e (opcional) sigvx,sigvy,sigvz
%   info.rf, info.of, info.t0s, info.tfs
%   unc: struct com incertezas por passo (sig e sigd) em SI
%
% Outputs:
%   Ra(i).X,Y,Z
%   sRa(i).sigX,sigY,sigZ (se solicitado)
%   Va(i).vx,vy,vz (se solicitado)
%==========================================================================

    Ra = struct([]);
    if nargout > 1, sRa = struct([]); else, sRa = []; end
    if nargout > 2, Va = struct([]); else, Va = []; end

    dt_pos = info.tfs - info.t0s;

    % Resolve aliases SIRGAS -> ITRF para montar a cadeia
    ifrf = resolve_sirgas_to_itrf(info.rf);
    itof = resolve_sirgas_to_itrf(info.of);

    chain = itrf_chain(ifrf, itof);  % ex: 2000->2005->2008->2014->2020

    doUnc = (nargout > 1) && (nargin >= 4) && ~isempty(unc);
    doVel = (nargout > 2);

    for i = 1:numel(Rr)

        % Entrada
        r0 = [Rr(i).X; Rr(i).Y; Rr(i).Z];
        v0 = [Vr(i).vx; Vr(i).vy; Vr(i).vz];

        % 1) Propaga para tf NO frame de entrada
        r_cur = r0 + v0*dt_pos;
        v_cur = v0;

        % 2) Se tiver incerteza, inicializa cov no tf (assumindo Cov(r,v)=0 e diagonal)
        if doUnc
            req = {'sigX','sigY','sigZ'};
            reqv = {'sigvx','sigvy','sigvz'};
            for f = req
                if ~isfield(Rr(i),f{1}), error("Falta Rr(%d).%s", i, f{1}); end
            end
            for f = reqv
                if ~isfield(Vr(i),f{1}), error("Falta Vr(%d).%s", i, f{1}); end
            end

            Crr = diag([Rr(i).sigX^2,  Rr(i).sigY^2,  Rr(i).sigZ^2]);
            Cvv = diag([Vr(i).sigvx^2, Vr(i).sigvy^2, Vr(i).sigvz^2]);
            Ccur = Crr + (dt_pos^2)*Cvv;
        end

        % 3) Cadeia determinística (coords) e opcional (vel) e opcional (cov)
        for k = 1:(numel(chain)-1)

            rf_k = chain(k);
            of_k = chain(k+1);

            info_step = info;
            info_step.rf = char(rf_k);
            info_step.of = char(of_k);

            % Lê parâmetros determinísticos do passo (já no sentido rf->of)
            param_k = readITRFparams('itrfparameters.txt', info_step);
			
			dt_par = info.tfs - param_k.epochRef;
            % Monta A(t), T(t) no epoch tf e também derivadas (para vel)
            [A, T, Ad, Td] = build_AT_AndDot(param_k, dt_par);

            % --- coords do passo
            r_next = T + A*r_cur;

            % --- vel do passo (se solicitado)
            if doVel
                v_next = Td + Ad*r_cur + A*v_cur;
            end

            % --- cov do passo (se solicitado)
            if doUnc
                stepKey = build_step_key(rf_k, of_k);
                if ~isfield(unc, stepKey)
                    error("Tabela 'unc' não contém o passo: %s", stepKey);
                end

                sig_p  = unc.(stepKey).sig(:);   % [Tx Ty Tz D Rx Ry Rz]
                sig_pd = unc.(stepKey).sigd(:);  % incertezas das taxas

                % Cp no epoch tf (assumindo não correlacionado)
                dt_par_unc = info.tfs - unc.(stepKey).ep;
				Cp = diag(sig_p.^2) + (dt_par_unc^2)*diag(sig_pd.^2);

                Jp = jacobian_params(r_cur);  % linearização no r_cur (antes do passo)
                Ccur = A*Ccur*A.' + Jp*Cp*Jp.';
            end

            % Atualiza estado para o próximo passo
            r_cur = r_next;
            if doVel, v_cur = v_next; end
        end

        % Saídas finais
        Ra(i).X = r_cur(1); Ra(i).Y = r_cur(2); Ra(i).Z = r_cur(3);

        if doVel
            Va(i).vx = v_cur(1); Va(i).vy = v_cur(2); Va(i).vz = v_cur(3);
        end

        if doUnc
            sRa(i).sigX = sqrt(Ccur(1,1));
            sRa(i).sigY = sqrt(Ccur(2,2));
            sRa(i).sigZ = sqrt(Ccur(3,3));
        end
    end
end

function itrf = resolve_sirgas_to_itrf(fr)
    fr = string(fr);
    if fr == "SIRGAS2022"
        itrf = "ITRF2014";
    elseif fr == "SIRGAS2000"
        itrf = "ITRF2000";
    else
        itrf = fr;
    end
end

function chain = itrf_chain(rf, of)
    order = ["ITRF97","ITRF2000","ITRF2005","ITRF2008","ITRF2014","ITRF2020"];
    i0 = find(order==string(rf), 1);
    i1 = find(order==string(of), 1);
    if isempty(i0) || isempty(i1)
        error("ITRF chain: frame(s) não suportados: %s -> %s", rf, of);
    end
    if i0 <= i1
        chain = order(i0:i1);
    else
        chain = order(i0:-1:i1);
    end
end

function [A, T, Ad, Td] = build_AT_AndDot(param, dt)
    % Parâmetros no epoch tf: p(t) = p0 + pd*dt
    Tx = param.Tx + param.Txd*dt;
    Ty = param.Ty + param.Tyd*dt;
    Tz = param.Tz + param.Tzd*dt;

    D  = param.D  + param.Dd*dt;

    Rx = param.Rx + param.Rxd*dt;
    Ry = param.Ry + param.Ryd*dt;
    Rz = param.Rz + param.Rzd*dt;

    T = [Tx; Ty; Tz];

    Rmat = [  0   -Rz   Ry;
             Rz    0  -Rx;
            -Ry   Rx   0 ];

    A = (1 + D)*eye(3) + Rmat;

    % Derivadas no tempo (constantes, assumindo taxas constantes):
    Td = [param.Txd; param.Tyd; param.Tzd];

    Rdot = [  0         -param.Rzd   param.Ryd;
              param.Rzd  0          -param.Rxd;
             -param.Ryd  param.Rxd   0 ];

    Ad = param.Dd*eye(3) + Rdot;
end

function Jp = jacobian_params(r)
    x=r(1); y=r(2); z=r(3);
    Jp = [ ...
        1 0 0  x   0   z  -y;
        0 1 0  y  -z   0   x;
        0 0 1  z   y  -x   0];
end

function key = build_step_key(rf, of)
    key = char(sprintf("%s_to_%s", rf, of));
    key = strrep(key,"-","_");
    key = strrep(key," ","_");
end
