% Default parameters for the analyze_tDCS_experiment function
%
%   function analyze_tDCS_exp_params = analyze_tDCS_exp_defaults( varargin )
%
%   'exp_folder'        : path to the folder that contains the data
%   'baseline_files'    : pre-tDCS files. If empty, it will assume all
%                           files were recorded without tDCS
%   'tDCS_files'        : tDCS files
%   'post_tDCS_files'   : post-tDCS files
%   'muscles'           : muscles to analyze and plot. If empty, it will be
%                           all
%   'resp_per_win'      : 
%


function analyze_tDCS_exp_params = analyze_tDCS_exp_defaults( varargin )

analyze_tDCS_exp_defaults = struct(...
    'exp_folder',           '', ...
    'baseline_files',       {}, ...
    'tDCS_files',           {}, ...
    'post_tDCS_files',      {}, ...
    'muscles',              {}, ...
    'resp_per_win',         4500 ...
);


% fill default options missing from input argument
if nargin
    analyze_tDCS_exp_params = varargin{1};
else
    analyze_tDCS_exp_params = [];
end

all_param_names             = fieldnames( analyze_tDCS_exp_defaults );
for i = 1:numel( all_param_names )
    if ~isfield( analyze_tDCS_exp_params, all_param_names(i) )
        analyze_tDCS_exp_params.( all_param_names{i} ) = analyze_tDCS_exp_params.( all_param_names{i} );
    end
end