function handles = create_NIDAQ_session(params,handles)

daq_devices = daq.getDevices;
if numel(daq_devices)~= 1
    disp('No NIDAQ devices found, can''t use vibration motor.')
    handles.NIDAQ = [];
    return;
end
if isfield(handles,'NIDAQ') && isfield(handles.NIDAQ,'session')
    if handles.NIDAQ.session.isvalid    
        try
            handles.NIDAQ.session.stop;
        end
        release(handles.NIDAQ.session);
        delete(handles.NIDAQ.session);
    end
end

handles.NIDAQ.session = daq.createSession('ni');
devs = daq.getDevices;
handles.NIDAQ.devs = devs.ID;
if isfield(params,'num_NIDAQ_outputs')
    for iOutput = 0:params.num_NIDAQ_outputs-1
        addCounterOutputChannel(handles.NIDAQ.session,handles.NIDAQ.devs, iOutput, 'PulseGeneration');
        disp(['Connect motor ' num2str(iOutput+1) ' to terminal ' handles.NIDAQ.session.Channels(iOutput+1).Terminal])
    end
else
    addCounterOutputChannel(handles.NIDAQ.session,handles.NIDAQ.devs, 0, 'PulseGeneration');
    disp(['Connect motor to terminal ' handles.NIDAQ.session.Channels(1).Terminal])
end
%%
for iOutput = 1:length(handles.NIDAQ.session.Channels)
    ch = handles.NIDAQ.session.Channels(iOutput);
    ch.Frequency = 500;
    ch.InitialDelay = 0;
    ch.DutyCycle = 0.001;
end
handles.NIDAQ.session.Rate = 1000;
handles.NIDAQ.session.IsContinuous = true;
handles.NIDAQ.session.startBackground()

%%
if isfield(params,'vibration_motors') &&... 
        isfield(params.vibration_motors,'test_motors') && params.vibration_motors.test_motors
    disp('Testing motors')
    for iOutput = 1:length(handles.NIDAQ.session.Channels)
        disp('Motor 1')
        ch = handles.NIDAQ.session.Channels(iOutput);
        ch.DutyCycle = .7;
        pause(1)
        ch.DutyCycle = .001;
    end
    disp('Done testing motors')
else
    disp('Not testing motors')
end
    

