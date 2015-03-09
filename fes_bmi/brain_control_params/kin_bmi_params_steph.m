function kin_params = kin_bmi_params_steph(varargin)

params.online       = true;
params.save_data    = true;
params.mode         = 'direct';
params.save_dir     = 'E:\Data-lab1\12A2-Kevin\LearnAdapt';
params.save_name    = 'Kevin_VelBC_03092015_SN';
params.hp_rc        = 60;
params.pred_bounds  = [11.5 11.5];

if nargin
    kin_params = varargin{1};
else
    kin_params = [];
end

all_param_names = fieldnames(params);
for i=1:numel(all_param_names)
    if ~isfield(kin_params,all_param_names(i))
        kin_params.(all_param_names{i}) = params.(all_param_names{i});
    end
end