function test_ws_commError_latency(params)
% --- test_ws_commError_latency ---
%
% INPUTS:
% Params               Parameter structure with optional fields [default]
%   - serial_string        COM port [COM3]
%   - dbg_lvl              debug outputs from wireless_stim from 0-4 [1]
%   - save_folder          folder to save delay times [current directory]
%   - log_file             log the parameters, storage file name, and ME
%                               struct (if failed out) [.\commErrorLog.mat]
%   - test_time            minutes to test each set of stim params [1440]
%   - email                email to notify on test changes [KevinHP's]
%   - zb_ch_page           list of ch_pages to test [0,2,5,16,17,18,19]
%   - blocking             test true/false/both [both]
%   - comm_timout_ms       timeout lengths to test [-1,15,100,1000]
%   - batt                 battery number or 'power supply' ['power supply']


% fill in parameters as needed
operatingParams = struct(...
    'serial_string','COM3',...
    'dbg_lvl',3,...
    'save_folder','.',...
    'log_file','.\comErrorLog.csv',...
    'test_time','1440',...
    'email','kevinbodkin2017@u.northwestern.edu',...
    'zb_ch_page',[0,2,5,16,17,18,19],...
    'blocking','both',...
    'comm_timeout_ms',[-1,15,100,1000],...
    'batt','power supply');

flds = fieldnames(params); % list of fields from input parameter structure
for ii = 1:numel(flds) 
    operatingParams.(flds(ii)) = params.(flds(ii)); % overwrite default values as needed
end
params = operatingParams; clear operatingParams;


% open log files, make new directories as necessary
prev_dir = cd; % save so we can return to this at the end
if exist(params.save_folder,'dir')
    cd(params.save_folder)
else
    mkdir(params.save_folder)
    cd(params.save_folder)
end

% create file for timestamps
fsFileName = ['Comm_Timestamp_', datestr(now,'yyyymmddTHHMMSS'), '.dat']
tsFID = fopen(fsFileName,'w');


% make a meshgrid of the desired input options to wireless stim
switch params.blocking
    case 'true'
        blocking = 1;
    case 'false'
        blocking = 0;
    case 'both'
        blocking = [0 1];
end

[blocking,zb_ch_page,comm_timeout_ms] = meshgrid(blocking,params.zb_ch_page,params.comm_timeout_ms); % repeat so we have one iteration of every possibility
blocking = blocking(:); % reshape from matrix to vector
zb_ch_page = zb_ch_page(:);
comm_timeout_ms = comm_timeout_ms(:);

for ii = 1:length(blocking)
    stimParams = struct(...
        'blocking',blocking(ii),...
        'dbg_lvl',params.dbg_lvl,...
        'comm_timeout_ms',comm_timeout_ms(ii),...
        'zb_ch_page',zb_ch_page(ii),...
        'serial_string',params.serial_string);
    
    
        instrreset % flush the serial ports -- take care of any previous errors (hopefully)
        
        try
            





