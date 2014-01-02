function wnew = gradient_descent_adapt(w, X, y, grad_func, lr)
%gradient_descent_adapt: runs gradient descent adaptation of the weight
%matrix w given the data x and feedback y.
% 'grad_func' % computes the gradient of the loss function with 
% respect to the weight matrix
%
% INPUTS:
%  - w         : weight matrix
%  - x         : data
%  - y         : feedback
%  - grad_func : function handler L/dw = grad(y, \hat{y}, w)
%  - lr        : learning rate

wnew = w - lr*grad_func(w, X, y);