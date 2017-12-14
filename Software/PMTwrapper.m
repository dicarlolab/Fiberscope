function [Res, parsedResponse] = PMTwrapper(strCommand, opt)
Res = 1;
parsedResponse = 1;
return;
global g_PMTwrapper
parsedResponse = [];
Res = [];
if ~exist('opt','var')
    opt = [];
end
if strcmpi(strCommand,'Init')
     comPort = getCOMmapping('pmt');
    [Res] = fnInit(comPort);
elseif strcmpi(strCommand,'IsInitialized')
    if isempty(g_PMTwrapper) || ~isfield(g_PMTwrapper,'initialized')
        Res = false;
    else
        Res = g_PMTwrapper.initialized;
    end
elseif  strcmpi(strCommand,'PMTon')
    [Res,parsedResponse] = auxSendCommand(g_PMTwrapper.codes.CMD_PMT_ON, num2str(opt), 'OK!',0);
elseif  strcmpi(strCommand,'PMToff')
    [Res,parsedResponse] = auxSendCommand(g_PMTwrapper.codes.CMD_PMT_OFF, num2str(opt), 'OK!',0);
elseif  strcmpi(strCommand,'RampGain')
    [Res,parsedResponse] = auxSendCommand(g_PMTwrapper.codes.CMD_RAMP_GAIN, num2str(opt), 'OK!',0);
elseif  strcmpi(strCommand,'GetGain')
    [Res,parsedResponse] = auxSendCommand(g_PMTwrapper.codes.CMD_GET_GAIN, num2str(opt), 'OK!',0);
elseif  strcmpi(strCommand,'GetGainNonBlocking')
    
         % time to send query...
        switch g_PMTwrapper.gainStateMachine
            case 0
                if (GetSecs() - g_PMTwrapper.lastTimeRead) > 0.3 % query every one second
                    g_PMTwrapper.gainStateMachine = 1;
                    clearBuffer();
                    strOut = [sprintf('%02d',g_PMTwrapper.codes.CMD_GET_GAIN),10];
                    fprintf(g_PMTwrapper.com, strOut);
                end
            case 1
                % has response arrived?
                if (GetSecs() - g_PMTwrapper.lastTimeRead) > 6 % it took too long?, try again?
                    fprintf('Timedout on response\n');
                    g_PMTwrapper.gainStateMachine = 0;
                    g_PMTwrapper.lastTimeRead = GetSecs();
                end
                if (GetSecs() - g_PMTwrapper.lastTimeRead) > 0.5 % allow 500 ms for response to fully arrive
                    if g_PMTwrapper.com.BytesAvailable > 0
                            Dummy = fread(g_PMTwrapper.com, g_PMTwrapper.com.BytesAvailable);
                            if length(Dummy) > 5
                                g_PMTwrapper.lastKnownGain = str2num(char(Dummy(5:end)'));
                            end
                    end
                    g_PMTwrapper.gainStateMachine = 0;
                    g_PMTwrapper.lastTimeRead = GetSecs();
                end
                
        end
        
        Res = 1;
        parsedResponse = g_PMTwrapper.lastKnownGain;
elseif  strcmpi(strCommand,'SetGain')
    [Res,parsedResponse] = auxSendCommand(g_PMTwrapper.codes.CMD_SET_GAIN, num2str(opt), 'OK!',0);

elseif strcmpi(strCommand,'Release')
    fprintf('Releasing PMT controller\n');
     try
     [Res,parsedResponse] = auxSendCommand(g_PMTwrapper.codes.CMD_PMT_OFF, [], 'OK!',1);
     if ~isempty(g_PMTwrapper)
        fclose(g_PMTwrapper.com);
     end
     catch
     end
    g_PMTwrapper.initialized = false;
    Res = true;   
end
    
        

function [Res]=fnInit(strPort)
global g_PMTwrapper
g_PMTwrapper.codes.CMD_SET_GAIN = 1;
g_PMTwrapper.codes.CMD_GET_GAIN = 2;
g_PMTwrapper.codes.CMD_PMT_ON = 3;
g_PMTwrapper.codes.CMD_PMT_OFF = 4;
g_PMTwrapper.codes.CMD_RAMP_GAIN = 5;
g_PMTwrapper.codes.CMD_INIT = 6;
g_PMTwrapper.lastKnownPosition = [];
g_PMTwrapper.lastTimeRead = GetSecs();
g_PMTwrapper.lastKnownGain = 0;
g_PMTwrapper.gainStateMachine = 0;
fprintf('Initializing PMT controller Module...\n');

allComObjects = instrfind('Port',strPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_PMTwrapper.com = serial(strPort,'BaudRate',115200);
try
    fopen(g_PMTwrapper.com);
catch
    fprintf('Warning. Could not connect to PMT controller!\n');
    Res = false;
    return;
end
if ~strcmp(g_PMTwrapper.com.Status,'open')
    fprintf('Error communicating with controller\n');
    Res = false;
    return;
    
end
WaitSecs(2);

clearBuffer();

Res = auxSendCommand(g_PMTwrapper.codes.CMD_INIT, [], 'OK!',0);

g_PMTwrapper.initialized = Res == true;

return;



function [Res, parsedRespose] = auxSendCommand(command, strParameters, strExpectedResponse, waitPeriod)
global g_PMTwrapper
parsedRespose =[];
Res =false;
if isempty(g_PMTwrapper) || strcmp(g_PMTwrapper.com.Status,'closed')
    return;
end;
    clearBuffer();
    
if ~isempty(strParameters)
    strOut = [sprintf('%02d %s',command,strParameters),10];
else
    strOut = [sprintf('%02d',command),10];
end
% fprintf('=>%s',strOut);
 fprintf(g_PMTwrapper.com, strOut);    
 
if ~exist('waitPeriod','var')
    waitPeriod = 0.5;
end
if waitPeriod > 0
    A=GetSecs();
    while GetSecs()-A < waitPeriod
        if g_PMTwrapper.com.BytesAvailable > 0
            WaitSecs(0.1);
            break;
        end
    end
    
else
    fprintf('Waiting for PMT controller to respond...');
    while g_PMTwrapper.com.BytesAvailable == 0
        WaitSecs(0.3);
    end
    fprintf('OK\n');
end
if g_PMTwrapper.com.BytesAvailable > 0
    Dummy = fread(g_PMTwrapper.com, g_PMTwrapper.com.BytesAvailable);
else
    fprintf('Error communicating with controller\n');
    Res = false;
    return;
    
end
% fprintf('<=%s',char(Dummy'));
if isempty(strExpectedResponse)
    Res = char(Dummy');
    return;
end


if length(Dummy) > 5
  parsedRespose = str2num(char(Dummy(5:end)'));
end
Res = true;
return;


function clearBuffer()
global g_PMTwrapper
clear Dummy
if g_PMTwrapper.com.BytesAvailable > 0
    Dummy = fread(g_PMTwrapper.com, g_PMTwrapper.com.BytesAvailable);
end

