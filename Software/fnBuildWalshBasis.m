function basis = fnBuildWalshBasis(n, maxPatterns)
% Generate a 2D walsh basis 
% input: 
% n - size of the 2D basis (must be a power of two)
% output:
% basis: a 3D array, composed of individual basis functions (n,n,n^2)
%
% Shay Ohayon
% MIT 2014
% 
% Revision history
%
% 7/22/2014 - Version 0.1, based on Antonio's original code.

% check for cached...
if ~exist('maxPatterns','var')
    maxPatterns = 40000;
end

filename = sprintf('C:/cache/WalshBasisCache_%d_%d.mat',n,maxPatterns);
if exist(filename,'file')
    fprintf('Loading walsh basis from cache file %s...',filename);
    load(filename)
    fprintf('Done.\n');
else
    N = n^2;
    basis = fnWalsh(N,maxPatterns);
    save(filename,'basis','-v7.3');
end




function basis = fnWalsh(N,maxPatterns)
% H = walsh(N)
%  generate a sequency (Walsh) ordered Hadamard matrix of size N,
%  where N must be an integer power of 2.

% Version 1.1 - 20 Jun 2008
% Updated to use bin2dec rather than bi2de, so that the
% communication toolbox is no longer required.

% Check that N==2^k.
targN = N;
k = log2(N);
crop =  k-floor(k)>eps;
if crop
    N=(2^nextpow2(sqrt(N)))^2;
    fprintf('warning, N is no an integer power of 2. will crop down!\n');
end
n=sqrt(N);
% Generate the Hadamard matrix
H = hadamard(N,'int8');

% generate Gray code of size N.
graycode = [0;1];
while size(graycode,1) < N
  graycode = [kron([0;1], ones(size(graycode,1),1)), ...
              [graycode; flipud(graycode)]];
end

% Generate indices from bit-reversed Gray code.
seqord = bin2dec(fliplr(char(graycode+'0')))+1;
% This line does the same thing, but requires the communication toolbox
% seqord = bi2de(graycode)'+1;

% Reorder H.
H = H(seqord,:);


basis=reshape(H',n,n,n*n);
if (n*n > maxPatterns)
    basis=basis(:,:,1:maxPatterns);
end
if crop
    n=sqrt(targN);
    basis = basis(1:n,1:n,:);
end