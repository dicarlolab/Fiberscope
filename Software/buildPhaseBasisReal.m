function phaseBasisReal=buildPhaseBasisReal(hadamardSize)
walshBasis = fnBuildWalshBasis(hadamardSize); % returns hadamardSize x hadamardSize x hadamardSize^2
% if get(handles.hFullFOV,'value')
%     walshBasisRotated =fnBuildWalshBasisRotated(dmd.hadamardSize, pi/4);
%     walshBasis = cat(3,walshBasis,walshBasisRotated);
%   
% end

numModes = size(walshBasis ,3);
% fprintf('Using %dx%d basis. Each uses %dx%d mirrors. Reference is %d pixels, which is %.3f of area\n',...
%     dmd.hadamardSize,dmd.hadamardSize,dmd.leeBlockSize,dmd.leeBlockSize,dmd.numReferencePixels, ...
%     (4*dmd.numReferencePixels*dmd.effectiveDMDsize-4*dmd.numReferencePixels*dmd.numReferencePixels)/(dmd.effectiveDMDsize*dmd.effectiveDMDsize));

phaseBasis = single((walshBasis == 1)*pi);
phaseBasisReal = single(reshape(real(exp(1i*phaseBasis)),hadamardSize*hadamardSize,numModes));


function basis = fnBuildWalshBasis(n)
N = n^2;
H = fnWalsh(N);
basis=reshape(H',n,n,n*n);

    
    


function H = fnWalsh(N)
% H = walsh(N)
%  generate a sequency (Walsh) ordered Hadamard matrix of size N,
%  where N must be an integer power of 2.

% Version 1.1 - 20 Jun 2008
% Updated to use bin2dec rather than bi2de, so that the
% communication toolbox is no longer required.

% Check that N==2^k.
k = log2(N);
if k-floor(k)>eps
  error('N must be an integer power of 2.');
end

% Generate the Hadamard matrix
H = hadamard(N);

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
    