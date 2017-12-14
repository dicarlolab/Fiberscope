%M matrix need not be square, but N is.
function [N] = centerit(M, n, bias)

if nargin < 3, bias = 0; end

% N = zeros(n+4) + bias;
N = zeros(n) + bias;
[r c] = size(M);

if(mod(r,2) == 1)
    r = r + 1;
    M = [M;zeros(1,c)];
end

if(mod(c,2) == 1)
    c = c + 1;
    M = [M zeros(r,1)];
end


N(n/2 - r/2 +1 : n/2 +r/2 , n/2 - c/2 +1: n/2 +c/2 ) = M;
