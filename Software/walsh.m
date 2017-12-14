function H = walsh(N)
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
