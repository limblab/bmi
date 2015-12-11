%
% Function to call get_pw_to_force, making it easy to assign parameters 
%
%   force = CALL_GET_PW_TO_FORCE( get_pw_f_params )
%
%

function force = call_get_pw_to_force( gpwfp )

% Assign electrodes in the stimulator, based on the selected muscle and
% monkey
switch gpwfp.monkey
    case 'Jango'
        switch gpwfp.muscle
            case 'EDCu'
                gpwfp.elec  = [1 3 5];
            case 'FCU'
                gpwfp.elec  = [7 9 11];
            case 'EDCr'
                gpwfp.elec  = [13 15 17];
            case 'ECU'
                gpwfp.elec  = [19 21 23];
            case 'ECRb'
                gpwfp.elec  = [2 4 6];
            case 'PL'
                gpwfp.elec  = [8 10 12];
            case 'ECRl'
                gpwfp.elec  = [25 27 29];
            case 'FDP'
                gpwfp.elec  = [14 16 18];
            case 'FCR'
                gpwfp.elec  = [20 22 24];
            otherwise
                error('wrong muscle name');
        end
    otherwise
        error('we do not have more monkeys at the moment');
end

% Fill missing parameters to defaults;
gpwfp           = get_pw_to_force_params_defaults( gpwfp );

% Run the code
force           = get_pw_to_force( gpwfp );

