function [Ra, sRa] = IERS(Rr, Vr, param, info, unc)
%==========================================================================
% IERS - ITRF/SIRGAS coordinate transformation using IERS linearized model
%
% Deterministic coordinates:
%   - Computed using ONE direct transformation (rf -> of),
%     i.e., using the parameters read by readITRFparams(..., info).
%
% Key epochs:
%   - dt_pos = info.tfs - info.t0s        (site motion with velocity)
%   - dt_par = info.tfs - param.epochRef (parameter epoch update)
%
%==========================================================================

    Ra = struct([]);
    if nargout > 1
        sRa = struct([]);
    else
        sRa = [];
    end

    doUnc = (nargout > 1) && (nargin >= 5) && ~isempty(unc);

    %------------------------------------------------------
    % Resolve SIRGAS aliases to ITRF (for uncertainty chain)
    %------------------------------------------------------
    if string(info.rf) == "SIRGAS2022"
        ifrf = "ITRF2014";
    elseif string(info.rf) == "SIRGAS2000"
        ifrf = "ITRF2000";
    else
        ifrf = string(info.rf);
    end

    if string(info.of) == "SIRGAS2022"
        itof = "ITRF2014";
    elseif string(info.of) == "SIRGAS2000"
        itof = "ITRF2000";
    else
        itof = string(info.of);
    end

    %------------------------------------------------------
    % Time deltas
    %------------------------------------------------------
    dt_pos = info.tfs - info.t0s;            % for r(t) = r0 + v*dt_pos
    dt_par = info.tfs - param.epochRef;     % for parameters: p(t) = p0 + pd*dt_par

    %------------------------------------------------------
    % 1) Deterministic transformation matrix (DIRECT rf -> of)
    %------------------------------------------------------
    [A_dir, T_dir] = build_AT(param, dt_par);

    %------------------------------------------------------
    % 2) Build consecutive chain ONLY for uncertainty propagation
    %------------------------------------------------------
    if doUnc
        chain = itrf_chain(ifrf, itof); % e.g. 2000->2005->2008->2014->2020
    end

    %------------------------------------------------------
    % Loop over stations/solutions
    %------------------------------------------------------
    for i = 1:length(Rr)

        % input position and velocity (input frame at t0s)
        r0 = [Rr(i).X; Rr(i).Y; Rr(i).Z];
        v  = [Vr(i).vx; Vr(i).vy; Vr(i).vz];

        % time propagation to tfs (still in input frame)
        r_dt = r0 + v*dt_pos;

        %==============================
        % A) Coordinates (DIRECT)
        %==============================
        r_out = T_dir + A_dir*r_dt;

        Ra(i).X = r_out(1);
        Ra(i).Y = r_out(2);
        Ra(i).Z = r_out(3);

        %==============================
        % B) Uncertainty (CHAIN)
        %==============================
        if doUnc

            % -- require input sigmas
            if ~isfield(Rr(i),'sigX') || ~isfield(Rr(i),'sigY') || ~isfield(Rr(i),'sigZ') || ...
               ~isfield(Vr(i),'sigvx') || ~isfield(Vr(i),'sigvy') || ~isfield(Vr(i),'sigvz')
                error("Uncertainty propagation requires Rr.sigX/sigY/sigZ and Vr.sigvx/sigvy/sigvz.");
            end

            % input covariance at t0 (assume diagonal)
            Crr = diag([Rr(i).sigX^2,  Rr(i).sigY^2,  Rr(i).sigZ^2]);
            Cvv = diag([Vr(i).sigvx^2, Vr(i).sigvy^2, Vr(i).sigvz^2]);

            % covariance of time-propagated position (assume Cov(r,v)=0)
            Ccur = Crr + (dt_pos^2)*Cvv;

            % linearization point (use r_dt at tfs)
            r_lin = r_dt;

            for k = 1:(length(chain)-1)

                rf_k = chain(k);
                of_k = chain(k+1);

                stepKey = build_step_key(rf_k, of_k);
                if ~isfield(unc, stepKey)
                    error("Uncertainty table does not contain step: %s", stepKey);
                end

                % Get sigma of parameters and rates for this step
                sig_p  = unc.(stepKey).sig(:);   % [Tx Ty Tz D Rx Ry Rz]
                sig_pd = unc.(stepKey).sigd(:);  % rates uncertainties
                epoch_p = unc.(stepKey).ep;

                % Build deterministic parameters per step (needed for A_k)
                info_step = info;
                info_step.rf = char(rf_k);
                info_step.of = char(of_k);
                param_k = readITRFparams('itrfparameters.txt', info_step);

                % Parameter time delta for THIS STEP (relative to its epochRef)
                dt_par_k = info.tfs - epoch_p;

                % Cp at epoch tfs (uncorrelated assumption)
                Cp = diag(sig_p.^2) + (dt_par_k^2)*diag(sig_pd.^2);

                % Build A for THIS STEP (covariance propagation)
                [A_k, ~] = build_AT(param_k, dt_par_k);

                % Propagate covariance through this step
                Jp = jacobian_params(r_lin);
                Ccur = A_k*Ccur*A_k.' + Jp*Cp*Jp.';

                % (optional) you could update r_lin deterministically step-by-step,
                % but you requested not to update actual coordinates in chain.
            end

            sRa(i).sigX = sqrt(Ccur(1,1));
            sRa(i).sigY = sqrt(Ccur(2,2));
            sRa(i).sigZ = sqrt(Ccur(3,3));
        end
    end
end

%==========================================================================
% Helper: consecutive chain for uncertainty propagation only
%==========================================================================
function chain = itrf_chain(rf, of)
    order = ["ITRF97","ITRF2000","ITRF2005","ITRF2008","ITRF2014","ITRF2020"];

    i0 = find(order==string(rf), 1);
    i1 = find(order==string(of), 1);

    if isempty(i0) || isempty(i1)
        error("ITRF chain: unsupported frame(s): %s -> %s", rf, of);
    end

    if i0 <= i1
        chain = order(i0:i1);
    else
        chain = order(i0:-1:i1);
    end
end

%==========================================================================
% Helper: build A and T for IERS model (small rotations)
%==========================================================================
function [A, T] = build_AT(param, dt_par)

    Tx = param.Tx + param.Txd*dt_par;
    Ty = param.Ty + param.Tyd*dt_par;
    Tz = param.Tz + param.Tzd*dt_par;

    D  = param.D  + param.Dd*dt_par;

    Rx = param.Rx + param.Rxd*dt_par;
    Ry = param.Ry + param.Ryd*dt_par;
    Rz = param.Rz + param.Rzd*dt_par;

    T = [Tx; Ty; Tz];

    Rmat = [  0   -Rz   Ry;
             Rz    0  -Rx;
            -Ry   Rx   0 ];

    A = (1 + D)*eye(3) + Rmat;
end

%==========================================================================
% Helper: Jacobian wrt Helmert parameters [Tx Ty Tz D Rx Ry Rz]
%==========================================================================
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
