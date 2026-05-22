function unc = helmert_unc_table()
% Returns Helmert parameter uncertainties per ITRF step (SI units).
% sig  : [Tx Ty Tz D Rx Ry Rz] at epoch (m, -, rad)
% sigd : rates uncertainty (m/y, 1/y, rad/y)

    as2rad = pi/(180*3600);

    % helper: convert [mm mm mm ppb 0.001" 0.001" 0.001"] -> SI
    toSI = @(u) [u(1:3)*1e-3, u(4)*1e-9, u(5:7)*1e-3*as2rad];

    unc = struct();

    % ==========================================================
    % Forward transformations
    % ==========================================================
    unc.ITRF97_to_ITRF2000.sig    = toSI([0.3 0.3 0.3 0.05 0.012 0.012 0.014]);
    unc.ITRF97_to_ITRF2000.sigd   = toSI([0.3 0.3 0.3 0.05 0.012 0.012 0.014]);
    unc.ITRF97_to_ITRF2000.ep     = 1997;

    unc.ITRF2000_to_ITRF2005.sig  = toSI([0.3 0.3 0.3 0.05 0.012 0.012 0.012]);
    unc.ITRF2000_to_ITRF2005.sigd = toSI([0.3 0.3 0.3 0.05 0.012 0.012 0.012]);
    unc.ITRF2000_to_ITRF2005.ep   = 2000;

    unc.ITRF2005_to_ITRF2008.sig  = toSI([0.2 0.2 0.2 0.03 0.008 0.008 0.008]);
    unc.ITRF2005_to_ITRF2008.sigd = toSI([0.2 0.2 0.2 0.03 0.008 0.008 0.008]);
    unc.ITRF2005_to_ITRF2008.ep   = 2005;

    unc.ITRF2008_to_ITRF2014.sig  = toSI([0.2 0.1 0.1 0.02 0.006 0.006 0.006]);
    unc.ITRF2008_to_ITRF2014.sigd = toSI([0.2 0.1 0.1 0.02 0.006 0.006 0.006]);
    unc.ITRF2008_to_ITRF2014.ep   = 2010;

    unc.ITRF2014_to_ITRF2020.sig  = toSI([0.2 0.2 0.2 0.03 0.007 0.006 0.007]);
    unc.ITRF2014_to_ITRF2020.sigd = toSI([0.2 0.2 0.2 0.03 0.007 0.006 0.007]);
    unc.ITRF2014_to_ITRF2020.ep   = 2015;

    % ==========================================================
    % Inverse transformations (same uncertainties!)
    % ==========================================================
    unc.ITRF2005_to_ITRF2000 = unc.ITRF2000_to_ITRF2005;
    unc.ITRF2008_to_ITRF2005 = unc.ITRF2005_to_ITRF2008;
    unc.ITRF2014_to_ITRF2008 = unc.ITRF2008_to_ITRF2014;
    unc.ITRF2020_to_ITRF2014 = unc.ITRF2014_to_ITRF2020;

end
