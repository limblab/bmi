function update_vibration_motor_duty_cycles(handles,params,new_force)

    params.vibration_motors.min_duty_cycle = .5;
    params.vibration_motors.max_duty_cycle = .99;
    
    params.vibration_motors.min_force = 0;
    params.vibration_motors.max_force = 10;
    
    y_min = params.vibration_motors.min_duty_cycle;
    y_max = params.vibration_motors.max_duty_cycle;
    
    x_min = params.vibration_motors.min_force;
    x_max = params.vibration_motors.max_force;
    
    m = (y_max-y_min)/(x_max-x_min);
    b = y_min-m*x_min;
    
    new_duty_cycles = new_force*m+b;
    new_duty_cycles = max(min(new_duty_cycles,y_max),y_min);
    
    update_NIDAQ_outputs(handles,new_duty_cycles)
    
    
    
    