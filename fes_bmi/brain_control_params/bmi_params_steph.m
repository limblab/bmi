function params = bmi_params_steph(type)

params.online       = true;
params.save_data    = true;
params.output       = 'xpc';
params.mode         = 'emg_cascade';
params.save_dir     = 'E:\Data-lab1\12A2-Kevin\LearnAdapt';


% params.pred_bounds  = [11 11];

switch type
    case 'emg_cascade'
        params.save_name = ['Kevin_EMGBC_' datestr(now,'yyyymmdd') '_SN'];
        params.mode      = 'emg_cascade';
        params.hp_rc        = 0;
    otherwise
        params.save_name = ['Kevin_KinBC_' datestr(now,'yyyymmdd') '_SN'];
        params.mode      = 'direct';
        params.hp_rc        = 60;
end