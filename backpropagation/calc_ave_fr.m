function ave_fr = calc_ave_fr(varargin)
% measures and returns the average firing rate from cerebus stream
% uses the same param structure as run_decoder, see bmi_params_defaults.m

if nargin
    params = varargin{1};
    params = bmi_params_defaults(params);
else
    params = bmi_params_defaults;
end

if params.online
    connection = cbmex('open',1);
    if ~connection
        error('Connection to Central Failed');
    end
    
    new_spikes = zeros(params.n_neurons,1);
    Redo = 'Redo';
    
    while(strcmp(Redo,'Redo'))
        ave_fr = 0.0;
        h = waitbar(0,'Averaging Firing Rate');
        cbmex('trialconfig',1,'nocontinuous');
        buf_t = tic;
        for i = 1:10
            pause(0.5);
            pause_t = toc(buf_t);
            ts_cell_array = cbmex('trialdata',1);
            buf_t = tic;
            %firing rate for new spikes
            for n = 1:params.n_neurons
                new_spikes(n) = length(ts_cell_array{n,2})/pause_t;
            end
            ave_fr = ave_fr + mean(new_spikes);
            waitbar(i/10,h);
        end
        ave_fr = ave_fr/10;
        close(h);
        Redo = questdlg(sprintf('Ave FR = %.2f Hz',ave_fr),'Looks good?','OK','Redo','OK');
    end
    clearxpc;
else
    offline_data = LoadDataStruct(params.offline_data);
    ave_fr = mean(mean(offline_data.spikeratedata));
    msgbox(sprintf('Ave FR = %.2f Hz',ave_fr),'Offline File');
end

% function ave_fr = calc_ave_fr(params,varargin)
%     if params.online
%         Redo = 'Redo';
%         while(strcmp(Redo,'Redo'))
%             ave_fr = 0.0;
%             h = waitbar(0,'Averaging Firing Rate');
%             cbmex('trialconfig',1,'nocontinuous');
%             for i = 1:10
%                 pause_t = tic;
%                 pause(0.5);
%                 ts_cell_array = cbmex('trialdata',1);
%                 pause_t = toc(pause_t);
%                 new_spikes = get_new_spikes(ts_cell_array,params.n_neurons,pause_t);
%                 ave_fr = ave_fr + mean(new_spikes);
%                 waitbar(i/10,h);
%             end
%             ave_fr = ave_fr/10;
%             close(h);
%             Redo = questdlg(sprintf('Ave FR = %.2f Hz',ave_fr),'Looks good?','OK','Redo','OK');
%         end
%     else
%         offline_data = varargin{1};
%         ave_fr = mean(mean(offline_data.spikeratedata));
%         uiwait(msgbox(sprintf('Ave FR = %.2f Hz',ave_fr)));
%     end
% end