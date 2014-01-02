keep_running = msgbox('Click ''ok'' to stop the program');
pause(1); %make sure the window has time to open properly

t_buf = tic;
bin = 0;

tic;
while(ishandle(keep_running) && toc(t_buf)<=10 )
        bin = bin+1;
    
        et_buf = toc(t_buf); %elapsed buffering time
        
        disp(bin);
        
        % this actually pauses the program for ~15 ms, and ensure other
        % processes are accomplished.
        pause(0.001); 
        
end
