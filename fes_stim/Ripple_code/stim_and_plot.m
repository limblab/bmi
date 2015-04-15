% Quick example script that allows for stimulation and visualization of 
% continuous data channels.
% stim_str = 'Elect=142,144,;TL=20.0,20.0,;Freq=50.0,50.0,;Dur=0.2,0.2,;Amp=560.0,0.0,;TD=10.0,0.0,;FS=0.0,0.0,;';
stim_str = 'Elect=4,6,;TL=20,20,;Freq=50,50,;Dur=0.1,0.1,;Amp=0.0,0.0,;TD=0.0,0.0,;FS=0.0,0.0,;';	
% clear any existing waveforms 
xippmex('spike', 4, 1);
xippmex('spike', 6, 1);
% do the stim
xippmex('stim', stim_str);
% wait for stim data
pause(1.0);
[count, ts, wfs] = xippmex('spike', 4, 1);
min_time = min(ts);
wfs_stim = xippmex('cont', 4, 1000, 1, min_time-3030);
wfs_settle = xippmex('cont', 6, 1000, 1, min_time-3030);
wfs_nosettle = xippmex('cont', 146, 1000, 1, min_time-3030);
t = (1:length(wfs_settle))/30;

figure(5);
clf;

subplot(3, 1, 1);
plot(t, wfs_settle);
subplot(3, 1, 2);
plot(t, wfs_stim(1:length(wfs_settle)));
subplot(3, 1, 3);
plot(t, wfs_nosettle);
linkaxes;
