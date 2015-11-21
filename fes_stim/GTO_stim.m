%
% function GTO_stim( stim_ampl, stim_pw, stim_freq, nbr_pulses, mode, sync_out ) 
%
%   stim_ampl: in mA ( < 8 mA)
%   stim_pw: in ms
%   stim_freq: in Hz
%   nbr_pulses: (duration has to be < 1 s)
%   mode: 'bi' or 'mono' (-polar)
%   sync_out: optional. if true, it will send out a single sync stimulus
%       through channel 32

function GTO_stim( stim_ampl, stim_pw, stim_freq, nbr_pulses, mode, varargin ) 

sp                      = stim_params_defaults();

sp.tl                   = 1000/stim_freq*nbr_pulses;
sp.freq                 = stim_freq;

switch mode
    case 'bi'
        sp.elect_list   = [5 7 9 11 2 4 6 8];
        sp.pol          = [1 1 1 1 0 0 0 0];
    case 'mono'
        sp.elect_list   = [5 7 9 11];
        sp.pol          = [1 1 1 1];
end        
sp.pw                   = stim_pw;
sp.amp                  = round(stim_ampl/4) ...
                            * ones(1,numel(sp.elect_list));


% If sync_out is set, send out sync signal (single pulse, 2.2 mA) through
% channel 32 
if nargin == 6
    sync_out            = varargin{1};
    if sync_out
        sp.tl           = [sp.tl * ones(1,numel(sp.elect_list)), ...
                                1000/sp.freq];
        sp.amp          = [sp.amp, 2.2];
        sp.elect_list   = [sp.elect_list, 32];
        sp.pol          = [sp.pol, 1];
    end
end

ezstim(sp);