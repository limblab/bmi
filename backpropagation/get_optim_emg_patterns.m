function [emg_patterns] = get_optim_emg_patterns(E2F,lambda,varargin)

if nargin >2
    targets = varargin{1};
else
    r = 10; % radius
    n_tgt = 8;
    targets = zeros(n_tgt+1,2);
    for tgt = 1:n_tgt
        targets(tgt+1,:) = round([r*cos(2*pi*(tgt-1)/n_tgt) r*sin(2*pi()*(tgt-1)/n_tgt)]*1000)/1000;
    end
end        

%% Optimization options

n_tgt  = size(targets,1);
n_emgs = size(E2F.H,1);
init_emg_val = rand(n_tgt,n_emgs);

TolX     = 1e-9; %function search tolerance for EMG
TypicalX = 0.1*ones(size(init_emg_val));
TolFun   = 1e-9; %tolerance on cost function? not exactly sure what this should be

%  fmin_options = optimoptions('fmincon','GradObj','on','Display','notify-detailed',...
%                                         'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX);

fmin_options = optimset('fmincon');
fmin_options = optimset(fmin_options,'Algorithm','interior-point','GradObj','on','Display','notify-detailed',...
    'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX,'FunValCheck','on');

%emg bound:
emg_min = zeros(size(init_emg_val));
emg_max = ones( size(init_emg_val));

emg_patterns = fmincon(@(EMG) Force2EMG_costfun_sig(EMG,targets,E2F,lambda),init_emg_val,[],[],[],[],emg_min,emg_max,[],fmin_options);
emg_patterns(1,:) = zeros(1,n_emgs); %overwrite the pattern for center target to all 0 EMG