function [Res, parsedResponse] = FilterWheelWrapper(strCommand, opt)
global g_wheelWrapper
parsedResponse = [];
Res = [];

if strcmpi(strCommand,'Init')
    comPort = getCOMmapping('FilterWheel');
    [Res, parsedResponse] = fnInit(comPort);
elseif strcmpi(strCommand,'IsInitialized')
    if isempty(g_wheelWrapper) || ~isfield(g_wheelWrapper,'initialized')
        Res = false;
    else
        Res = g_wheelWrapper.initialized;
    end
elseif strcmpi(strCommand,'SetFilterWheelPosition')
    if g_wheelWrapper.lastKnownPositions(opt(1)) == opt(2)
        fprintf('Not moving. Same position\n');
        Res = 1;
        return;
    else
        fprintf(['Sending Set filter command: ',num2str(opt),'\n']);
        Res = auxSendCommand(g_wheelWrapper.codes.CMD_SET_FILTER_POS, num2str(opt), 'OK!',0);
        if (Res)
            g_wheelWrapper.lastKnownPositions(opt(1)) = opt(2);
        end
    end
 elseif strcmpi(strCommand,'GetFilterWheelPosition')
     Res = 1;
     parsedResponse = g_wheelWrapper.lastKnownPositions(opt);
    %[Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_GET_FILTER_POS, [], 'OK!',0);
    
 elseif strcmpi(strCommand,'StepRight')
    [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_STEP_RIGHT, num2str(opt), 'OK!',0.5);
elseif strcmpi(strCommand,'StepLeft')
    [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_STEP_LEFT, num2str(opt), 'OK!',0.5);
elseif strcmpi(strCommand,'GetPositionName')
    motorIndex = opt(1);
    positionIndex = opt(2);
    Res = GetPositionName(motorIndex,positionIndex);
elseif strcmpi(strCommand,'ShutterON')
    % background compatible...
    if ~exist('opt','var')
        opt = 1;
    end
    [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_SHUTTER_ON, num2str(opt), 'OK!',0.5);
elseif strcmpi(strCommand,'GetShutterState')
    [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_GET_SHUTTER_STATE, [], 'OK!',0.5);
elseif strcmpi(strCommand,'ShutterOFF')
    if ~exist('opt','var')
        opt = 1;
    end
    [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_SHUTTER_OFF, num2str(opt), 'OK!',0.5);
elseif strcmpi(strCommand,'CalibrateWheel')
    [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_CALIBRATE_WHEEL, num2str(opt), 'OK!',0.5);
elseif strcmpi(strCommand,'SetNaturalDensity')
    motorIndex= opt(1);
    parsedResponse = NaturalDensityToWheelPosition(motorIndex,opt(2));
    Res = FilterWheelWrapper('SetFilterWheelPosition',[motorIndex, parsedResponse]);
elseif strcmpi(strCommand,'StartFastRotationMotor2')
    Res = auxSendCommand(g_wheelWrapper.codes.CMD_START_FAST_MOTOR2, num2str(opt), 'OK!',1);
elseif strcmpi(strCommand,'StopFastRotationMotor2')
    Res = auxSendCommand(g_wheelWrapper.codes.CMD_STOP_FAST_MOTOR2, num2str(opt), 'OK!',1);
 elseif strcmpi(strCommand,'Release')
     try
     [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_SHUTTER_ON, '1', 'OK!',0.5);
     [Res,parsedResponse] = auxSendCommand(g_wheelWrapper.codes.CMD_SHUTTER_ON, '2', 'OK!',0.5);
      
     if ~isempty(g_wheelWrapper)
        fclose(g_wheelWrapper.com);
     end
     catch
     end
     
     
    g_wheelWrapper.initialized = false;
    Res = true;   
end
    
        

function [Res, activeFilterPositions]=fnInit(strMotorPort)
global g_wheelWrapper
g_wheelWrapper.codes.CMD_GET = 01;
g_wheelWrapper.codes.CMD_GET_FILTER_POS = 1;
g_wheelWrapper.codes.CMD_SET_FILTER_POS = 2;
g_wheelWrapper.codes.CMD_STEP_LEFT = 3;
g_wheelWrapper.codes.CMD_STEP_RIGHT = 4;
g_wheelWrapper.codes.CMD_SHUTTER_ON = 6;
g_wheelWrapper.codes.CMD_SHUTTER_OFF = 7;
g_wheelWrapper.codes.CMD_GET_SHUTTER_STATE = 8;

g_wheelWrapper.codes.CMD_START_FAST_MOTOR2 = 10;
g_wheelWrapper.codes.CMD_STOP_FAST_MOTOR2 = 11;
g_wheelWrapper.lastKnownPosition = [];
fprintf('Initializing Filter Wheel Module...\n');

allComObjects = instrfind('Port',strMotorPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_wheelWrapper.com = serial(strMotorPort,'BaudRate',115200);
try
    fopen(g_wheelWrapper.com);
catch
    fprintf('Warning. Could not connect to filter wheel!\n');
    Res = false;
    activeFilterPositions = [];
    return;
end
if ~strcmp(g_wheelWrapper.com.Status,'open')
    fprintf('Error communicating with controller\n');
    Res = false;
    return;
    
end
WaitSecs(2);

clearBuffer();

[Res,  activeFilterPosition1] = auxSendCommand(g_wheelWrapper.codes.CMD_GET_FILTER_POS, '1', 'OK!');
if (~Res)
    return;
end
[Res,  activeFilterPosition2] = auxSendCommand(g_wheelWrapper.codes.CMD_GET_FILTER_POS, '2', 'OK!');
if (~Res)
    return;
end
activeFilterPositions = [activeFilterPosition1,activeFilterPosition2];
fprintf('Initialized Filter Wheel module. 473nm: %s, 532nm: %s\n',GetPositionName(1,activeFilterPosition1),GetPositionName(2,activeFilterPosition2));
g_wheelWrapper.lastKnownPositions = [activeFilterPosition1,activeFilterPosition2];

g_wheelWrapper.initialized = true;
Res = true;
return;







function [Res, parsedRespose] = auxSendCommand(command, strParameters, strExpectedResponse, waitPeriod)
global g_wheelWrapper
parsedRespose =[];
Res =false;
if isempty(g_wheelWrapper) || strcmp(g_wheelWrapper.com.Status,'closed')
    return;
end;
    clearBuffer();
    
if ~isempty(strParameters)
    strOut = [sprintf('%02d %s',command,strParameters),10];
else
    strOut = [sprintf('%02d',command),10];
end
 %fprintf('=>%s',strOut);
 fprintf(g_wheelWrapper.com, strOut);    
 
if ~exist('waitPeriod','var')
    waitPeriod = 0.5;
end
if waitPeriod > 0
    WaitSecs(waitPeriod);
else
    fprintf('Waiting for filter wheel to respond...');
    while g_wheelWrapper.com.BytesAvailable == 0
        WaitSecs(1);
    end
    fprintf('OK\n');
end
if g_wheelWrapper.com.BytesAvailable > 0
    Dummy = fread(g_wheelWrapper.com, g_wheelWrapper.com.BytesAvailable);
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

% if ~strncmpi(char(Dummy'),strExpectedResponse,length(strExpectedResponse))
%     fprintf('Error communicating with controller (weird response: %s)\n',char(Dummy'));
%     Res = false;
%     return;
% else
%     %fprintf('Communication with device OK!\n');
% end

if length(Dummy) > 5
  parsedRespose = str2num(char(Dummy(5:end)'));
end
Res = true;
return;


function clearBuffer()
global g_wheelWrapper
clear Dummy
if g_wheelWrapper.com.BytesAvailable > 0
    Dummy = fread(g_wheelWrapper.com, g_wheelWrapper.com.BytesAvailable);
end



function Res = GetPositionName(motorIndex,position)
% for now, assume both filter wheels are the same
position = mod(position,6);
switch position
    case 0
        Res = 'Natural Density 1';
    case 1
        Res = 'Natural Density 2';
    case 2
        Res = 'Natural Density 3';
    case 3
        Res = 'Natural Density 4';
    case 4
        Res = 'Natural Density 5';
    case 5
        Res = 'Empty';
    otherwise
        Res = [];
end
return;

function pos = NaturalDensityToWheelPosition(motorIndex,density)
% for now, assume both filter wheels are the same
switch density
    case 0
        pos = 5;
    case 1
        pos = 0;
    case 2
        pos = 1;
    case 3
        pos = 2;
    case 4
        pos = 3;
    case 5
        pos = 4;
end    