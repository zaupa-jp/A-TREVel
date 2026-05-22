function [sigVx, sigVy, sigVz, CovV_ecef] = propSigV_NEU2ECEF(sigN, sigE, sigU, lat, lon, h, method)
%__________________________________________________________________________
% propSigV_NEU2ECEF - Propagates velocity uncertainties from local NEU to ECEF
%
% Inputs:
%   sigN, sigE, sigU : standard deviations of velocities in NEU (m/year)
%   lat, lon, h      : geodetic coordinates (deg, deg, m)
%   method (optional): "jacobian" (default) or "rotation"
%
% Outputs:
%   sigVx, sigVy, sigVz : standard deviations in ECEF (m/year)
%   CovV_ecef           : full covariance matrix in ECEF (m^2/year^2)
%
% Notes:
%   - Uncertainties are propagated through covariance:
%         Cov_ecef = A * Cov_neu * A'
%   - If NEU components are assumed uncorrelated:
%         Cov_neu = diag([sigN^2, sigE^2, sigU^2])
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    if nargin < 7 || isempty(method)
        method = "jacobian"; % recommended with your current neu2ecef()
    else
        method = string(method);
    end

    % Covariance in NEU (assuming independence)
    CovV_neu = diag([sigN^2, sigE^2, sigU^2]);

    % ------------------------------------------------------------
    % Build linear mapping A such that: [Vx;Vy;Vz] = A*[vN;vE;vU]
    % ------------------------------------------------------------
    switch lower(method)

        case "jacobian"
            % Use your own neu2ecef() as a black-box linear map
            % Columns of A are the outputs for unit basis vectors in NEU
            [Vx1, Vy1, Vz1] = neu2ecef(1, 0, 0, lat, lon, h); % effect of vN
            [Vx2, Vy2, Vz2] = neu2ecef(0, 1, 0, lat, lon, h); % effect of vE
            [Vx3, Vy3, Vz3] = neu2ecef(0, 0, 1, lat, lon, h); % effect of vU

            A = [Vx1 Vx2 Vx3;
                 Vy1 Vy2 Vy3;
                 Vz1 Vz2 Vz3];

        case "rotation"
            % Classic NEU->ECEF rotation matrix (pure rotation)
            phi = deg2rad(lat);
            lam = deg2rad(lon);

            A = [ -sin(phi)*cos(lam),  -sin(lam),  cos(phi)*cos(lam);
                  -sin(phi)*sin(lam),   cos(lam),  cos(phi)*sin(lam);
                   cos(phi),            0,         sin(phi) ];

        otherwise
            error('propSigV_NEU2ECEF:InvalidMethod', ...
                  'Invalid method. Use "jacobian" or "rotation".');
    end

    % ------------------------------------------------------------
    % Covariance propagation: Cov_ecef = A * Cov_neu * A'
    % ------------------------------------------------------------
    CovV_ecef = A * CovV_neu * A.';

    % Standard deviations in ECEF
    sig = sqrt(diag(CovV_ecef));
    sigVx = sig(1);
    sigVy = sig(2);
    sigVz = sig(3);
end
