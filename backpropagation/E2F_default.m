function E2F = E2F_default

E2F.fillen      = 0.05;
E2F.binsize     = 0.05;
E2F.outnames    = ['x_pos';'y_pos'];
E2F.input_type  = 'EMG';

E2F.H = [...
    10      0;
    7.07    7.07;
    0       10;
    -7.07   7.07;
    -10     0;
    -7.07   -7.07;
    0       -10;
    7.07    -7.07];
    