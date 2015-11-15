%
% function GTO_stim( stim_ampl, stim_pw, stim_freq, nbr_pulses ) 
%
%   stim_ampl: in mA ( < 8 mA)
%   stim_pw: in ms
%   stim_freq: in Hz
%   nbr_pulses: (duration has to be < 1 s)
%   mode: 'bi' or 'mono' (-polar)

function GTO_stim( stim_ampl, stim_pw, stim_freq, nbr_pulses, mode ) 

sp              = stim_params_defaults();

sp.tl           = 1000/stim_freq*nbr_pulses;
sp.amp          = stim_ampl/4*ones(1,8);
sp.freq         = stim_freq;

switch mode
    case 'bi'
        sp.elect_list   = [2 4 6 8 5 7 9 11];
        sp.pol          = [1 1 1 1 0 0 0 0];
    case 'mono'
        sp.elect_list   = [2 4 6 8];
        sp.pol          = [1 1 1 1];
end        
sp.pw           = stim_pw;

ezstim(sp);