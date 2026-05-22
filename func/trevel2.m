function [Ra, Vr, Rr, sRa, txt] = trevel2(info)
%__________________________________________________________________________
% TREVEL2 - Coordinate transformation between ITRF/SIRGAS realizations
%           with returned outputs for batch processing and saving.
%
% Output:
%    Ra   -> final transformed coordinates
%    Vr   -> velocity used in the transformation
%    Rr   -> input coordinates used by the routine
%    sRa  -> propagated coordinate uncertainties (if available)
%    txt  -> formatted text summary (optional log)
%
% Input fields follow the same pattern as trevel(info)
%__________________________________________________________________________

    txt = "";
    sRa = [];
    Vr  = struct();
    Rr  = struct();
    Ra  = struct();

    %======================================================================
    % Read transformation parameters
    %======================================================================
    param = readITRFparams('itrfparameters.txt', info);
    unc = struct();

    %======================================================================
    % SIRGAS mode
    %======================================================================
    if string(info.nw) == "SIRGAS"

        txt = txt + sprintf("==============================================\n");
        txt = txt + sprintf(" Coordinate transformation %s -> %s\n", info.rf, info.of);
        txt = txt + sprintf(" Station: %s\n", info.st);
        txt = txt + sprintf(" Initial epoch: %.1f\n", info.t0s);
        txt = txt + sprintf(" Final epoch:   %.1f\n", info.tfs);
        txt = txt + sprintf("==============================================\n\n");

        % Read station coordinates
        Rr = readSIRGAScrd(info);

        txt = txt + sprintf(">>> Original coordinates at %.1f (%s)\n", info.t0s, info.rf);
        for i = 1:length(Rr)
            txt = txt + sprintf(" Solution %d:\n", i);
            txt = txt + sprintf("   X = %12.4f m\n", Rr(i).X);
            txt = txt + sprintf("   Y = %12.4f m\n", Rr(i).Y);
            txt = txt + sprintf("   Z = %12.4f m\n", Rr(i).Z);

            if isfield(Rr(i),'sigX')
                txt = txt + sprintf("   σX= %.4f m, σY= %.4f m, σZ= %.4f m\n\n", ...
                    Rr(i).sigX, Rr(i).sigY, Rr(i).sigZ);
            else
                txt = txt + sprintf("\n");
            end
        end

        % Read station velocities
        Vr = readSIRGASvel('SIRGAS2022_vel.txt', info);

        txt = txt + sprintf(">>> Official station velocities (%s):\n", info.st);
        for i = 1:length(Vr)
            txt = txt + sprintf(" Solution %d:\n", i);
            txt = txt + sprintf("   Vx = %10.4f m/year\n", Vr(i).vx);
            txt = txt + sprintf("   Vy = %10.4f m/year\n", Vr(i).vy);
            txt = txt + sprintf("   Vz = %10.4f m/year\n", Vr(i).vz);

            if isfield(Vr(i),'sigvx')
                txt = txt + sprintf("   σVx= %.4f, σVy= %.4f, σVz= %.4f (m/year)\n\n", ...
                    Vr(i).sigvx, Vr(i).sigvy, Vr(i).sigvz);
            else
                txt = txt + sprintf("\n");
            end
        end

        % Apply transformation
        if isfield(info,'uncertainty') && info.uncertainty == 1
            unc = helmert_unc_table();
            [Ra, sRa] = IERS(Rr, Vr, param, info, unc);
        else
            Ra = IERS(Rr, Vr, param, info);
            sRa = [];
        end

        txt = txt + sprintf("\n>>> Transformed coordinates at %.1f (%s)\n", info.tfs, info.of);

        for i = 1:length(Ra)
            txt = txt + sprintf(" Solution %d:\n", i);
            txt = txt + sprintf("   X = %12.4f m\n", Ra(i).X);
            txt = txt + sprintf("   Y = %12.4f m\n", Ra(i).Y);
            txt = txt + sprintf("   Z = %12.4f m\n", Ra(i).Z);

            if ~isempty(sRa)
                txt = txt + sprintf("   σX= %.4f m, σY= %.4f m, σZ= %.4f m\n\n", ...
                    sRa(i).sigX, sRa(i).sigY, sRa(i).sigZ);
            else
                txt = txt + sprintf("\n");
            end
        end

    %======================================================================
    % Manual mode
    %======================================================================
    else
        txt = txt + sprintf("\n>>> Coordinates provided manually by the user\n");

        %--------------------------------------------------------------
        % Input coordinates
        %--------------------------------------------------------------
        if string(info.ctp) == "XYZ"
            Rr.X = info.x;
            Rr.Y = info.y;
            Rr.Z = info.z;

            txt = txt + sprintf("   X = %.4f m\n", info.x);
            txt = txt + sprintf("   Y = %.4f m\n", info.y);
            txt = txt + sprintf("   Z = %.4f m\n", info.z);

            txt = txt + sprintf("\n>>> Converting XYZ to LLA (GRS80)...\n");

            [a,b,e2,~] = refell_GT("GRS80");
            [lat0, lon0, h0] = xyz2ell3_GT(info.x, info.y, info.z, a, b, e2);

            txt = txt + sprintf("   Latitude  = %.8f°\n", lat0);
            txt = txt + sprintf("   Longitude = %.8f°\n", lon0);
            txt = txt + sprintf("   Height    = %.4f m\n", h0);

        else
            lat0 = info.lat;
            lon0 = info.lon;
            h0   = info.alt;

            txt = txt + sprintf("   Latitude  = %.8f°\n", lat0);
            txt = txt + sprintf("   Longitude = %.8f°\n", lon0);
            txt = txt + sprintf("   Height    = %.4f m\n", h0);

            [a,b,e2,~] = refell_GT("GRS80");
            [x,y,z] = ell2xyz_GT(lat0, lon0, h0, a, e2);

            Rr.X = x;
            Rr.Y = y;
            Rr.Z = z;

            txt = txt + sprintf("\n>>> Converted to XYZ:\n");
            txt = txt + sprintf("   X = %.4f m\n", x);
            txt = txt + sprintf("   Y = %.4f m\n", y);
            txt = txt + sprintf("   Z = %.4f m\n", z);
        end

        %--------------------------------------------------------------
        % Velocity model
        %--------------------------------------------------------------
        if startsWith(string(info.modelovel), "VEMOS", "IgnoreCase", true)

            txt = txt + sprintf("\n>>> Interpolating velocity from %s (lat/lon)...\n", string(info.modelovel));

            vemosFile = sprintf("%s.txt", string(info.modelovel));
            vemos = leVEMOS(vemosFile);
            vel   = interpolaVemos(vemos, lat0, lon0);

            txt = txt + sprintf("   vN = %.5f m/year\n", vel.vN);
            txt = txt + sprintf("   vE = %.5f m/year\n", vel.vE);
            txt = txt + sprintf("   vU = %.5f m/year\n", vel.vU);

            txt = txt + sprintf("\n>>> Converting NEU velocity to ECEF...\n");

            [vx, vy, vz] = neu2ecef(vel.vN, vel.vE, vel.vU, lat0, lon0, h0);

            txt = txt + sprintf("   VX = %.6f m/year\n", vx);
            txt = txt + sprintf("   VY = %.6f m/year\n", vy);
            txt = txt + sprintf("   VZ = %.6f m/year\n", vz);

            Vr.vx = vx;
            Vr.vy = vy;
            Vr.vz = vz;

            if isfield(info,'uncertainty') && info.uncertainty == 1
                Rr.sigX = info.sdx;
                Rr.sigY = info.sdy;
                Rr.sigZ = info.sdz;

                [svx, svy, svz, ~] = propSigV_NEU2ECEF( ...
                    vel.sigN, vel.sigE, vel.sigU, lat0, lon0, h0, "jacobian");

                Vr.sigvx = svx;
                Vr.sigvy = svy;
                Vr.sigvz = svz;
            end

        elseif string(info.modelovel) == "Insert"

            txt = txt + sprintf("\n>>> Velocities provided by the user...\n");

            Vr.vx = info.vxi;
            Vr.vy = info.vyi;
            Vr.vz = info.vzi;

            txt = txt + sprintf("   VX = %.6f m/year\n", Vr.vx);
            txt = txt + sprintf("   VY = %.6f m/year\n", Vr.vy);
            txt = txt + sprintf("   VZ = %.6f m/year\n", Vr.vz);

            if isfield(info,'uncertainty') && info.uncertainty == 1
                Rr.sigX = info.sdx;
                Rr.sigY = info.sdy;
                Rr.sigZ = info.sdz;
                Vr.sigvx = info.svx;
                Vr.sigvy = info.svy;
                Vr.sigvz = info.svz;
            end

        else
            txt = txt + sprintf("\n>>> Computing ECEF velocities from Euler rotation angles...\n");

            omx = info.omegax/1e6;
            omy = info.omegay/1e6;
            omz = info.omegaz/1e6;

            Vr.vx = -omz*Rr.Y + omy*Rr.Z;
            Vr.vy =  omz*Rr.X - omx*Rr.Z;
            Vr.vz = -omy*Rr.X + omx*Rr.Y;

            txt = txt + sprintf("   VX = %.6f m/year\n", Vr.vx);
            txt = txt + sprintf("   VY = %.6f m/year\n", Vr.vy);
            txt = txt + sprintf("   VZ = %.6f m/year\n", Vr.vz);
        end

        %--------------------------------------------------------------
        % Apply transformation
        %--------------------------------------------------------------
        txt = txt + sprintf("\n>>> Applying IERS transformation %s -> %s\n", info.rf, info.of);

        if isfield(info,'uncertainty') && info.uncertainty == 1
            unc = helmert_unc_table();
            [Ra, sRa] = IERS(Rr, Vr, param, info, unc);
        else
            Ra = IERS(Rr, Vr, param, info);
            sRa = [];
        end

        txt = txt + sprintf("\n>>> Final coordinates:\n");
        txt = txt + sprintf("   X = %.4f m\n", Ra.X);
        txt = txt + sprintf("   Y = %.4f m\n", Ra.Y);
        txt = txt + sprintf("   Z = %.4f m\n", Ra.Z);

        if ~isempty(sRa)
            txt = txt + sprintf("   σX= %.4f m, σY= %.4f m, σZ= %.4f m\n\n", ...
                sRa.sigX, sRa.sigY, sRa.sigZ);
        else
            txt = txt + sprintf("\n");
        end
    end

    % opcional: também imprimir na Command Window
    fprintf('%s', txt);
end

