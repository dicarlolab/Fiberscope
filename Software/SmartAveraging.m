function strctAverage = SmartAveraging(varargin)
strCommand = varargin{1};
if strcmpi(strCommand,'Init')
    dataSize = varargin{2};
    strctAverage.numSamplesToAverage = varargin{3};
    strctAverage.numDim = length(dataSize);
    if strctAverage.numSamplesToAverage == 0
        strctAverage.data = zeros(dataSize);
    else
        strctAverage.data = zeros([dataSize,strctAverage.numSamplesToAverage]);
        
    end
    
    strctAverage.avgdata = zeros(dataSize);
    strctAverage.stddata  = zeros(dataSize);
    strctAverage.lastdata = zeros(dataSize);
    strctAverage.Mk = zeros(dataSize);
    strctAverage.Sk = zeros(dataSize);
    strctAverage.counter = 0;
 elseif strcmpi(strCommand,'AddSamples')
    strctAverage =  varargin{2};
    incomingData = varargin{3};
    
    d = strctAverage.numDim;
    numSamples = size(incomingData,d+1);
    if numSamples == 1
        % happens when the last dimension collapses...
        indices = repmat({':'}, 1, d+1);
        lastSlice = repmat({':'}, 1, d);
        strctAverage.lastdata = incomingData(lastSlice{:}); %incomingData(:,end);
    else
        indices = repmat({':'}, 1, d+1);
        indices{d+1} = numSamples;
        strctAverage.lastdata = incomingData(indices{:}); %incomingData(:,end);
    end
    % create cell array with indexes for each dimension
    
    
    if strctAverage.numSamplesToAverage == 0
        for sampleIter=1:numSamples
          if (numSamples == 1)
                dataSlice = strctAverage.lastdata;
          else
              indices{d+1} = sampleIter;
              dataSlice =  incomingData(indices{:}); %incomingData(:,end);
          end
            % continuous averaging
            strctAverage.counter = strctAverage.counter + 1;
            strctAverage.avgdata = (strctAverage.avgdata * (strctAverage.counter-1) + dataSlice)/strctAverage.counter;
            if (strctAverage.counter == 1)
                strctAverage.Mk =dataSlice ;
            else
                oldMk = strctAverage.Mk;
                strctAverage.Mk = oldMk + (dataSlice - oldMk) / strctAverage.counter;
                strctAverage.Sk = strctAverage.Sk + (dataSlice - oldMk) .* (dataSlice -strctAverage.Mk);
                strctAverage.stddata = sqrt(strctAverage.Sk/(strctAverage.counter-1)); % NaN for first iteration...
            end
        end
    else
        % TODO, remove one sample, add one sample. This will be faster....
        
        for sampleIter=1:numSamples
            
           indices{d+1} = sampleIter;
           dataSlice = incomingData(indices{:}); %incomingData(:,end);
           indx = 1+mod(strctAverage.counter,strctAverage.numSamplesToAverage);
           indices{d+1} = indx;
           strctAverage.data(indices{:}) =  dataSlice;
           strctAverage.counter = strctAverage.counter + 1;
        end
        
        if strctAverage.counter < strctAverage.numSamplesToAverage
            indices{d+1} = 1:indx;
            strctAverage.avgdata = mean(strctAverage.data(indices{:}),d+1);    
            strctAverage.stddata = std(strctAverage.data(indices{:}),[],d+1);
        else
            strctAverage.avgdata = mean(strctAverage.data,d+1);    
            strctAverage.stddata = std(strctAverage.data,[],d+1);
        end
    end  
end
return