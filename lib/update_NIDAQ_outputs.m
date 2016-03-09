function update_NIDAQ_outputs(handles,new_duty_cycles)

for iOutput = 1:length(handles.NIDAQ.session.Channels)
    ch = handles.NIDAQ.session.Channels(iOutput);
    ch.DutyCycle = new_duty_cycles(iOutput);
end