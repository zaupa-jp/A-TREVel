function trevel(info)
%__________________________________________________________________________
% TREVEL - Coordinate transformation between ITRF/SIRGAS realizations
%
% Input:
%    info.rf   → input realization   (e.g., "SIRGAS2022")
%    info.of   → output realization  (e.g., "SIRGAS2000")
%    info.st   → station code        (e.g., "FORT")
%    info.t0s  → initial epoch       (e.g., 2015.0)
%    info.tfs  → final epoch         (e.g., 2020.5)
%    info.nw   → network type        ("SIRGAS")
%
%__________________________________________________________________________
%
%   Copyright (c) 2025, João P V Zaupa
%__________________________________________________________________________

    unc = struct();
    %======================================================================
    % Read SIRGAS coordinates and velocities
    %======================================================================
    if info.nw == "SIRGAS"

        fprintf("==============================================\n");
        fprintf(" Coordinate transformation %s -> %s\n", info.rf, info.of);
        fprintf(" Station: %s\n", info.st);
        fprintf(" Initial epoch: %.1f\n", info.t0s);
        fprintf(" Final epoch:   %.1f\n", info.tfs);
        fprintf("==============================================\n\n");

        %---------------------------------------
        % Read station coordinates
        %---------------------------------------
        Rr = readSIRGAScrd(info);  % filters only the selected station
        fprintf(">>> Original coordinates at %.1f (%s)\n", info.t0s, info.rf);

        for i = 1:length(Rr)
            fprintf(" Solution %d:\n", i);
            fprintf("   X = %12.4f m\n", Rr(i).X);
            fprintf("   Y = %12.4f m\n", Rr(i).Y);
            fprintf("   Z = %12.4f m\n", Rr(i).Z);
            fprintf("   σX= %.4f m, σY= %.4f m, σZ= %.4f m\n\n", ...
                Rr(i).sigX, Rr(i).sigY, Rr(i).sigZ);
        end

        %---------------------------------------
        % Read station velocities
        %---------------------------------------
        Vr = readSIRGASvel('SIRGAS2022_vel.txt', info);

        fprintf(">>> Official station velocities (%s):\n", info.st);

        for i = 1:length(Vr)
            fprintf(" Solution %d:\n", i);
            fprintf("   Vx = %10.4f m/year\n", Vr(i).vx);
            fprintf("   Vy = %10.4f m/year\n", Vr(i).vy);
            fprintf("   Vz = %10.4f m/year\n", Vr(i).vz);
            fprintf("   σVx= %.4f, σVy= %.4f, σVz= %.4f (m/year)\n\n", ...
                Vr(i).sigvx, Vr(i).sigvy, Vr(i).sigvz);
        end

        %==================================================================
        % Apply ITRF/IERS transformation (deterministic)
        %==================================================================
        if isfield(info,'uncertainty') && info.uncertainty == 1
            unc = helmert_unc_table();
            [Ra, sRa] = IERS_auto(Rr, Vr, info, unc);
        else
            Ra = IERS_auto(Rr, Vr, info);
            sRa = [];
        end
        
        fprintf("\n>>> Transformed coordinates at %.1f (%s)\n", ...
            info.tfs, info.of);

        for i = 1:length(Ra)
            fprintf(" Solution %d:\n", i);
            fprintf("   X = %12.4f m\n", Ra(i).X);
            fprintf("   Y = %12.4f m\n", Ra(i).Y);
            fprintf("   Z = %12.4f m\n", Ra(i).Z);
        
            if ~isempty(sRa)
                fprintf("   σX= %.4f m, σY= %.4f m, σZ= %.4f m\n\n", ...
                    sRa(i).sigX, sRa(i).sigY, sRa(i).sigZ);
            else
                fprintf("\n");
            end
        end

    else
        % ============================================================
        %   USER-DEFINED COORDINATES
        % ============================================================
    
        fprintf("\n>>> Coordinates provided manually by the user\n");
    
        % Input coordinate type
        if info.ctp == "XYZ"
            % XYZ → store directly
            Rr.X = info.x;
            Rr.Y = info.y;
            Rr.Z = info.z;
    
            fprintf("   X = %.4f m\n", info.x);
            fprintf("   Y = %.4f m\n", info.y);
            fprintf("   Z = %.4f m\n", info.z);
    
            % ========================================================
            %   1) Convert XYZ → LLA (GRS80)
            % ========================================================
            fprintf("\n>>> Converting XYZ to LLA (GRS80)...\n");
    
            [a,b,e2,~] = refell_GT("GRS80");
    
            [lat0, lon0, h0] = xyz2ell3_GT(info.x, info.y, info.z, a, b, e2);
    
            fprintf("   Latitude  = %.8f°\n", lat0);
            fprintf("   Longitude = %.8f°\n", lon0);
            fprintf("   Height    = %.4f m\n", h0);
    
        else
            % LLA provided by the user
            lat0 = info.lat;
            lon0 = info.lon;
            h0   = info.alt;
    
            fprintf("   Latitude  = %.8f°\n", lat0);
            fprintf("   Longitude = %.8f°\n", lon0);
            fprintf("   Height    = %.4f m\n", h0);
    
            % Convert to XYZ for consistency
            [a,b,e2,~] = refell_GT("GRS80");
            [x,y,z] = ell2xyz_GT(lat0, lon0, h0, a, e2);
    
            Rr.X = x;
            Rr.Y = y;
            Rr.Z = z;
    
            fprintf("\n>>> Converted to XYZ:\n");
            fprintf("   X = %.4f m\n", x);
            fprintf("   Y = %.4f m\n", y);
            fprintf("   Z = %.4f m\n", z);
        end
    
        %--------------------------------------------------------------
        % Velocity model: VEMOS (any version, e.g., VEMOS2022, VEMOS2017)
        %--------------------------------------------------------------
        if startsWith(string(info.modelovel), "VEMOS", "IgnoreCase", true)
        
            fprintf("\n>>> Interpolating velocity from %s (lat/lon)...\n", string(info.modelovel));
        
            % Build filename from the selected model version
            vemosFile = sprintf("%s.txt", string(info.modelovel));
        
            % Read model and interpolate
            vemos = leVEMOS(vemosFile);
            vel   = interpolaVemos(vemos, lat0, lon0);
        
            fprintf("   vN = %.5f m/year\n", vel.vN);
            fprintf("   vE = %.5f m/year\n", vel.vE);
            fprintf("   vU = %.5f m/year\n", vel.vU);
        
            % ==============================================================    
            %   3) Convert velocity NEU → ECEF
            % ==============================================================    
            fprintf("\n>>> Converting NEU velocity to ECEF...\n");
        
            [vx, vy, vz] = neu2ecef(vel.vN, vel.vE, vel.vU, lat0, lon0, h0);
        
            fprintf("   VX = %.6f m/year\n", vx);
            fprintf("   VY = %.6f m/year\n", vy);
            fprintf("   VZ = %.6f m/year\n", vz);


            if isfield(info,'uncertainty') && info.uncertainty == 1
                Rr.sigX = info.sdx;
                Rr.sigY = info.sdy;
                Rr.sigZ = info.sdz;
                [svx, svy, svz, ~] = propSigV_NEU2ECEF(vel.sigN, vel.sigE, vel.sigU, lat0, lon0, h0, "jacobian");
                Vr.sigvx = svx;
                Vr.sigvy = svy;
                Vr.sigvz = svz;
            end
        
            Vr.vx = vx;
            Vr.vy = vy;
            Vr.vz = vz;
			

		elseif info.modelovel == "Insert"
            fprintf("\n>>> Velocities provided by the user...\n");
            
            vx = info.vxi;
            vy = info.vyi;
            vz = info.vzi;

            fprintf("   VX = %.6f m/year\n", vx);
            fprintf("   VY = %.6f m/year\n", vy);
            fprintf("   VZ = %.6f m/year\n", vz);
        
            Vr.vx = vx;
            Vr.vy = vy;
            Vr.vz = vz;
			
			if isfield(info,'uncertainty') && info.uncertainty == 1
                Rr.sigX =  info.sdx;
                Rr.sigY =  info.sdy;
                Rr.sigZ =  info.sdz;
                Vr.sigvx = info.svx;
                Vr.sigvy = info.svy;
                Vr.sigvz = info.svz;
            end

        else
            % ==============================================================    
            %   3) Euler pole-based velocity estimation
            % ==============================================================    
			fprintf("\n>>> Computing ECEF velocities from Euler rotation angles...\n");
            
            omx = info.omegax/1e6;
            omy = info.omegay/1e6;
            omz = info.omegaz/1e6;

            vx = -omz*Rr.Y + omy*Rr.Z;
            vy =  omz*Rr.X - omx*Rr.Z;
            vz = -omy*Rr.X + omx*Rr.Y;

            fprintf("   VX = %.6f m/year\n", vx);
            fprintf("   VY = %.6f m/year\n", vy);
            fprintf("   VZ = %.6f m/year\n", vz);
        
            Vr.vx = vx;
            Vr.vy = vy;
            Vr.vz = vz;
            
        end
    
        % ==============================================================    
        %   4) Apply IERS transformation
        % ==============================================================    
        fprintf("\n>>> Applying IERS transformation %s -> %s\n", info.rf, info.of);
    
        % Rr structure is compatible with SIRGAS format
        % Vr is consistent
        if isfield(info,'uncertainty') && info.uncertainty == 1
            unc = helmert_unc_table();
            [Ra, sRa] = IERS_auto(Rr, Vr, info, unc);
        else
            Ra = IERS_auto(Rr, Vr, info);
            sRa = [];
        end
    
        fprintf("\n>>> Final coordinates:\n");
        fprintf("   X = %.4f m\n", Ra.X);
        fprintf("   Y = %.4f m\n", Ra.Y);
        fprintf("   Z = %.4f m\n", Ra.Z);

        if ~isempty(sRa)
                fprintf("   σX= %.4f m, σY= %.4f m, σZ= %.4f m\n\n", ...
                sRa.sigX, sRa.sigY, sRa.sigZ);
        else
               fprintf("\n");
        end

    end

end
