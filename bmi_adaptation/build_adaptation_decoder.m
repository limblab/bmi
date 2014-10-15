monkey = 'Mihili';

root_dir = '';
datafile = 'Mihili_M1_CO_BL_09242014_001';
task = 'CO';

useTunedSubset = false; % not fully implemented yet

latency = 0.1;
doUnsorted = 1;

BDF2BinArgs = struct('binsize',0.05,...
    'starttime',0,...
    'stoptime',0,...
    'EMG_hp',50,...
    'EMG_lp',10,...
    'minFiringRate',0,...
    'NormData',0,...
    'FindStates',0,...
    'Unsorted',doUnsorted,...
    'TriKernel',0,...
    'sig',0.04,...
    'ArtRemEnable',0,...
    'NumChan',10,...
    'TimeWind',5e-04);

% convert the file to BDF
disp('Converting data file to BDF...');
convertDataToBDF(root_dir,'');

% load BDF
load(fullfile(root_dir,[datafile '.mat']));

% bin data file
disp('Done. Binning data file...');
out_file = fullfile(root_dir,[datafile '_binned.mat']);

if BDF2BinArgs.ArtRemEnable
    disp('Looking for Artifacts...');
    out_struct = artifact_removal(out_struct,BDF2BinArgs.NumChan,BDF2BinArgs.TimeWind, 1);
end

binnedData = convertBDF2binned_Matt(out_struct,BDF2BinArgs);

save(out_file,'binnedData');

if ~useTunedSubset % just build a normal decoder with the whole file
    
    DecoderOptions = struct('foldlength',foldLength, ...
        'PredEMGs',0, ...
        'PredCursPos',0, ...
        'PredVeloc',1, ...
        'PredForce',0, ...
        'fillen',numlags*binsize, ...
        'UseAllInputs',1, ...
        'PolynomialOrder',3, ...
        'numPCs',0, ...
        'Use_Thresh',0, ...
        'Use_EMGs',0, ...
        'Use_Ridge',0, ...
        'Use_SD',0);
    
    [filt_struct, ~] = BuildModel(binnedData, DecoderOptions);
    
    filt_file = fullfile(root_dir,[datafile '_Decoder_vel.mat']);
    disp('Saving prediction model...');
    save(filt_file,'filt_struct');
    
    
else % fit tuning curves for each neuron and pick a subset
    % get trial table
    disp('Done. Getting trial table...');
    
    switch lower(task)
        case 'co'
            tt = ff_trial_table_co(bdf);
        case 'rt'
            tt = ff_trial_table_rt(bdf);
    end
    
    % now convert to movement table for use in my tuning code
    [mt,~] = getMovementTable(tt,task);
    
    % get tuning curves for all of the neurons
    disp('Done. Fitting tuning curves for all units...');
    
    % calculate firing rate for each cell
    fr = zeros(size(mt,1),size(sg,1));
    useWin = zeros(size(mt,1),2);
    for trial = 1:size(mt,1)
        useWin(trial,:) = [mt(trial,4), mt(trial,5)];
        for unit = 1:size(sg,1)
            ts = bdf.units(unit).ts;
            %  the latency to account for transmission delays
            ts = ts + latency;
            % how many spikes are in this window?
            spikeCounts = sum(ts > useWin(trial,1) & ts <= useWin(trial,2));
            fr(trial,unit) = spikeCounts./(useWin(trial,2)-useWin(trial,1)); % Compute a firing rate
        end
    end
    
    % now get movement directions
    theta = zeros(size(mt,1),1);
    for trial = 1:size(mt,1)
        idx = data.cont.t > useWin(trial,1) & data.cont.t <= useWin(trial,2);
        usePos = data.cont.pos(idx,:);
        theta(trial) = atan2(usePos(end,2)-usePos(1,2),usePos(end,1)-usePos(1,1));
    end
    theta = binAngles(theta,angleBinSize);
    
    % Perhaps rank by quality of tuning and exclude untuned cells?
    
    
    % count how many cells and select some number of random cells
    
    
    % build decoder using these cells
    
end
