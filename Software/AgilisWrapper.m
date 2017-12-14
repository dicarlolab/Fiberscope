function [Res, parsedResponse] = AgilisWrapper(strCommand, opt)
% AgilisWrapper('IsInitialized')
% AgilisWrapper('Init')
% AgilisWrapper('SetStepSize',50)
% AgilisWrapper('SetStepSize',-50)
% AgilisWrapper('ZeroPosition')
% [~,pos]=AgilisWrapper('GetPosition')
% AgilisWrapper('RelativeMove',-3200)
% AgilisWrapper('MoveToLimit',1)
% AgilisWrapper('MoveToLimit',2)
% AgilisWrapper('SetStepDelay',20) % 20*10us = 200 usec delay after each
% step
% AgilisWrapper('Release')
global g_agilisWrapper
parsedResponse = [];
Res = [];
if ~exist('opt','var')
    opt = [];
end
if strcmpi(strCommand,'Init')
     comPort = getCOMmapping('agilis');

    [Res] = fnInit(comPort);
elseif strcmpi(strCommand,'IsInitialized')
    if isempty(g_agilisWrapper) || ~isfield(g_agilisWrapper,'initialized')
        Res = false;
    else
        Res = g_agilisWrapper.initialized;
    end
elseif  strcmpi(strCommand,'SetCorrectionFactor')
    g_agilisWrapper.stepCorrectionFactor = opt;
    g_agilisWrapper.stepSizeUmNeg = -0.48844;
    g_agilisWrapper.stepSizeUmPos = 0.48844 * g_agilisWrapper.stepCorrectionFactor;
    g_agilisWrapper.numPosSteps = 0;
    g_agilisWrapper.numNegSteps = 0;
elseif  strcmpi(strCommand,'PCmode')
    fprintf('Agilis in PC Mode\n');
    [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_ENABLE_PC_MODE,[], [],[],[]);
elseif  strcmpi(strCommand,'ManualMode')
    fprintf('Agilis in Manual Mode\n');
    [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_ENABLE_MANUAL_MODE, [],[],[],[]);
elseif  strcmpi(strCommand,'SetStepSize')
    if opt > 0
        [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_SET_STEP_SIZE, '1',num2str(opt), [],[]);
    else
        [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_SET_STEP_SIZE, '1',[num2str(-opt),'-'], [],[]);
    end
elseif  strcmpi(strCommand,'RelativeMove')
    if opt > 0
        g_agilisWrapper.numPosSteps =g_agilisWrapper.numPosSteps + opt;
    else
        g_agilisWrapper.numNegSteps =g_agilisWrapper.numNegSteps + -opt;
    end
    
    [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_RELATIVE_MOVE, '1',num2str(opt), [],[]);
elseif  strcmpi(strCommand,'RelativeMoveUm')
    if opt > 0
        numSteps = round(opt / g_agilisWrapper.stepSizeUmPos);
    else
        numSteps = round(opt / -g_agilisWrapper.stepSizeUmNeg);
    end
    [Res,parsedResponse] = AgilisWrapper('RelativeMove',numSteps);
    WaitUntilResponse('1TS','1TS0',0.1); % block until movement is finished...
    
elseif strcmpi(strCommand,'MoveToPositionUm')
    destinationUm = opt;
    currentPositionUm = g_agilisWrapper.numPosSteps * g_agilisWrapper.stepSizeUmPos +  ...
                        g_agilisWrapper.numNegSteps * g_agilisWrapper.stepSizeUmNeg;
                    
    if destinationUm > currentPositionUm
        % move in positive direction
        destinationNumSteps = round((destinationUm-currentPositionUm) /g_agilisWrapper.stepSizeUmPos);
    else
        % move in negative direction
        destinationNumSteps = round((currentPositionUm-destinationUm) /g_agilisWrapper.stepSizeUmNeg);
    end
    [Res,parsedResponse] = AgilisWrapper('RelativeMove',destinationNumSteps);
    WaitUntilResponse('1TS','1TS0',0.1); % block until movement is finished...
elseif  strcmpi(strCommand,'ZeroPosition')
    g_agilisWrapper.numPosSteps = 0;
    g_agilisWrapper.numNegSteps = 0;
    [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_ZERO_POSITION, '1',[],[],[]);
elseif strcmpi(strCommand,'GetPosition')
    [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_QUERY_POSITION, '1',[],'1TP',0);
 elseif strcmpi(strCommand,'GetPositionUm')
        Res = g_agilisWrapper.numPosSteps * g_agilisWrapper.stepSizeUmPos +  ...
                        g_agilisWrapper.numNegSteps * g_agilisWrapper.stepSizeUmNeg;

   
elseif strcmpi(strCommand,'SetStepDelay')
    [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_SET_STEP_DELAY, '1',num2str(opt),[],[]);
    
elseif strcmpi(strCommand,'MoveToLimit')
    [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_MOVE_TO_LIMIT, '1',num2str(opt),[],[]);
elseif strcmpi(strCommand,'GetStepSizeUm')
     Res = 0.51;
elseif strcmpi(strCommand,'WaitForMotionToEnd')     
    WaitUntilResponse('1TS','1TS0',0.5);

elseif strcmpi(strCommand,'CalibrateStepSize')
    [stepSizeUmNeg,numStepsNeg]=CalibrateNegativeDirection();
    [stepSizeUmPos,numStepsPos]=CalibratePositiveDirection();
    
    g_agilisWrapper.stepSizeUmNeg = stepSizeUmNeg;
    g_agilisWrapper.stepSizeUmPos = stepSizeUmPos ;
    g_agilisWrapper.numPosSteps = 0;
    g_agilisWrapper.numNegSteps = 0;
    fprintf('Num Positive Steps: %d, Step Size: %.6f\n',numStepsPos,stepSizeUmPos);
    fprintf('Num Negative Steps: %d, Step Size: %.6f\n',numStepsNeg,stepSizeUmNeg);
elseif strcmpi(strCommand,'Release')
    fprintf('Releasing Agilis controller\n');
     try
     [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_ENABLE_MANUAL_MODE, [], [],[],[]);
     if ~isempty(g_agilisWrapper)
        fclose(g_agilisWrapper.com);
     end
     catch
     end
    g_agilisWrapper.initialized = false;
    Res = true;   
end
return

    
function [stepSizeUm,numSteps]=CalibratePositiveDirection()
global g_agilisWrapper
fprintf(g_agilisWrapper.com, [sprintf('1PR100'),13,10]);     % 1PR100 Move 100 steps. Needed to move out of the limit.
WaitSecs(0.5);
fprintf(g_agilisWrapper.com, [sprintf('1MV-3'),13,10]);     % 1MV-3 Move to the negative limit.
WaitUntilResponse('PH','PH1',1);
fprintf(g_agilisWrapper.com, [sprintf('1SU50'),13,10]);     % value of step amplitude you want to use.
fprintf(g_agilisWrapper.com, [sprintf('1ZP'),13,10]);     % 1ZP Reset step counter to zero.
fprintf(g_agilisWrapper.com, [sprintf('1PR100'),13,10]);     % 1PR100 Move 100 steps. Needed to move out of the limit.
WaitSecs(0.5);
fprintf(g_agilisWrapper.com, [sprintf('1MV4'),13,10]);     % MV4 Move to positive limit and stop.
WaitUntilResponse('PH','PH1',1);
fprintf(g_agilisWrapper.com, [sprintf('1TP?'),13,10]);     % Tell number of steps.
WaitSecs(0.5);
res = char(fread(g_agilisWrapper.com, g_agilisWrapper.com.BytesAvailable)');
numSteps = str2num(res(4:end))+100;
distanceTravelledUm = 12000;
stepSizeUm = distanceTravelledUm/numSteps;
return;


function [stepSizeUm,numSteps]=CalibrateNegativeDirection()
global g_agilisWrapper
fprintf(g_agilisWrapper.com, [sprintf('1PR100'),13,10]);     % 1PR100 Move 100 steps. Needed to move out of the limit.
WaitSecs(0.5);
fprintf(g_agilisWrapper.com, [sprintf('1MV4'),13,10]);     % 1MV4 Move to the positive limit.
WaitUntilResponse('PH','PH1',1);
fprintf(g_agilisWrapper.com, [sprintf('1SU-50'),13,10]);     % value of step amplitude you want to use.
fprintf(g_agilisWrapper.com, [sprintf('1ZP'),13,10]);     % 1ZP Reset step counter to zero.
fprintf(g_agilisWrapper.com, [sprintf('1PR-100'),13,10]);     % 1PR100 Move 100 steps. Needed to move out of the limit.
WaitSecs(0.5);
fprintf(g_agilisWrapper.com, [sprintf('1MV-4'),13,10]);     % MV-4 Move to negative limit and stop.
WaitUntilResponse('PH','PH1',1);
fprintf(g_agilisWrapper.com, [sprintf('1TP?'),13,10]);     % Tell number of steps.
WaitSecs(0.5);
res = char(fread(g_agilisWrapper.com, g_agilisWrapper.com.BytesAvailable)');
numSteps = str2num(res(4:end))-100;
distanceTravelledUm = 12000;
stepSizeUm = distanceTravelledUm/numSteps;
return;

function WaitUntilResponse(strCommand,strResponse,delaySec)
global g_agilisWrapper
% clear buffer
if g_agilisWrapper.com.BytesAvailable > 0
    res = char(fread(g_agilisWrapper.com, g_agilisWrapper.com.BytesAvailable)');
end

i=0;
while 1
    fprintf(g_agilisWrapper.com, [sprintf('%s',strCommand),13,10]);     % 1MV-3 Move to the negative limit.
    if i > 15
        fprintf('%d Waiting for motor to respond...\n',i);
    end
    i=i+1;
    WaitSecs(delaySec);
    if g_agilisWrapper.com.BytesAvailable > 0
        res = char(fread(g_agilisWrapper.com, g_agilisWrapper.com.BytesAvailable)');
        if all(res(1:length(strResponse)) == strResponse)
            %fprintf('Motor in destination position\n');
            break;
        end
    end
end
return;
        

function [Res]=fnInit(strPort)
global g_agilisWrapper

fprintf('Initializing Agilis controller Module...\n');

g_agilisWrapper.codes.CMD_ENABLE_MANUAL_MODE = 'ML';
g_agilisWrapper.codes.CMD_ENABLE_PC_MODE = 'MR';
g_agilisWrapper.codes.CMD_RELATIVE_MOVE = 'PR';
g_agilisWrapper.codes.CMD_SET_STEP_SIZE = 'SU';
g_agilisWrapper.codes.CMD_STOP_MOTION = 'ST';
g_agilisWrapper.codes.CMD_QUERY_POSITION = 'TP';
g_agilisWrapper.codes.CMD_ZERO_POSITION = 'ZP';
g_agilisWrapper.codes.CMD_MOVE_TO_LIMIT = 'MV';
g_agilisWrapper.codes.CMD_SET_STEP_DELAY = 'DL';
g_agilisWrapper.codes.CMD_GET_STEP_DELAY = 'DL?';
g_agilisWrapper.codes.CMD_GET_STATUS = 'TS';
%global g_agilisWrapper
g_agilisWrapper.stepCorrectionFactor = 1.71333;
g_agilisWrapper.stepSizeUmNeg = -0.48844;
g_agilisWrapper.stepSizeUmPos = 0.48844 * g_agilisWrapper.stepCorrectionFactor;
g_agilisWrapper.numPosSteps = 0;
g_agilisWrapper.numNegSteps = 0;

allComObjects = instrfind('Port',strPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_agilisWrapper.com = serial(strPort,'BaudRate',921600,'DataBits',8,'Parity','none','StopBits',1);
try
    fopen(g_agilisWrapper.com);
catch
    fprintf('Warning. Could not connect to Agilis controller!\n');
    Res = false;
    return;
end
if ~strcmp(g_agilisWrapper.com.Status,'open')
    fprintf('Error communicating with Agilis controller\n');
    Res = false;
    return;
    
end

clearBuffer();

 [Res,parsedResponse] = auxSendCommand(g_agilisWrapper.codes.CMD_ENABLE_PC_MODE,[], [],[],[]);
  WaitSecs(0.1);
 fprintf(g_agilisWrapper.com, [sprintf('1SU-50'),13,10]);     % value of step amplitude you want to use.
 WaitSecs(0.1);
 fprintf(g_agilisWrapper.com, [sprintf('1SU50'),13,10]);     % value of step amplitude you want to use.

 
g_agilisWrapper.initialized = Res == true;

return;

function manualCalib()
global g_agilisWrapper


function [Res, parsedRespose] = auxSendCommand(command, strPrefix,strPostfix, strExpectedResponse, waitPeriod)
global g_agilisWrapper
parsedRespose =[];
Res =false;
if isempty(g_agilisWrapper) || strcmp(g_agilisWrapper.com.Status,'closed')
    return;
end;
    clearBuffer();
    
   
strOut = [sprintf('%s%s%s',strPrefix,command,strPostfix),13,10];
 fprintf(g_agilisWrapper.com, strOut);    

if ~exist('waitPeriod','var')
    waitPeriod = 0.5;
end
if ~isempty(waitPeriod)
    if waitPeriod > 0
        A=GetSecs();
        while GetSecs()-A < waitPeriod
            if g_agilisWrapper.com.BytesAvailable > 0
                WaitSecs(0.1);
                break;
            end
        end
        
    else
        if waitPeriod == 0
            fprintf('Waiting for Agilis controller to respond...');
            while g_agilisWrapper.com.BytesAvailable == 0
                WaitSecs(0.3);
            end
            fprintf('OK\n');
        end
    end
end
if ~isempty(strExpectedResponse)
    if g_agilisWrapper.com.BytesAvailable > 0
        Dummy = fread(g_agilisWrapper.com, g_agilisWrapper.com.BytesAvailable);
    else
        fprintf('Error communicating with agilis controller\n');
        Res = false;
        return;
    
    end
    if isempty(strExpectedResponse)
        Res = char(Dummy');
        return;
    end
    if length(Dummy) > 4
        parsedRespose = str2num(char(Dummy(4:end)'));
    end
end
Res = true;
return;


function clearBuffer()
global g_agilisWrapper
clear Dummy
if g_agilisWrapper.com.BytesAvailable > 0
    Dummy = fread(g_agilisWrapper.com, g_agilisWrapper.com.BytesAvailable);
end

% 
% 
% The MV-4 and MV4 commands are useful to calibrate the average step size at a
% certain step amplitude by counting the number of steps between the limits in
% forward and reverse direction. They are used as part of the MA and PA
% commands. In order to measure the number of steps between the limits, you can
% use the following sequence of commands:
% 1MV-3 Move to the negative limit.
% 1PH? If reply is 1PH1 or 1PH3, then:
% 1SUnn nn = value of step amplitude you want to use.
% 1ZP Reset step counter to zero.
% 1PR100 Move 100 steps. Needed to move out of the limit.
% MV4 Move to positive limit and stop.
% 1PH? If reply is PH1 or PH3, then:
% 1TP? Tell number of steps. The average step size in forward direction at the
% defined step amplitude is equal to the total available travel range (see
% data sheet) divided by the return of the TP command. 