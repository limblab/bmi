% Create matlab server
if exist('t', 'var')
    fclose(t);
    delete(t);
    clear('t');
end
t = tcpip('127.0.0.1', 8000, 'NetworkRole', 'server');
%t.Timeout = 30;
%t.OutputBufferSize = 1024;
%t.InputBufferSize = 1024;
% Open connection
fopen(t);
disp('Client connected...');
% Send number of neurons to use

fwrite_matrix(t, [
send_ack(t);
%mat = rand(10);
while true
    %pause(1);
    mat = fread_matrix(t);
    
    %pause(0.05);
    %disp(mat);
    fwrite_matrix(t, mat);
end

fclose(t);
%fclose(t);