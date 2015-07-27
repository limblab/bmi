%
% This script configures the sta_trig_avg for our TDCS experiment
%

% Who is in the lab?
monkey                  ='Jango';


% Set up the stimulation parameters

stap                    = stim_trig_avg_defaults;

stap.nbr_stims_ch       = 15000;
stap.stim_ampl          = 0.054;

switch monkey
    case 'Kevin'
        stap.monkey     = 'Kevin';
        stap.data_dir   = 'E:\Data-lab1\12A2-Kevin\CerebusData\TDCS';
        stap.stim_elec  = 17;
    case 'Jango'
        stap.monkey     = 'Jango';
        stap.data_dir   = 'E:\Data-lab1\12A1-Jango\CerebusData\TDCS';
        stap.stim_elec  = 17;
    otherwise
        error('wrong monkey!');
end
        


%% -----------------------------------------------------------------------
% Call the ICMS function

% stim_trig_avg(stap);


