
function handles = setup_stimulator(params,handles)


switch params.output
    
    % for the grapevine
    case 'stimulator'

        % connect
        connection  = xippmex;

        % find stimulation channels
        stim_ch     = xippmex('elec','stim');

        % ToDo: check that the anode and cathode channels are in stim_ch
        
    % for the wireless stimulator
    case 'wireless_stim'

        dbg_lvl     = 1;
        connection  = wireless_stim(params.bmi_fes_stim_params.port_wireless, dbg_lvl);
        
        try
            % comm_timeout specified in ms, or disable
            ws.init(1, ws.comm_timeout_disable); % 1 = reset FPGA stim controller
            
            ws.version();      % print version info, call after init
            
            if dbg_lvl ~= 0
                % retrieve & display settings from all channels
                channel_list    = 1:ws.num_channels;
                commands        = ws.get_stim(channel_list);
                ws.display_command_list(commands, channel_list);
            end
            
        catch ME
            delete(ws);
            rethrow(ME);
        end
    
end




% Return errors and close everything if there's an error initializing the
% respective stimulator
if connection ~= 1
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