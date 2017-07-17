%
% Function to build an EMG decoder from raw data in a format that will be
% compatible with (call_)run_bmi_fes
% 
%   neuron2emg_decoder = build_emg_decoder_from_nev( file_path, file_name_prefix, task, emg_list_4_dec )
%   neuron2emg_decoder = build_emg_decoder_from_nev( file_path_and_name, task, emg_list_4_dec )
%
% Inputs:
%   (file_path)             : file path
%   (file_name)             : file name
%   (file_path_and_name)    : file path and name in a single string
%   task                    : task: 'WF', 'WM', 'MG_XX' (XX = [PW, KG, PG])
%   emg_list4_dec           : list of EMGs that want to be decoded
%   poly_order              : order of the polynomial in static
%                               non-linearity
%
% Outputs:
%   neuron2emg_decoder      : decoder
%

function [neuron2emg_decoder,pred_data] = build_emg_decoder_from_nev( varargin )


% some opts -can be made into parameters
dec_opts.PredEMGs   = 1;
% dec_opts.fillen     = 0.5; % filter length (s)
% dec_opts.plotflag   = 1;

bin_opts.NormData   = true;
bin_opts.HP = 90; % setting it a little higher to get rid of some of the 60 hz noise


% ------------------------------------------------------------------------
% read inputs
if nargin == 4
    file4decoder    = varargin{1};
    task            = varargin{2};
    emg_list_4_dec  = varargin{3};
    poly_order      = varargin{4};
elseif nargin == 5
    file_path       = varargin{1};
    file_name_prefix = varargin{2};
    task            = varargin{3};
    emg_list_4_dec  = varargin{4};
    poly_order      = varargin{5};
    file4decoder    = [file_path, file_name_prefix];
end

% static non-linearity?
dec_opts.PolynomialOrder = poly_order;


% ------------------------------------------------------------------------
% convert to BDF and bin
if strncmp(task,'MG',2)
    % for the multigadget, there is no pos data
    bdf             = get_nev_mat_data(file4decoder,'nokin');
elseif strncmp(task,'WF',2)
    bdf             = get_nev_mat_data(file4decoder,'nokin');
elseif strncmp(task,'treats',6)
    bdf             = get_nev_mat_data(file4decoder,'nokin');
end

% bin the data
binned_data         = convertBDF2binned(bdf,bin_opts);

for i = 1:size(binned_data.emgguide)
    qmin = quantile(binned_data.emgdatabin(:,i),.05);
    binned_data.emgdatabin(:,i) = binned_data.emgdatabin(:,i)-qmin;
end

% ------------------------------------------------------------------------
% find the EMGs that we want to decode, get rid of the others
emg_pos_in_bin      = zeros(1,numel(emg_list_4_dec));
for i = 1:length(emg_pos_in_bin)
    aux_emg_pos     = find( strncmp(binned_data.emgguide,emg_list_4_dec(i),...
                        length(emg_list_4_dec{i})) );
    % the length of the EMG electrode name may have different length, and
    % can overlap with another, in that case choose the one with shortest
    % number of chars; this is the one you're looking for
    if length(aux_emg_pos) > 1
        aux_numchar_emg     = [];
        for ii = 1:length(aux_emg_pos)
            aux_numchar_emg = [aux_numchar_emg, ...
                                length(binned_data.emgguide{aux_emg_pos(ii)})];
        end
        aux_emg_pos = aux_emg_pos( aux_numchar_emg == length(emg_list_4_dec{i}) );
    end
    emg_pos_in_bin(i)   = aux_emg_pos;
end


% ------------------------------------------------------------------------
% Build the decoder

train_data              = binned_data;
train_data.emgguide     = emg_list_4_dec;
train_data.emgdatabin   = binned_data.emgdatabin(:,emg_pos_in_bin);

[neuron2emg_decoder,pred_data]      = BuildModel( train_data, dec_opts );


[R2, VAF]               = mfxval( train_data, dec_opts );


% ------------------------------------------------------------------------
% plot
figure,
subplot(121)
bar(mean(R2,1))
set(gca,'FontSize',14),set(gca,'TickDir','out')
set(gca,'Xtick',1:length(emg_list_4_dec))
set(gca,'XTickLabel',emg_list_4_dec)
set(gca,'XTickLabelRotation',45)
ylabel('R^2'),ylim([0 1]), xlim([0 length(emg_list_4_dec)+1])
subplot(122)
bar(mean(VAF,1))
set(gca,'FontSize',14),set(gca,'TickDir','out')
set(gca,'Xtick',1:length(emg_list_4_dec))
set(gca,'XTickLabel',emg_list_4_dec)
set(gca,'XTickLabelRotation',45)
ylabel('VAF'),ylim([0 1]), xlim([0 length(emg_list_4_dec)+1])

