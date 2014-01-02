function r = cbind(varargin)
% Column-wise binding matrices or row-wise vectors. All matrices must have
% same number of rows. Vectors are expanded to match number of rows of
% matrices

% Check that matrices have all the same number of rows or rows equal 1
matrix_sizes = cellfun(@(x)(size(x, 1)), varargin);
max_size = max(matrix_sizes);

% Check that all sizes are the same
if any(~ismember(matrix_sizes, [1 max_size]))
    error('Matrices must have all same number of rows or 1 row');
end

% Expand single matrices
expand_matrix_func = @(x)(expand_matrix(x, max_size));
r0_ = cellfun(expand_matrix_func, varargin, ...
    'UniformOutput', false);
r = horzcat(r0_{:});

end

function m = expand_matrix(m, max_size)
% Expand matrix to match max_size

if size(m, 1) ~= max_size
    m = repmat(m, max_size, 1);
end
end
