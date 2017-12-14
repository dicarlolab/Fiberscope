% What is preferred? better quantization or more samples?
dynamicRange = 1000;  %say, 1000 mV range (+- 1V)
variance = 100;
bits = 5:16;
numSamples = 1:2:100;
stdError = zeros(length(bits),length(numSamples));
for bitIter= 1:length(bits)
    bitRange = bits(bitIter);
    for iter=1:length(numSamples)
        N = numSamples(iter);
        numRepeats = 1000;
        er=zeros(1,numRepeats);
        for k=1:numRepeats
            trueValue = 2*(rand()-0.5) *dynamicRange;
            noisyValues = trueValue + sqrt(variance)*randn(1,N);
            quantizedValues = round((noisyValues/dynamicRange) * 2^bitRange)/(2^bitRange)*dynamicRange;
            % now between -1 and 1
            er(k)=mean( abs(quantizedValues-trueValue));
        end
        stdError(bitIter,iter)=std(er);
    end
end
% figure(1);
% clf;
% imagesc(numSamples,bits,stdError);
% xlabel('Num Samples');
% ylabel('Bits');

figure;
clf;
plot(numSamples,stdError')

% figure(11);
% clf;
% hist(er,200)
% %set(gca,'xlim',[trueValue-30 trueValue+30]);
% std(er)
%mean(er)/trueValue*100
% scenario 1:
% 10 samples at 16 bit
