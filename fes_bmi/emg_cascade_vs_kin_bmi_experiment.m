% Brain Control of Kinematic Experiment
% 
% 1.  Record 15 min of wrist movement data
% 
% 2.  >> train_data = convert2BDF2Binned;
% 
% 3.  >> opts = BuildModelGUI;
%     >> dec  = BuildModel(train_data,opts);
%     
% 4.  >> params  = bmi_params_steph('kinematics');
%     
% 5.  >> params.neuron_decoder = dec;
% 
% 6.  Setup behavior for bmi:
%         - software filter?
%         - easier targets, shorter hold time?
%         - continuous neural control
%         
% 7.  run_decoder2(params)


% Brain Control through EMG cascade Experiment
% 
% 1.  Record 15 min of isometric force data
% 
% 2.  >> train_data = convert2BDF2Binned; %DONT FORGET: Normalize Force and EMG!
% 
% 3.  >> opts = BuildModelGUI; %(in=spikes, out=EMG, length = 500ms, polyn order = 0)
%     >> N2E  = BuildModel(train_data,opts);
%     >> opts = BuildModelGUI; %(in=EMG, out=cursor position, ***PAY ATTENTION length = 50ms****, polyn order=0 )
%     >> E2F  = BuildModel(train_data,opts);
%     
% 4.  >> params  = bmi_params_steph('emg_cascade');
%     
% 5.  >> params.neuron_decoder = N2E;
%     >> params.emg_decoder = E2F;
% 
% 6.  Turn on the task using the R8T4_IsoBC behavioral file
%        
%         
% 7.  run_decoder2(params)
