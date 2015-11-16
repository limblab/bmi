
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
        connection  = 1;
        
    % for the wireless stimulator
    case 'wireless_stim'

        dbg_lvl     = 1; % could be made into a parameter
        handles.ws  = wireless_stim(params.bmi_fes_stim_params.port_wireless, dbg_lvl);
        
        try
            % comm_timeout specified in ms, or disable
            handles.ws.init( 1, handles.ws.comm_timeout_disable ); % 1 = reset FPGA stim controller
            
            handles.ws.version();      % print version info, call after init
            
            if dbg_lvl ~= 0
                % retrieve & display settings from all channels
                channel_list    = 1:handles.ws.num_channels;
                commands        = handles.ws.get_stim(channel_list);
                handles.ws.display_command_list(commands, channel_list);
            end
            
            % if everything ok
            connection  = 1;
            
        catch ME
            delete(handles.ws);
            rethrow(ME);
        end
    
end




% Return errors and close everything if there's an error initializing the
% respective stimulator
if ~connection
    cbmex('close');
    
    if exist('xpc','var')
        fclose(xpc);
        delete(xpc);
        echoudp('off')
        clear xpc
    end
    
    close(handles.keep_running);
    
    switch params.output
        case 'stimulator'
            error('ERROR: Xippmex did not initialize');
        case 'wireless_stim'
            error('ERROR: No connection to wireless stimulator');
    end
end