% Brain Control of Kinematic Experiment
% 
% 1.  Record 20(?) min of wrist movement data
% 
% 2.  >> train_data = convert2BDF2Binned
% 
% 3.  >> opts = BuildModelGUI;
%     >> dec  = BuildModel(train_data,opts);
%     
% 4.  >> params  = kin_bmi_default;
%     
% 5.  >> params.neuron_decoder = dec;
% 
% 6.  Setup behavior for bmi:
%         - software filter?
%         - easier targets, shorter hold time?
%         - continuous neural control
%         
% 7.  run_decoder2(params)
