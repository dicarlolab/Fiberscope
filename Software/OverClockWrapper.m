function [Res] = OverClockWrapper(numTTLS)
% depricated. use Mojo v3 with fixed number of triggers (10).
Res = 1;
return;

global g_overClock
comPort = getCOMmapping('dmdoverclock');
fprintf('Initializing Overclock Module...\n');

allComObjects = instrfind('Port',comPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_overClock.com = serial(comPort,'BaudRate',115200);
try
    fopen(g_overClock.com);
catch
    fprintf('Warning. Could not connect to overclocking module!\n');
    Res = false;
    return;
end
if ~strcmp(g_overClock.com.Status,'open')
    fprintf('Error communicating with controller\n');
    Res = false;
    return;
end
WaitSecs(1.5);

clearBuffer();

[Res,  response] = auxSendCommand(1, sprintf('%d',numTTLS), 'OK');
fclose(g_overClock.com);

if (~Res)
    return;
end
fprintf('Initialized overclocking module. Num TTLS: %d\n',response(1));
clear global g_overClock
Res = true;
return;


function [Res, parsedRespose] = auxSendCommand(command, strParameters, strExpectedResponse, waitPeriod)
global g_overClock
parsedRespose =[];
Res =false;
if isempty(g_overClock) || strcmp(g_overClock.com.Status,'closed')
    return;
end;
    clearBuffer();
if ~isempty(strParameters)
 fprintf(g_overClock.com, [sprintf('%02d %s',command,strParameters),10]);    
else
    fprintf(g_overClock.com, [sprintf('%02d',command),10]);
end
if ~exist('waitPeriod','var')
    waitPeriod = 1;
end
WaitSecs(waitPeriod);
if g_overClock.com.BytesAvailable > 0
    Dummy = fread(g_overClock.com, g_overClock.com.BytesAvailable);
else
    fprintf('Error communicating with controller\n');
    Res = false;
    return;
    
end
if isempty(strExpectedResponse)
    Res = char(Dummy');
    return;
end
if ~strncmpi(char(Dummy'),strExpectedResponse,length(strExpectedResponse))
    fprintf('Error communicating with controller (weird response: %s)\n',char(Dummy'));
    Res = false;
    return;
else
    %fprintf('Communication with device OK!\n');
end
if length(Dummy) > 5
  parsedRespose = str2num(char(Dummy(5:end)'));
end
Res = true;
return;


function clearBuffer()
global g_overClock
clear Dummy
if g_overClock.com.BytesAvailable > 0
    Dummy = fread(g_overClock.com, g_overClock.com.BytesAvailable);
end
