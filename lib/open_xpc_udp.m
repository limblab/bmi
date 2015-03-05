function xpc = open_xpc_udp(params)
%% UDP port for XPC
if strcmpi(params.output,'xpc')
    XPC_IP   = '192.168.0.1';
    XPC_PORT = 24999;
    echoudp('on',XPC_PORT);
    xpc = udp(XPC_IP,XPC_PORT);
    set(xpc,'ByteOrder','littleEndian');
    set(xpc,'LocalHost','192.168.0.10');
    fopen(xpc);

%     XPC_PORT_WRITE = 24999;
%     echoudp('on',XPC_PORT_WRITE);
%     xpc.xpc_write = udp(XPC_IP,XPC_PORT_WRITE);
%     set(xpc.xpc_write,'ByteOrder','littleEndian');
%     set(xpc.xpc_write,'LocalHost','192.168.0.10');
%     fopen(xpc.xpc_write);
% 
%     XPC_PORT_READ = 24998;
%     xpc.xpc_read = udp(XPC_IP,XPC_PORT_READ);
%     set(xpc.xpc_read,'ByteOrder','littleEndian');
%     set(xpc.xpc_read,'LocalHost','192.168.0.10');
%     set(xpc.xpc_read,'LocalPort',24998);
%     set(xpc.xpc_read,'Timeout',.05);
%     set(xpc.xpc_read,'InputBufferSize',100);
%     set(xpc.xpc_read,'InputDatagramPacketSize',100);
%     set(xpc.xpc_read, 'ReadAsyncMode', 'continuous');
else
    xpc = [];
end