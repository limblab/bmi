function E2F = E2F_deRugy_PD(varargin)

E2F.fillen      = 0.05;
E2F.binsize     = 0.05;
E2F.emglabels   = {'ECRb','ECRl','FCR','FCU','ECU'};
E2F.outnames    = {'x_pos','y_pos'};
E2F.input_type  = 'EMG';
E2F.filename    = 'E2F_deRugy_PD';
E2F.decoder_type= 'E2F';

if nargin factor=varargin{1};else factor=15;end

E2F.H = factor*[...
    -cosd(52.3)  sind(52.3);
    -cosd(77.2)  sind(77.2);
    -cosd(165.5) sind(165.5);
    -cosd(233.1) sind(233.1);
    -cosd(304.5) sind(304.5)];
        