%
% remove stimulation artifacts from threshold crossings recorded with
% get_new_spikes()
%
%   function cleaned_ts = remove_stim_artifacts( ts, params, bin_dur )
%
% Inputs:
%   ts                  : cell array with threshold crossing times for each
%                           channel (CBMex standard format)
%   params              : param struct of run_decoder / run_bmi_fes
%   bin_dur             : duration of the last CBMex read (bin)
%
% Ouputs:
%   cleaned_ts          : ts cell array without the time stamps of the
%                           artefacts (CBMex standard format)
%
%

function cleaned_ts = remove_stim_artifacts( ts, params, bin_dur )

 
% params for artifact removal
max_nbr_chs             = 10;
reject_bin_size         = 0.001;


% -------------------------------------------------------------------------
% 1. Bin the threshold crossings into bins of size 'reject_bin_size'

% time support for binning, made equal to the length of the recorded bin
rejection_t             = 0:reject_bin_size:ceil(bin_dur/reject_bin_size)*reject_bin_size;
% preallocate matrix for storing bin counts
counts                  = zeros(length(rejection_t),params.n_neurons);
% bin the data
for n = 1:params.n_neurons
    unit                = params.neuronIDs(n,2);
    temp_counts         = histc(double(ts{n,unit+2})/30000,rejection_t)';
    if ~isempty(temp_counts)
        counts(:,n)     = temp_counts;
    end
end

% -------------------------------------------------------------------------
% This portion will have to be reimplemented later.
% % 2. Block stimulation artifacts
% 
% % find the delay between last block time and the buffer read time
% % then get the modulo of that divided by the stim period -- subtracting
% % that from the interstim period will give us the time of the next stim.
% 
% nextStim = floor((.033 - mod((tBuffer-params.tSync),.033))/reject_bin_size); % there's gotta be a cleaner way to do this
% 
% if nextStim + 33 < size(counts,1) % are there going to be two stims in this bin?
%     counts(nextStim,:) = 0;
%     counts(nextStim+33,:) = 0;
% else
%     counts(nextStim,:) = 0;
% end
% 


% -------------------------------------------------------------------------
% 2. Look for bins with spikes in more chs than 'max_nbr_chs'

% number of channels with simultaneous spikes across the whole array
array_counts            = sum(counts,2);
% get bins with artefacts
bins_w_artifacts        = find(array_counts>max_nbr_chs);
nbr_artifacts           = length(bins_w_artifacts);
% -------------------------------------------------------------------------
% 3. Go back and get rid of spikes

% for each bin with artifact
for i = 1:nbr_artifacts
    % get the channels that had artefacts
    bin                 = bins_w_artifacts(i);
    chs_w_artifacts     = find(counts(bin,:));
    % and remove the threshold crossings that happened in that bin
    for n = 1:length(chs_w_artifacts)
        ch              = chs_w_artifacts(n);
        unit            = params.neuronIDs(ch,2);
        
        ts{ch,unit+2}( (bin-1)*reject_bin_size < double(ts{ch,unit+2})/30000 ...
                & double(ts{ch,unit+2})/30000 < bin*reject_bin_size ) = [];
    end
    clear chs_w_artifacts;
end

% warn about the artefacts
if nbr_artifacts > 0
    disp([num2str(nbr_artifacts) ' artifact(s) in this bin']);
    drawnow;
end

% -------------------------------------------------------------------------
% return cleaned threshold crossings
cleaned_ts              = ts;