%
% Characterize the PW to force relationship. Data should follow the force
% structure defined in get_pw_to_force
%
%   PW_TO_FORCE( force )
%
%

function pw_to_force( force )


% find indexes of the responses, grouped by PW

find(force.data(:,1)>force.t_sync_pulses(1),1)
