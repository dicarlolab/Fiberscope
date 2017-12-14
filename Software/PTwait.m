function PTwait(N)
fprintf('Waiting for %d...',N);
pX = 0;
while PTwrapper('GetBufferSize') < N
    X=PTwrapper('GetBufferSize');
    if X > pX + 1
        pX = X;
        fprintf('%d ',X);
    end
end
fprintf('Done!\n');