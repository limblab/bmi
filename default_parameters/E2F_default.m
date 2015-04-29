function E2F = E2F_default(varargin)

E2F.fillen      = 0.05;
E2F.binsize     = 0.05;
E2F.outnames    = ['x_pos';'y_pos'];
E2F.input_type  = 'EMG';
E2F.filename    = 'E2F_default';
E2F.decoder_type= 'E2F';

if nargin
    radius = varargin{1};
else
    radius = 15;
end

E2F.H = radius*[...
    cosd(0)     sind(0);
    cosd(45)    sind(45);
    cosd(90)    sind(90);
    cosd(135)   sind(135);
    cosd(180)   sind(180);
    cosd(225)   sind(225);
    cosd(270)   sind(270);
    cosd(315)   sind(315)];
    