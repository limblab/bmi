function res = sigmoid(x,mode, varargin)
%piecewise sigmoid.
% f(x) = {  0         , x <=  0;
%          sig[0,1]   , 0 <x< 1;
%           1         , x >=  1;

bottom = 0;
top    = 1;
v50    = 0.5;
slope  = 10;

if nargin > 2
    p = varargin{1};
    bottom = p(1);
    top    = p(2);
    v50    = p(3);
    slope  = p(4);
end

% res = 1./(1+exp(-x));


switch mode
    case 'inverse'         
        %'inverse' (find x from f(x))
        res = v50 - log(-1+(top-bottom)./(x-bottom))/slope;
        res = round(10000*res)/10000;
        res = max(res,bottom);
        res = min(res,top);
    case 'direct'
        % normal, find y = f(x)
        res = bottom + (top-bottom)./(1+exp((v50-x).*slope));
        res = round(10000*res)/10000;
        res = min(res,top);
        idx_top = find(x>=top);
        res(idx_top) = top*ones(size(idx_top));
        idx_bot = find(x<=bottom);
        res(idx_bot) = zeros(size(idx_bot));
    case 'derivative'
        res = slope*(top-bottom).*exp(slope*(v50-x))./(exp(slope*(v50-x))+1).^2;
        idx_out = find(x<=bottom | x>=top);
        res(idx_out) = zeros(size(idx_out));
end

