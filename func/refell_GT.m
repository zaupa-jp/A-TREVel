function [a,b,e2,finv]=refell_GT(type)
% refell_GT  Computes reference ellipsoid parameters.
%   Reference: Department of Defence World Geodetic
%   System 1984, DMA TR 8350.2, 1987.
%   TOPEX Reference:
%   <http://topex-www.jpl.nasa.gov/aviso/text/general/news/hdbk311.htm#CH3.3>
%
% Version: 1 Jun 04
%
% Modifications:
%   - Added PZ90 ellipsoid (GLONASS reference).
%   - Added CGCS2000 ellipsoid (China Geodetic Coordinate System 2000).
%   - Added GTRF option (Galileo Terrestrial Reference Frame, using GRS80 ellipsoid).
%
%   All modifications implemented by:
%       João P. V. Zaupa, 2026.
%
% Useage:  [a,b,e2,finv]=refell_GT(type)
%
% Input:   type - reference ellipsoid type (char)
%                 CLK66     = Clarke 1866
%                 GRS67     = Geodetic Reference System 1967
%                 GRS80     = Geodetic Reference System 1980
%                 WGS72     = World Geodetic System 1972
%                 WGS84     = World Geodetic System 1984
%                 ATS77     = Quasi-earth centred ellipsoid for ATS77
%                 NAD27     = North American Datum 1927 (=CLK66)
%                 NAD83     = North American Datum 1927 (=GRS80)
%                 INTER     = International
%                 KRASS     = Krassovsky (USSR)
%                 MAIRY     = Modified Airy (Ireland 1965/1975)
%                 TOPEX     = TOPEX/POSEIDON ellipsoid
%                 PZ90      = PZ-90 (GLONASS)
%                 CGCS2000  = China Geodetic Coordinate System 2000
%                 GTRF      = Galileo Terrestrial Reference Frame (uses GRS80 ellipsoid)
%
% Output:  a    - major semi-axis (m)
%          b    - minor semi-axis (m)
%          e2   - eccentricity squared
%          finv - inverse of flattening
%
% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com
%
% Modifications Copyright (c) 2026, João P. V. Zaupa
% Email: jp.zaupa@unesp.br
%__________________________________________________________________________


type = upper(char(type));

switch type

    case {'CLK66','NAD27'}
        a = 6378206.4;
        finv = 294.9786982;

    case 'GRS67'
        a = 6378160.0;
        finv = 298.247167427;

    case {'GRS80','NAD83'}
        a = 6378137.0;
        finv = 298.257222101;

    case 'WGS72'
        a = 6378135.0;
        finv = 298.26;

    case 'WGS84'
        a = 6378137.0;
        finv = 298.257223563;

    case 'ATS77'
        a = 6378135.0;
        finv = 298.257;

    case 'KRASS'
        a = 6378245.0;
        finv = 298.3;

    case 'INTER'
        a = 6378388.0;
        finv = 297.0;

    case 'MAIRY'
        a = 6377340.189;
        finv = 299.3249646;

    case 'TOPEX'
        a = 6378136.3;
        finv = 298.257;

    case 'PZ90'
        % PZ-90 (GLONASS)
        a = 6378136.0;
        finv = 298.25784;

    case 'CGCS2000'
        % CGCS2000
        a = 6378137.0;
        finv = 298.257222101;

    case 'GTRF'
        % GTRF uses the GRS80 ellipsoid
        a = 6378137.0;
        finv = 298.257222101;

    otherwise
        error('refell_GT: unknown ellipsoid type: %s', type);

end

f  = 1/finv;
b  = a*(1 - f);
e2 = 1 - (1 - f)^2;

end