
% Brain Control through EMG cascade Experiment
% IP address: 0:10 are the last two numbers

% Steps
%1. Record 15 min of isometric force data
% 2.  
train_data = convert2BDF2Binned; %DONT FORGET: Normalize Force and EMG!

% 3.  
opts = BuildModelGUI; %(in=spikes, out=EMG, length = 500ms, polyn order = 0)
% Select the 4 wrist EMGs
% Locate the indices for ECR, ECU, FCR, FCU
FCUind = strmatch('FCU',train_data.emgguide(1,:)); FCUind = FCUind(1);
FCRind = strmatch('FCR',train_data.emgguide(1,:)); FCRind = FCRind(1);
ECUind = strmatch('ECU',train_data.emgguide(1,:)); ECUind = ECUind(1);
ECRind = strmatch('ECR',train_data.emgguide(1,:)); ECRind = ECRind(1);
emg_vector = [FCUind FCRind ECUind ECRind];
train_data_subset = train_data;
train_data_subset.emgdatabin = train_data.emgdatabin(:,emg_vector);
train_data_subset.emgguide = train_data.emgguide(emg_vector);

% Build neuron to EMG model
N2E  = BuildModel(train_data_subset,opts);

% Load EMG to Force decoders [new as of 4/29/2015]
%load('E:\Data-lab1\12A2-Kevin\LearnAdapt\E2F_Decoders\E2F_decoders_from04282015.mat')
load('E:\Data-lab1\12A2-Kevin\LearnAdapt\E2F_Decoders\E2F_decoders_from06092015.mat')

% Build EMG to Force model
%opts = BuildModelGUI; %(in=EMG, out=cursor position, ***PAY ATTENTION length = 250ms****, polyn order=0 )
%E2F  = BuildModel(train_data_subset,opts);


% Make reflected EMG to Force decoder--------------------------------------
% FCRweightsInd = strmatch('FCR',N2E.outnames(1,:));
% ECRweightsInd = strmatch('ECR',N2E.outnames(1,:));
% noOfWeights = opts.fillen/.05;
% FCRindices = fliplr((noOfWeights*FCRweightsInd:-1:noOfWeights*FCRweightsInd-noOfWeights+1));
% FCR2Fweights = E2F.H(FCRindices,:);
% ECRindices = fliplr((noOfWeights*ECRweightsInd:-1:noOfWeights*ECRweightsInd-noOfWeights+1));
% ECR2Fweights = E2F.H(ECRindices,:);
% E2F_reflected = E2F;
% E2F_reflected.H(ECRindices,:) = FCR2Fweights;
% E2F_reflected.H(FCRindices,:) = ECR2Fweights;
%--------------------------------------------------------------------------

% Make rotated EMG to Force decoder----------------------------------------
% train_data_rotated = convert2BDF2Binned;
% train_data_rotated_subset = train_data_rotated; %new
% train_data_rotated_subset.emgdatabin = train_data_rotated.emgdatabin(:,emg_vector); %new
% train_data_rotated_subset.emgguide = train_data_rotated.emgguide(emg_vector); %new
% rotatedOpts = BuildModelGUI; %(in=EMG, out=cursor position, ***PAY ATTENTION length = 250ms****, polyn order=0 )
% E2F_rotated  = BuildModel(train_data_rotated_subset,rotatedOpts);
%--------------------------------------------------------------------------

% 4.  
params  = bmi_params_steph('emg_cascade');

% 5. 
params.neuron_decoder = N2E;
params.emg_decoder = E2F_normal_from06092015;

% params.emg_decoder = E2F_rotated_from06092015;
% params.emg_decoder = E2F_reflected_from06092015;

% 6.  Turn on the task using the R8T4_isometric_easyparameters behavioral file  

% 7. 
% Set the recording time that you want on the FileStorage GUI
run_decoder2(params)





% Make normal decoder

% Make reflected decoder
% N2Enormal = N2E;
% FCRweightsInd = strmatch('FCR',N2E.outnames(1,:));
% ECRweightsInd = strmatch('ECR',N2E.outnames(1,:));
% ECRweights = N2E.H(:,ECRweightsInd); FCRweights = N2E.H(:,FCRweightsInd);
% N2E.H(:,ECRweightsInd) = FCRweights;
% N2E.H(:,FCRweightsInd) = ECRweights;
% N2Ereflected = N2E;



