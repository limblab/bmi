monkey = 'Mihili';
array = 'M1';
y = '2015';
m = '08';
d = '03';
task = 'RT';
filenum = '001';

bdf_file = ['E:\' monkey '\Matt\BMIAdaptation\' array '\' y '-' m '-' d '\' monkey '_' array '_' task '_BC_BL_' m d y '_' filenum '.mat'];
out_file = ['E:\' monkey '\Matt\BMIAdaptation\' array '\' y '-' m '-' d '\' monkey '_' array '_' task '_BC_BL_' m d y '_' filenum '_binned.mat'];
filt_file = ['E:\' monkey '\Matt\BMIAdaptation\' array '\' y '-' m '-' d '\' monkey '_' array '_' task '_BC_BL_' m d y '_' filenum '_Decoder_vel.mat'];

minFiringRate = 1;
polyOrder = 3;
foldLength = 60;
useUnsorted = 1;
remArtifacts = 1;
numlags = 10;
binsize = 0.05;
remakeBDF = false;

BDF2BinArgs = struct('binsize',0.05,'starttime',0,'stoptime',0,'EMG_hp',50,'EMG_lp',10,'minFiringRate',minFiringRate,'NormData',0,'FindStates',0,'Unsorted',useUnsorted,'TriKernel',0,'sig',0.04,'ArtRemEnable',remArtifacts,'NumChan',10,'TimeWind',5e-04);
DecoderOptions = struct('PolynomialOrder',polyOrder,'minFiringRate',minFiringRate,'foldlength',foldLength,'PredEMGs',0,'PredCursPos',0,'PredVeloc',1,'PredTarg',0,'PredForce',0,'PredCompVeloc',0,'PredMoveDir',0,'fillen',numlags*binsize,'UseAllInputs',1,'numPCs',0,'Use_Thresh',0,'Use_EMGs',0,'Use_Ridge',0,'Use_SD',0);

%% Get BDF
if remakeBDF || ~exist(bdf_file,'file') % Make BDF
    disp('Creating BDF...');
    out_struct = get_nev_mat_data(['E:\Mihili\Matt\BMIAdaptation\M1\' y '-' m '-' d '\' monkey '_' array '_' task '_BC_BL_'],3);
    save(bdf_file,'out_struct','-v7.3');
    BDF = out_struct;
    clear out_struct;
else % Load BDF
    disp('Loading BDF...')
    BDF = LoadDataStruct(bdf_file);
end
disp('Done.');

%% Remove artifacts
if BDF2BinArgs.ArtRemEnable
    disp('Looking for Artifacts...');
    BDF = artifact_removal(BDF,BDF2BinArgs.NumChan,BDF2BinArgs.TimeWind, 1);
    disp('Done.');
end

%% Bin
disp('Converting BDF structure to binned data...');
binnedData = convertBDF2binned_Matt(BDF,BDF2BinArgs);
disp('Done.');

disp('Saving binned data...');
save(out_file,'binnedData');
disp('Done.');

%% Build model
disp('Building decoder...');
[filt_struct, ~] = BuildModel_Matt(binnedData, DecoderOptions);
disp('Done.');

if isempty(filt_struct)
    error('Model Building Failed');
end

disp('Saving prediction model...');
save(filt_file,'filt_struct');
disp('Done.');

%% Cross validate
disp(sprintf('Proceeding to multifold cross-validation using %g sec folds...', DecoderOptions.foldlength));
[mfxval_R2, mfxval_vaf, mfxval_mse, ~] = mfxval_Matt(binnedData, DecoderOptions);
disp('Done.');