
function handles = setup_stimulator(params,handles)


switch params.output
    
    % for the grapevine
    case 'stimulator'

        % connect
        handles.gv  = xippmex; 

        % find stimulation channels
        channel_list = xippmex('elec','stim');

        % ToDo: check that the anode and cathode channels are in stim_ch

        % if there's a communication error with the grapevine
        if handles.gv ~= 1
            cbmex('close');
            if exist('xpc','var')
                fclose(xpc);
                delete(xpc);
                echoudp('off')
                clear xpc
            end
            close(handles.keep_running);
            error('Grapevine not found');
        end
        
    % for the wireless stimulator
    case 'wireless_stim'
% 
%         dbg_lvl     = 0; % could be made into a parameter
%         comm_timeout_ms = -1;
%         blocking = true;
%         zb_ch_page = 17;
%         
        stim_params = struct('dbg_lvl',1,'comm_timeout_ms',-1,'blocking',true,'zb_ch_page',17,'serial_string',params.bmi_fes_stim_params.port_wireless)
        handles.ws  = wireless_stim(stim_params);
        
        try
            % Switch to the folder that contains the calibration file
            cur_dir = pwd;
            cd( params.bmi_fes_stim_params.path_cal_ws );
            
            % comm_timeout specified in ms, or disable
%             handles.ws.init( 1, handles.ws.comm_timeout_disable ); % 1 = reset FPGA stim controller
            handles.ws.init();

            handles.ws.version();      % print version info, call after init
            
            % TEMP: go back to the folder you were
            cd(cur_dir)
            
            if stim_params.dbg_lvl ~= 0
                % retrieve & display settings from all channels
                channel_list    = 1:handles.ws.num_channels;
                commands        = handles.ws.get_stim(channel_list);
                handles.ws.display_command_list(commands, channel_list);
            end
            
            % set up the stimulation params that will not be modulated
            % (frequency, polarity, amplitude/PW [depending on the stim
            % mode] ...) 
            setup_wireless_stim_fes(handles.ws, params.bmi_fes_stim_params);
            
        % if something went wrong close communication with Central and the
        % stimulator and quit
        catch ME
            delete(handles.ws);
            cbmex('close');
            if exist('xpc','var')
                fclose(xpc);
                delete(xpc);
                echoudp('off')
                clear xpc
            end
            close(handles.keep_running);
            rethrow(ME);
        end
end

