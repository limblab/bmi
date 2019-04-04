This is backported from v6.04 so that Linux SDK/mex can be used agaisnt v6.03 release

Dependencies: Qt4 binaries (QtCore and QtXml)

Notes for Ubuntu8.04 (old distros): 
We need Qt 4.4 not available in old distros.
Best method to try (without the need to setup backport software channel) is to do use those attached .so files manually (I attached all that I thought you may need), 
place them beside you application and use ‘export LD_LIBRARY_PATH=.’ Before running your application built with cbsdk.
To test this method do this: ‘LD_LIBRARY_PATH=/path/to/new/qt/so/files  ldd /path/to/libcbsdkx64.so’ and it should show that those Qt libraries are resolved with the path you mentioned instead of system path in /usr/lib.
Similarly if you want to use MATLAB cbmex for example you should do something like ‘LD_LIBRARY_PATH=/path/to/new/qt/so/files  matlab.sh’ 
(i.e. set the variable then run matlab in the same line, or export then run matlab in two lines). 
To test this inside matlab use ‘getenv('LD_LIBRARY_PATH')’ to make sure it points (among other things) to the qt/so/files
here you may find more information:
http://www.mathworks.com/help/matlab/ref/matlabunix.html;jsessionid=fd475f58efec0b8d1e091bf9f3a1?nocookie=true

Notes on dependencies:
1- x64 version relies on x64 binaries
2- Qt4.8 is used which should be ABI compatible with Qt4
3- If library is not loaded by a Qt application, a fake Qt CoreApplication is created

Memory requirements:
1- Trial memory can be set manually
2- UDP socket receive memory should be increased: sysctl -w net.core.rmem_max=8388608
3- Qt by default uses $TMPDIR (or /tmp if not present) for shared memory, make sure the directory is mounted as tmpfs

Additional notes:
1- Analog output API could not be backported because of firmware incompatibility, thus is removed in this version
    In order to get the new Analog output (996 length waveform, firmware trigger mechanism) v6.04 is needed
2- Python extension is in pre-beta form thus not included.
3- cerebus lock files are crated in $TMPDIR (./tmp if not specified) and library will not run if the locks are not accessible to the user
4- port numbers 1001 and 1002 may require root permission (since v6.04 they are changed to 51001 and 51002)
    To work around root problem in v6.03, make sure sdk uses 51001 and 51002 and route ports:
     iptables -t nat -A PREROUTING -p udp --dport 51001 -j REDIRECT --to-port 1001
     iptables -t nat -A PREROUTING -p udp --dport 51002 -j REDIRECT --to-port 1002
    To delete above routing:
     iptables -t nat --line-numbers -n -L
     then
     iptables -t nat -D PREROUTING $num
5- If multiple processes need to connect to one NSP, the lock file is used to connect them to shared memory;
     for multiple NSPs, connections must be via different NICs and be re-routed using iptables commands; 
6- The same process can currently connect to at most 4 NSPs and API has changed since official 6.03

	
