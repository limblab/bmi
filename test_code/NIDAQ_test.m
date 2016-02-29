if ~exist('s','var')
    s = daq.createSession('ni');
    devs = daq.getDevices;
    devs = devs.ID;
        
    addCounterOutputChannel(s,devs, 0, 'PulseGeneration');
%     addAnalogInputChannel(s,devs, 8, 'Voltage');
    disp(['Connect motor to terminal ' s.Channels(1).Terminal])
%         lh = addlistener(s,'DataAvailable', @plotData);
end

%%
ch = s.Channels(1);
ch.Frequency = 500;
ch.InitialDelay = 0;
ch.DutyCycle = 0.7;
s.Rate = 1000;
% s.DurationInSeconds = 5;
s.IsContinuous = true;

%%
s.startBackground()
for i = 1:3
    freq = .5*i;   
    t = 0;
    tic
    while t < 5
        t = toc;
        ch.DutyCycle = .3*sin(2*pi*freq*t)+.69;
        pause(.05)    
    end
end
s.stop()
