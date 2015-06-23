function [cmd_combined] = stim_elect_mapping(PW,PA, params)

cmd_combined = [];

for i = 1:length(params.cathode_map)
    
    if(params.mode == 1)
        elect_current = params.current_max(i).*params.cathode_map{2,i};
    else
        elect_current = PA(i).*params.cathode_map{2,i};
    end
    
    converted_elect_current = round(elect_current/0.018);
    
    if(params.mode == 1)
        duration_command = round(1000*PW(i));
    else
        duration_command = round(params.duration_command(i));
    end
    
    cmd_length = 1;
    
    if(duration_command ==0 || duration_command == 33 || duration_command == 67 || duration_command == 100 || duration_command == 133 || duration_command == 167 || duration_command == 200)
        
        cmd_length = round(duration_command/33.3);
        
        
        
        for j = 1:length(params.cathode_map{1,i})
            
            if(duration_command == 0)
                cmd_length = 1;
                converted_elect_current(j) = 0;
            end
            
            cmd = struct('elec',params.cathode_map{1,i}(j),'period',1000,'repeats',params.freq,'action','curcyc');
            
            cmd.seq(1) = struct('length',cmd_length,'ampl',converted_elect_current(j),'pol',0,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            cmd.seq(2) = struct('length',6,'ampl',0,'pol',0,'fs',0,'enable',0,'delay',0,'ampSelect',1);
            cmd.seq(3) = struct('length',cmd_length,'ampl',converted_elect_current(j),'pol',1,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            
            cmd_combined = cat(2,cmd_combined,cmd);
            
        end
        
    else
        
        cmd_length = floor(duration_command/33.3);
        cmd_length2 = cmd_length;
        delay = round(duration_command - 33.3*cmd_length);
        duration_command = round(duration_command);
        converted_elect_current2 = converted_elect_current;
        cmd_mod = mod(duration_command,33.3);
        
        
        if(cmd_length == 1 || cmd_length == 4)
            delay = round(cmd_mod);
            
        else
            delay = round((31/30)*cmd_mod-(1/30));
        end
        
        for j = 1:length(params.cathode_map{1,i})
            
            if(cmd_length == 0)
                cmd_length2 = 1;
                converted_elect_current2(j) = 0;
            end
            
            cmd = struct('elec',params.cathode_map{1,i}(j),'period',1000,'repeats',params.freq,'action','curcyc');
            
            cmd.seq(1) = struct('length',cmd_length2,'ampl',converted_elect_current2(j),'pol',0,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            cmd.seq(2) = struct('length',1,'ampl',converted_elect_current(j),'pol',0,'fs',0,'enable',0,'delay',delay,'ampSelect',1);
            
            cmd.seq(3) = struct('length',6,'ampl',0,'pol',0,'fs',0,'enable',0,'delay',0,'ampSelect',1);
            
            cmd.seq(4) = struct('length',cmd_length2,'ampl',converted_elect_current2(j),'pol',1,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            cmd.seq(5) = struct('length',1,'ampl',converted_elect_current(j),'pol',1,'fs',0,'enable',0,'delay',delay,'ampSelect',1);
            
            cmd_combined = cat(2,cmd_combined,cmd);
            
        end
    end
    
end

for i = 1:length(params.anode_map)
    
    if(params.mode == 1)
        elect_current = params.current_max(i).*params.anode_map{2,i};
    else
        elect_current = PA(i).*params.anode_map{2,i};
    end
    
    converted_elect_current = round(elect_current/0.018);
    
    if(params.mode == 1)
        duration_command = round(1000*PW(i));
    else
        duration_command = round(params.duration_command(i));
    end
    
    cmd_length = 1;
    
    if(duration_command ==0 || duration_command == 33 || duration_command == 67 || duration_command == 100 || duration_command == 133 || duration_command == 167 || duration_command == 200)
        
        cmd_length = round(duration_command/33.3);
        
        
        
        for j = 1:length(params.anode_map{1,i})
            
            if(duration_command == 0)
                cmd_length = 1;
                converted_elect_current(j) = 0;
            end
            
            cmd = struct('elec',params.anode_map{1,i}(j),'period',1000,'repeats',params.freq,'action','curcyc');
            
            cmd.seq(1) = struct('length',cmd_length,'ampl',converted_elect_current(j),'pol',1,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            cmd.seq(2) = struct('length',6,'ampl',0,'pol',0,'fs',0,'enable',0,'delay',0,'ampSelect',1);
            cmd.seq(3) = struct('length',cmd_length,'ampl',converted_elect_current(j),'pol',0,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            
            cmd_combined = cat(2,cmd_combined,cmd);
            
        end
        
    else
        
        cmd_length = floor(duration_command/33.3);
        cmd_length2 = cmd_length;
        delay = round(duration_command - 33.3*cmd_length);
        duration_command = round(duration_command);
        converted_elect_current2 = converted_elect_current;
        cmd_mod = mod(duration_command,33.3);
        
        
        if(cmd_length == 1 || cmd_length == 4)
            delay = round(cmd_mod);
            
        else
            delay = round((31/30)*cmd_mod-(1/30));
        end
        
        for j = 1:length(params.anode_map{1,i})
            
            if(cmd_length == 0)
                cmd_length2 = 1;
                converted_elect_current2(j) = 0;
            end
            
            cmd = struct('elec',params.anode_map{1,i}(j),'period',1000,'repeats',params.freq,'action','curcyc');
            
            cmd.seq(1) = struct('length',cmd_length2,'ampl',converted_elect_current2(j),'pol',1,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            cmd.seq(2) = struct('length',1,'ampl',converted_elect_current(j),'pol',1,'fs',0,'enable',0,'delay',delay,'ampSelect',1);
            
            cmd.seq(3) = struct('length',6,'ampl',0,'pol',0,'fs',0,'enable',0,'delay',0,'ampSelect',1);
            
            cmd.seq(4) = struct('length',cmd_length2,'ampl',converted_elect_current2(j),'pol',0,'fs',0,'enable',1,'delay',0,'ampSelect',1);
            cmd.seq(5) = struct('length',1,'ampl',converted_elect_current(j),'pol',0,'fs',0,'enable',0,'delay',delay,'ampSelect',1);
            
            cmd_combined = cat(2,cmd_combined,cmd);
            
        end
    end
    
end

end