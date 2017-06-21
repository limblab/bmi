function PeriodicRecording(BaseFN,varargin)
% --- PeriodicRecording(BaseFN,...) ---
%   Sets up recordings for longs periods of time, starts recording into new
%   file every X minutes (default 15). Optional inputs should be put in as
%   name/value pairs. Hit "OK" to stop recording
%
% Required Inputs:
%   BaseFN      Base file name for recording, will be appended with 001 etc
%
%
% Optional Inputs [Default]:
%   RecPer      Length of each file, in minutes [15 minutes)
%   NumFile     Number of files before stopping [default unlimited]
%
%
%
% Example:
%   I want to record file "C:\Fake\AintReal\20170608_Pablo_InCage_xxx.nev"
%   for 2 hours in 10 minute segments.
%
%   PeriodicRecording('C:\Fake\AintReal\20170608_Pablo_InCage',...
%       'RecPer',10,'NumFile',12);
%
%
% KLB 2017


% Defaults
RecPer = 15; % 15 min
NumFile = 0; % unlimited

for v = 1:2:nargin
    switch varargin{v}
        case 'RecPer'
            RecPer = varargin{v+1};
        case 'NumFile'
            NumFile = varargin{v+1};
    end
end

I = 1; % start the counter for the FN increment
UserData = struct('I',I,'FileName',BaseFN);

% set up the timer
t = timer(...
        'Period',           RecPer*60,...
        'ExecutionMode',    'fixedrate',...
        'TimerFcn',         @PRTimerFcn,...
        'StartFcn',         @PRStartFcn,...
        'StopFcn',          @PRStopFcn,...
        'UserData',         UserData,...
        'StartDelay',        RecPer*60);

% If there's a limit to the number of times we want to run this
if NumFile = 1
    % a little kludgy, but here you go...
    timer.StartDelay = 0;
    timer.StartFcn = {@(~,~)disp('That''s a lot of work for only one file...')};
    timer.TimerFcn = @PRStartFcn;
    timer.TasksToExecute = 1;
elseif NumFile > 1
    timer.TasksToExecute = NumFile-1;
end

% messagebox -- let's get started
h = msgbox('Press ''ok'' to stop recording');
set(h,'DeleteFcn',{@PRMsgboxClose,t});
    
end

%%
% General Timer Function
%   close the previous file, start the next file, increment 
function PRTimerFcn(obj,event)

% stop previous file
I = PRIncFormat(obj.I)
cbmex('Fileconfig',[obj.FileName I],'',0);

% start next recording
obj.I = obj.I+1; % increment
I = PRIncFormat(obj.I); % format
cbmex('Fileconfig',[obj.FileName I],['Recorded on ' date ' using PediodicRecording.m'],1);
disp(['Recording file ' obj.FileName I '.nev']);

end


%%
% Timer Start Function
%   close the previous file, start the next file, increment 
function PRStartFcn(obj,event)

% set up increment value in proper format
I = PRIncFormat(obj.I)

cbmex('open')
% start first file
cbmex('Fileconfig',[obj.FileName I],'',1);
disp(['Recording file ' obj.FileName I '.nev']);
% start next recording
obj.I = obj.I+1;


end


%%
% Timer Ending Function
%   close the previous file, start the next file, increment 
function PRStopFcn(obj,event)

% set up increment value in proper format
I = PRIncFormat(obj.I)

% stop recording
disp('Stopping recording and shutting down cbmex interface')
cbmex('Fileconfig',[obj.FileName I],'',0);
cbmex('close')


end

%%
% msgbox close function
function PRMsgboxClose(obj,event,t)
    
    stop(t); % turn off the timer
end


%%
% format the increment value properly
function I = PRIncFormat(inI)
    if inI<10
        I = ['_00' num2str(inI)];
    elseif obj.I<100
        I = ['_0' num2str(inI)];
    else
        I = num2str(inI);
    end
end
