function strctRun=parseScansFromSessionFile(sessionFile, scanIndices,options)
for k=1:length(scanIndices)
    strctRun(k)= parseScanFromSessionFile(sessionFile, scanIndices(k),options);
end
