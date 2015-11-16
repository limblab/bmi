
function handles = setup_stimulator(params,handles)


switch params.output
    
    % for the grapevine
    case 'stimulator'

        % connect
        handles.gv  = xippmex;

        % find stimulation channels
        channel_list = xippmex('elec','stim');

        % ToDo: check that the anode and cathode channels are in stim_ch

        
        % if everything ok
        if handles.gv.connection ~= 1
 
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

        dbg_lvl     = 1; % could be made into a parameter
        handles.ws  = wireless_stim(params.bmi_fes_stim_params.port_wireless, dbg_lvl);
        
        try
            
            % TEMP: switch to the folder that contains the calibration file
            cur_dir = pwd;
            cd([params.save_dir filesep datestr(now,'yyyymmdd')])
            
            % comm_timeout specified in ms, or disable
            handles.ws.init( 1, handles.ws.comm_timeout_disable ); % 1 = reset FPGA stim controller
            
            handles.ws.version();      % print version info, call after init
            
            % TEMP: go back to the folder you were
            cd(cur_dir)
            
            if dbg_lvl ~= 0
                % retrieve & display settings from all channels
                channel_list    = 1:handles.ws.num_channels;
                commands        = handles.ws.get_stim(channel_list);
                handles.ws.display_command_list(commands, channel_list);
            end
            
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

