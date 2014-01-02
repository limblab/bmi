function [t, mat] = send_receive(t)

[t, mat] = fread_matrix(t);
%receive_ack(t);
%send_ack(t);
%mat = 0;
fwrite_matrix(t, mat);