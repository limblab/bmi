function params = bmi_params_steph(type)

params.online       = true;
params.save_data    = true;
params.output       = 'xpc';
params.mode         = 'emg_cascade';
params.save_dir     = 'E:\Data-lab1\12A1-Jango\CerebusData\LearnAdapt';


%params.pred_bounds  = [11 11];

switch type
    case 'emg_cascade'
        params.save_name = ['Jango_EMGBC_' datestr(now,'yyyymmdd') '_SN'];
        params.mode      = 'emg_cascade';
        params.hp_rc        = 0;
    otherwise
        params.save_name = ['Jango_KinBC_' datestr(now,'yyyymmdd') '_SN'];
        params.mode      = 'direct';
        params.hp_rc        = 60;
end