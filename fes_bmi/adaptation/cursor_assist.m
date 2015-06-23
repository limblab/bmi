function [cursor_pos,data] = cursor_assist(data,cursor_pos,cursor_traj)
 % cursor is moved towards outer target automatically if effort is detected.
 % full target trajectory if ave_fr reaches 1.25x baseline value.
 
 current_ave_fr = mean(data.spikes(1,:));
 
 if isnan(data.tgt_id) || isnan(data.tgt_on)
     % tgt not on yet, already completed back path, or next trial has started already
     % make the cursor move around zero
     cursor_pos = max([-1 -1],min([1 1],cursor_pos + 0.5*rand(1,2) - 0.25));
     return;
 end
 
 if data.tgt_on && data.tgt_id % outer target on
     if ~data.effort_flag && current_ave_fr >= 1.25*data.ave_fr
         data.effort_flag = true;
%          fprintf('Effort Detected');
     end
     if data.effort_flag
         %increase trajectory by increments of 4% (25 bins to complete traj)
         cursor_pos = cursor_traj.mean_paths(data.traj_pct+1,:,data.tgt_id);
         data.traj_pct = min(100,data.traj_pct+4);
     else
         %tgt on , but no effort detected yet, move around zeros, within center target
         cursor_pos = max([-1 -1],min([1 1],cursor_pos + 0.5*rand(1,2) - 0.25));
     end
 elseif data.traj_pct && data.tgt_id
     %tgt off but not back to center yet
     cursor_pos = cursor_traj.back_paths(101-data.traj_pct,:,data.tgt_id);
     data.traj_pct = max(0,data.traj_pct-4);
 else
     % tgt not on yet, already completed back path, or next trial has started already
     % make the cursor move around zero
     cursor_pos = max([-1 -1],min([1 1],cursor_pos + 0.5*rand(1,2) - 0.25));
 end

 
% % cursor is moved towards outer target proportionally with ave fr.
% % maximum displacement is reached at new_ave_fr = 1.3*ave_fr;
%
% pct_effort = (new_ave_fr-ave_fr)/ave_fr/0.3;
% if data.tgt_id
%  cursor_pos = pct_effort*data.tgt_pos;
% else
%  % tgt not on yet or next trial has started already
%  % make the cursor move around zero
%  cursor_pos = max([-1 -1],min([1 1],cursor_pos + 0.5*rand(1,2) - 0.25));
% end