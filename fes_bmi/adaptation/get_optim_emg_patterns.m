function [emg_patterns] = get_optim_emg_patterns(E2F,varargin)

% varargin = {lambda, targets};

% default params for lambda and targets:
lambda = [0 1];
r = 10; % radius
n_tgt = 8;
targets = zeros(n_tgt+1,2);
for tgt = 1:n_tgt
    targets(tgt+1,:) = [r*cos(2*pi*(tgt-1)/n_tgt) r*sin(2*pi()*(tgt-1)/n_tgt)];
end

% overwrite default with argin values:
if nargin > 1 lambda  = varargin{1}; end
if nargin > 2 targets = varargin{2}; end

%% Optimization options

n_tgt  = size(targets,1);
n_emgs = size(E2F.H,1);
init_emg_val = rand(n_tgt,n_emgs);

TolX     = 1e-9; %function search tolerance for EMG
TypicalX = 0.1*ones(size(init_emg_val));
TolFun   = 1e-9; %tolerance on cost function? not exactly sure what this should be

 fmin_options = optimoptions('fmincon','GradObj','on','Display','notify-detailed',...
                                        'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX,'MaxIter',10000);

% fmin_options = optimset('fmincon');
% fmin_options = optimset(fmin_options,'Algorithm','interior-point','GradObj','on','Display','notify-detailed',...
%     'TolX',TolX,'TolFun',TolFun,'TypicalX',TypicalX,'FunValCheck','on');

%emg bound:
emg_min = zeros(size(init_emg_val));
emg_max = ones( size(init_emg_val));

emg_patterns = fmincon(@(EMG) Force2EMG_costfun_nosig(EMG,targets,E2F,lambda),init_emg_val,[],[],[],[],emg_min,emg_max,[],fmin_options);
emg_patterns(1,:) = zeros(1,n_emgs); %overwrite the pattern for center target to all 0 EMG
emg_patterns(emg_patterns<0.01) = 0; %overwrite very low EMGs to 0