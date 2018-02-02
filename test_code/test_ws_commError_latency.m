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
%   - test_time            minutes to test each set of stim params in mins [1440]
%   - email                email to notify on test changes [KevinHP's]
%   - zb_ch_page           list of ch_pages to test [0,2,5,16,17,18,19]
%   - blocking             test true/false/both [both]
%   - comm_timout_ms       timeout lengths to test [-1,15,100,1000]
%   - batt                 battery number or 'power supply' ['power supply']
%   - ch_list              channels to stimulate [1:16]
%   - PW_max               max pulse width us [200]
%   - amp                  amplitude uA [8000]


% -- #DEFINE Constants --
AMP_OFFSET = 32768; % 16-bit DAC offset setting




% fill in parameters as needed
operatingParams = struct(...
    'serial_string','COM3',...
    'dbg_lvl',3,...
    'save_folder','.',...
    'log_file','.\comErrorLog.mat',...
    'test_time','1440',...
    'email','kevinbodkin2017@u.northwestern.edu',...
    'zb_ch_page',[0,2,5,16,17,18,19],...
    'blocking','both',...
    'comm_timeout_ms',[-1,15,100,1000],...
    'batt','power supply',...
    'ch_list',[1:16],...
    'PW_max',200,...
    'amp',8000);


% set up everything to email
if any(strfind(operatingParams.email,'@'))
    email = true;
    
    setpref('Internet','SMTP_Server','smtp.gmail.com')
    setpref('Internet','E_mail','limblabfesproject@gmail.com')
    setpref('Internet','SMTP_Username','limblabfesproject@gmail.com')
    setpref('Internet','SMTP_Password','ExcellentMonkey');
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class','javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');
end



flds = fieldnames(params); % list of fields from input parameter structure
for ii = 1:numel(flds) 
    operatingParams.(flds{ii}) = params.(flds{ii}); % overwrite default values as needed
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
permInd = randperm(length(blocking)); % create a vector of random indices
blocking = blocking(permInd);
zb_ch_page = zb_ch_page(permInd);
comm_timeout_ms = comm_timeout_ms(permInd);


% interstim time -- 50 ms to match the FES requirements
interstim_t = .05;

failures = 0; % count number of failures

for ii = 1:length(blocking)
    stimParams = struct(...
        'blocking',blocking(ii),...
        'dbg_lvl',params.dbg_lvl,...
        'comm_timeout_ms',comm_timeout_ms(ii),...
        'zb_ch_page',zb_ch_page(ii),...
        'serial_string',params.serial_string);
    
    
    instrreset % flush the serial ports -- take care of any previous errors (hopefully)
    errorCode = NaN; % change to an exception if something goes wrong
    totalTime = NaN; % length current test has occured
    vSet = NaN;
    % set up to store any warnings
    wrns = {}; % cell array to store any warning MSG:IDs and strings
    warning(''); % clear lastwarning command
    
    sprintf('\n\n--------------------------------------------------')
    sprintf('Trial number %i of %i',ii,length(blocking))
    sprintf('blocking: %i, comm_timeout_ms: %i, zb_ch_page: %i\n\n',blocking(ii),comm_timeout_ms(ii),zb_ch_page(ii))


    % create file for timestamps
    tsFileName = [params.save_folder,filesep,'Comm_Timestamp_', datestr(now,'yyyymmddTHHMMSS'), '.dat'];
    tsFID = fopen(tsFileName,'w');
    
    try
        % initialize ws object
        ws  = wireless_stim(stimParams);
        pause(1); drawnow; % adding brief pauses to allow for intialization times
        % reset FPGA controller
        ws.init; pause(1); drawnow; % with some pauses
        vSet = evalc('ws.version') % not sure if this is going to work, but store all the verison stuff
        vSet = strsplit(vSet,'\n');
        vSet = vSet(4:9);

        % waveform delay - min 50 us required due to electronics design
        stagg_t = 50;
        ws.set_TD(stagg_t,params.ch_list)

        % set stimulator to run continuously
        ws.set_Run(ws.run_cont,params.ch_list)

        % configure train length, frequency, polarity and amplitude
        cmd{1} = struct('Freq',30,'PL',1); % cathodic first
        ws.set_stim(cmd,params.ch_list); % send to stimulator

        cmd{1} = struct('CathAmp',AMP_OFFSET+params.amp, 'AnodAmp', AMP_OFFSET-params.amp);
        ws.set_stim(cmd, params.ch_list);

        testTic = tic; % time the test is supposed to run for each setting

        % check whether we had any warnings
        [msgStr,msgID] = lastwarn;
        if ~strcmp(msgStr,'')
            wrns{end+1,1} = msgStr;
            wrns{end+1,2} = msgID;
            warning('');
        end
       
        
        while toc(testTic) < params.test_time*60 % while we're still running

            PW = round(rand(size(params.ch_list))*params.PW_max);
            cur_t           = tic;
            % update anode and cathode PW
            ws.set_AnodDur( PW, params.ch_list);
            ws.set_CathDur( PW, params.ch_list);

            % wait until enough time has elapsed & store latency
            elapsed_t       = toc(cur_t);
            fwrite(tsFID,elapsed_t,'double'); % store the communication time

            % check whether we had any warnings
            [msgStr,msgID] = lastwarn;
            if ~strcmp(msgStr,'')
                wrns{end+1,1} = msgStr;
                wrns{end+1,2} = msgID;
                warning('');
            end

            while elapsed_t < interstim_t
                elapsed_t   = toc(cur_t);
            end

            drawnow;
        end

        totalTime = toc(testTic);
        
    catch ME
        errorCode = ME;
        failures = failures+1;
        if exist('testTic','var')
            totalTime = toc(testTic);
        end
    end
    
    % close the file with the timestamps
    fclose(tsFID)
    
    versionInfo = struct('deviceID',vSet(1),...
        'atmelID',vSet(2),...
        'wsVersion',vSet(3),...
        'localVersion',vSet(4),...
        'remoteVersion',vSet(5),...
        'FPGAVersion',vSet(6));
    
    
    % create struct with all important information about test
    currStor = struct('initParams',stimParams,...
        'chList',params.ch_list,...
        'PWMax',params.PW_max,...
        'amp',params.amp,...
        'totalTime',totalTime,...
        'battery',params.batt,...
        'tsFile',which(tsFileName),...
        'knownWarnings',{wrns},...
        'error',{errorCode},...
        'versionInfo',versionInfo,...
        'computer',getenv('ComputerName'));


    % load matlab struct with info on previous data, if it exists
    if exist(params.log_file)
        load(params.log_file) % open the file if it already exists
        commErrorLog{end+1} = currStor; % add the current log to the list
    else
        commErrorLog = {currStor}; % otherwise make a new struct
    end
    save(params.log_file,'commErrorLog','-v7.3') % save the updated structure


    % send email if we want
    if email
        if ~strcmp(class(errorCode),'MException')
            subject = sprintf('Test %i of %i success',ii,length(blocking));
        else
            subject = sprintf('Test %i of %i failed',ii,length(blocking))
        end
        
        sendmail(params.email,subject,...
            sprintf('Computer: %s\n Total Stimulation Time: %f min\n Blocking: %i\n  comm_timeout_ms: %i\n zb_ch_page:%i',...
            getenv('ComputerName'),totalTime/60,blocking(ii),comm_timeout_ms(ii),zb_ch_page(ii)))
    end
    
    
    % final clean up
    ws.delete
end


if email
    subject = sprintf('%s Test Complete',getenv('ComputerName'));
    sendmail(params.email,subject,'Testing has completed')
end


sprintf('Test complete.\n %i of %i tests resulted in failure.',failures,length(blocking))


end


