% data_location = 'D:\Data\Chewie_8I2\Chewie_2014-11-26_DCO_iso_hu';
data_location = 'D:\Data\Chewie_8I2\Chewie_2014-12-04_DCO_iso_hu_Thr5_pseudo_emg';
% bdf_file = [data_location filesep 'Output_Data\bdf.mat'];
bdf_file = [data_location '\BDFStructs\Chewie_2014-12-04_DCO_iso_hu_Thr5_pseudo_emg_001.mat'];
param_file = dir([data_location filesep 'CerebusData\*params*']);
param_file = [data_location filesep 'CerebusData\' param_file(1).name];
decoder_type = 'musc';
bdf = load(bdf_file);
temp = fields(bdf);
bdf = bdf.(temp{1});
load(param_file);

F = -bdf.force(:,2:3);
if strcmp(decoder_type,'musc')
    [estimated_emg,normalization_val] = end_force_to_musc_act(arm_params,F);
elseif strcmp(decoder_type,'cartesian')
    [estimated_emg,normalization_val] = end_force_to_cartesian_musc_act(arm_params,F);
end
model_emg_order = {'EMG_AD','EMG_PD','EMG_BI','EMG_TRI'};

for iEMG = 1:length(model_emg_order)
    emg_order(iEMG) = find(~cellfun(@isempty,strfind(model_emg_order,bdf.emg.emgnames{iEMG}))); %#ok<SAGROW>
end
estimated_emg = estimated_emg(:,emg_order);
bdf.emg.data(:,2:5) = estimated_emg;
bdf.emg.rectified = true;

[bdf_folder,bdf_filename,ext] = fileparts(bdf_file);
save([bdf_folder filesep bdf_filename '-' decoder_type],'bdf')