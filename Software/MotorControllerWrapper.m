function [Res, parsedResponse] = MotorControllerWrapper(strCommand, opt)
if ~exist('opt','var')
    opt = [];
end
% [Res, parsedResponse] = ThorlabsStageControllerWrapper(strCommand, opt);
% return;

global g_motorWrapper


parsedResponse = [];

if strcmpi(strCommand,'Init')
    comPort = getCOMmapping('Zstage');
    [Res, parsedResponse] = fnMotorInit(comPort);
    return;
elseif strcmpi(strCommand,'StorePosition')
    Res = auxSendCommand(g_motorWrapper.codes.CMD_STORE_POS, [], 'OK!',0);
    return;       
elseif strcmpi(strCommand,'RecallPosition')
    Res = auxSendCommand(g_motorWrapper.codes.CMD_RECALL_POS, [], 'OK!',0);
    return;       
elseif strcmpi(strCommand,'ResetRelative')
    [~,g_motorWrapper.relativePosition] = MotorControllerWrapper('GetPositionMicrons');
elseif strcmpi(strCommand,'GetRelativePosition')
    Res = true;
    parsedResponse = g_motorWrapper.relativePosition;
elseif strcmpi(strCommand,'StepDown')
  [Res,parsedResponse] = auxSendCommand(g_motorWrapper.codes.CMD_STEP_DOWN, [], 'OK!',0);
elseif strcmpi(strCommand,'StepUp')    
    [Res,parsedResponse]= auxSendCommand(g_motorWrapper.codes.CMD_STEP_UP, [], 'OK!',0);
elseif strcmpi(strCommand,'GetMinStepSizeMicrons')    
    [Res,parsedResponse]= auxSendCommand(g_motorWrapper.codes.CMD_GET_MIN_STEP_SIZE_MICRONS, [], 'OK!');
elseif strcmpi(strCommand,'IsInitialized')
    if isempty(g_motorWrapper) || ~isfield(g_motorWrapper,'initialized')
        Res = false;
    else
        Res = g_motorWrapper.initialized;
    end
    
    return;    
elseif strcmpi(strCommand,'Release')
    fprintf('Releasing Motor resource\n');
    auxSendCommand(g_motorWrapper.codes.CMD_ENABLE_POTENTIOMETER, [], 'OK!');
    if ~isempty(g_motorWrapper)
        fclose(g_motorWrapper.com);
    end
    g_motorWrapper.initialized = false;
    Res = true;
    return;
elseif strcmpi(strCommand,'SetStepSize')
    g_motorWrapper.stepSize = opt;
    Res = auxSendCommand(g_motorWrapper.codes.CMD_SET_STEP_SIZE, num2str(opt), 'OK!',0);
    return;
elseif strcmpi(strCommand,'ResetScreen')
    Res = auxSendCommand(g_motorWrapper.codes.CMD_RESET_SCREEN, [], 'OK!');
    return;
elseif strcmpi(strCommand,'SetSpeed')
    g_motorWrapper.speed = opt;
    Res = auxSendCommand(g_motorWrapper.codes.CMD_SET_SPEED, num2str(opt), 'OK!');
    return;    
elseif strcmpi(strCommand,'SetAbsolutePositionMicrons')
    Res = auxSendCommand(g_motorWrapper.codes.CMD_SET_ABSOLUTE_POS_MICRONS, num2str(opt), 'OK!',0);
    return;   
elseif strcmpi(strCommand,'SetRelativePositionMicrons')
    Res = auxSendCommand(g_motorWrapper.codes.CMD_SET_RELATIVE_POS_MICRONS, num2str(opt), 'OK!',0);
    return;    
elseif strcmpi(strCommand,'SetRelativePositionSteps')
    Res = auxSendCommand(g_motorWrapper.codes.CMD_SET_RELATIVE_POS_STEPS, num2str(opt), 'OK!',0);
    return;       
elseif strcmpi(strCommand,'SetAbsolutePositionSteps')
    Res = auxSendCommand(g_motorWrapper.codes.CMD_SET_ABSOLUTE_POS_STEPS, num2str(opt), 'OK!',0);
    return;    
elseif  strcmpi(strCommand,'GetPositionMicronsNonBlocking')
         % time to send query...
        switch g_motorWrapper.posStateMachine
            case 0
                if (GetSecs() - g_motorWrapper.lastTimeRead) > 0.5 
                    g_motorWrapper.posStateMachine = 1;
                    clearBuffer();
                    fprintf(g_motorWrapper.com, [sprintf('%02d',g_motorWrapper.codes.CMD_GET_POSITION_MICRONS),10]);
                end
            case 1
                % has response arrived?
                if (GetSecs() - g_motorWrapper.lastTimeRead) > 6 % it took too long?, try again?
                    fprintf('Timedout on response\n');
                    g_motorWrapper.posStateMachine = 0;
                    g_motorWrapper.lastTimeRead = GetSecs();
                end
                if (GetSecs() - g_motorWrapper.lastTimeRead) > 0.5 % allow 500 ms for response to fully arrive
                    if g_motorWrapper.com.BytesAvailable > 0
                            Dummy = fread(g_motorWrapper.com, g_motorWrapper.com.BytesAvailable);
                            if length(Dummy) > 5
                                g_motorWrapper.lastKnownPos = str2num(char(Dummy(5:end)'));
                            end
                    end
                    g_motorWrapper.posStateMachine = 0;
                    g_motorWrapper.lastTimeRead = GetSecs();
                end
                
        end
        
        Res = 1;
        parsedResponse = g_motorWrapper.lastKnownPos;       
elseif strcmpi(strCommand,'GetPositionMicrons')
    [Res,parsedResponse]= auxSendCommand(g_motorWrapper.codes.CMD_GET_POSITION_MICRONS, [], 'OK!',0);
    return;
elseif strcmpi(strCommand,'GetStepSizeMicrons')
   [Res,parsedResponse]= auxSendCommand(g_motorWrapper.codes.CMD_GET_STEP_SIZE, [], 'OK!',0);
    return;    
elseif strcmpi(strCommand,'GetPositionSteps')
  [Res,parsedResponse]= auxSendCommand(g_motorWrapper.codes.CMD_GET_POSITION_STEPS, [], 'OK!',0);
    return;    
elseif strcmpi(strCommand,'GetSpeed')
[Res,parsedResponse]= auxSendCommand(g_motorWrapper.codes.CMD_GET_SPEED, [], 'OK!',0);    
return;
elseif strcmpi(strCommand,'ResetPosition')
     Res = auxSendCommand(g_motorWrapper.codes.CMD_RESET_POSITION, [], 'OK!');
    return;
else
    fprintf('Unknown command!\n');
end

return;


function [Res, MinStepSize]=fnMotorInit(strMotorPort)
global g_motorWrapper
MinStepSize = NaN;
g_motorWrapper.codes.CMD_GET_POSITION_MICRONS = 1;
g_motorWrapper.codes.CMD_SET_ABSOLUTE_POS_MICRONS = 2;
g_motorWrapper.codes.CMD_SET_RELATIVE_POS_MICRONS = 3;
g_motorWrapper.codes.CMD_STEP_DOWN = 4;
g_motorWrapper.codes.CMD_STEP_UP = 5;
g_motorWrapper.codes.CMD_SET_STEP_SIZE = 6;
g_motorWrapper.codes.CMD_SET_SPEED = 7;
g_motorWrapper.codes.CMD_DISABLE_POTENTIOMETER = 8;
g_motorWrapper.codes.CMD_ENABLE_POTENTIOMETER = 9;
g_motorWrapper.codes.CMD_RESET_POSITION = 10;
g_motorWrapper.codes.CMD_RESET_SCREEN = 11;
g_motorWrapper.codes.CMD_PING = 12;
g_motorWrapper.codes.CMD_GET_STEP_SIZE = 13;
g_motorWrapper.codes.CMD_GET_SPEED = 14;
g_motorWrapper.codes.CMD_GET_POSITION_STEPS = 15;
g_motorWrapper.codes.CMD_SET_ABSOLUTE_POS_STEPS = 16;
g_motorWrapper.codes.CMD_SET_RELATIVE_POS_STEPS = 17;
g_motorWrapper.codes.CMD_GET_MIN_STEP_SIZE_MICRONS = 18;
g_motorWrapper.codes.CMD_STORE_POS = 19; 
g_motorWrapper.codes.CMD_RECALL_POS = 20; 

g_motorWrapper.posStateMachine = 0;
g_motorWrapper.lastKnownPos = [];
g_motorWrapper.lastTimeRead = GetSecs();



fprintf('Initializing Motor Module...\n');

allComObjects = instrfind('Port',strMotorPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_motorWrapper.com = serial(strMotorPort,'BaudRate',115200);
try
    fopen(g_motorWrapper.com);
catch
    fprintf('Warning. Could not connect to Z stage module!\n');
    Res = false;
    return;
end
if ~strcmp(g_motorWrapper.com.Status,'open')
    printError();
    Res = false;
    return;
    
end
WaitSecs(3);
clearBuffer();
% Res = auxSendCommand(g_motorWrapper.codes.CMD_PING, [], 'OK!',0);
% if (~Res)
%     return;
% end

Res = auxSendCommand(g_motorWrapper.codes.CMD_DISABLE_POTENTIOMETER, [], 'OK!',0);
if (~Res)
    return;
end


[Res,MinStepSize]= auxSendCommand(g_motorWrapper.codes.CMD_GET_MIN_STEP_SIZE_MICRONS, [], 'OK!',0);
if (~Res)
    return;
end

g_motorWrapper.stepSize = MinStepSize;
 
Res = auxSendCommand(g_motorWrapper.codes.CMD_SET_STEP_SIZE, num2str(MinStepSize), 'OK!',0);
if (~Res)
    return;
end

g_motorWrapper.codes.CMD_GET_SPEED = 14;

[Res, speed] = auxSendCommand(g_motorWrapper.codes.CMD_GET_SPEED ,[], 'OK!',0);
if (~Res)
    return;
end

g_motorWrapper.speed = speed;

% 
% g_motorWrapper.codes.CMD_RESET_SCREEN = 11;
% Res = auxSendCommand(g_motorWrapper.codes.CMD_RESET_SCREEN, [], 'OK!',1.5);
% if (~Res)
%     return;
% end

[~,g_motorWrapper.relativePosition] = MotorControllerWrapper('GetPositionMicrons');

g_motorWrapper.initialized = true;
Res = true;
return;


function [Res, parsedRespose] = auxSendCommand(command, strParameters, strExpectedResponse, waitPeriod)
global g_motorWrapper
parsedRespose =[];
if isempty(g_motorWrapper) || strcmp(g_motorWrapper.com.Status,'closed')
    return;
end;
    clearBuffer();
if ~isempty(strParameters)
 fprintf(g_motorWrapper.com, [sprintf('%02d %s',command,strParameters),10]);    
else
    try
        fprintf(g_motorWrapper.com, [sprintf('%02d',command),10]);
    catch
    printError();
    Res = false;
        
    end
    
end
if ~exist('waitPeriod','var')
    waitPeriod = 0.9;
end
if waitPeriod > 0
    WaitSecs(waitPeriod);
else
    fprintf('Waiting for motor controller to respond...');
    while g_motorWrapper.com.BytesAvailable == 0
        WaitSecs(0.2);
    end
    fprintf('OK\n');
end

if g_motorWrapper.com.BytesAvailable > 0
    Dummy = fread(g_motorWrapper.com, g_motorWrapper.com.BytesAvailable);
else
    printError();
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
global g_motorWrapper
% clear buffer.

clear Dummy
if g_motorWrapper.com.BytesAvailable > 0
    Dummy = fread(g_motorWrapper.com, g_motorWrapper.com.BytesAvailable);
end

function printError()
fprintf('Error communicating with controller\n');