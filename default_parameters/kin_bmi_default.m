function kin_params = kin_bmi_default(varargin)

params.online       = true;
params.save_data    = true;
params.mode         = 'direct';

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