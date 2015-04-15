function ezstim(varargin)

stim_params = [];
if nargin stim_params = varargin{1}; end


stim_params = stim_params_defaults(stim_params);

stim_string = stim_params_to_string(stim_params);

xippmex('open');
repeat = true;

% 
% while repeat
%     tmr = tic;
%     
%     xippmex('stim',stim_string);
%     drawnow;
%     
%     elapsed_t = toc(tmr);
%     while elapsed_t < 1
%         elapsed_t = toc(tmr);
%     end
%     disp('stimulating!');
% end
xippmex('stim',stim_string)
%     
% stim_string           = [   'Elect = ' num2str(2) ',' num2str(4) ',' num2str(6) ',;' ...
%                             'TL = ' num2str(1000) ',' num2str(1000) ',' num2str(1000) ',; ' ...
%                             'Freq = ' num2str(60) ',' num2str(60) ',' num2str(60) ',; ' ...
%                             'Dur = ' num2str(0.2) ',' num2str(0.2) ',' num2str(0.2) ',; ' ...
%                             'Amp = ' num2str(127) ',' num2str(127) ',' num2str(127) ',; ' ...     
%                             'TD = ' num2str(0) ',' num2str(0) ',' num2str(0) ',; ' ...
%                             'FS = 0,0,0,; ' ...
%                             'PL = 0,0,0,;']; 

