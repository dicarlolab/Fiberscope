function [Res, parsedResponse] = ThorlabsStageControllerWrapper(strCommand, opt)
global g_ThorlabsController
parsedResponse=[];
Res = 1;

if strcmpi(strCommand,'IsInitialized')
    if ~isfield(g_ThorlabsController,'initialized')
        Res = false;
        return;
    end
    g_ThorlabsController.savedPosition = 0;
    Res = g_ThorlabsController.initialized;
    return;
elseif strcmpi(strCommand,'Home')
    g_ThorlabsController.device.Home(60000);
    return;
elseif strcmpi(strCommand,'SetRelativePositionMicrons')
    NewPos = System.Decimal.ToDouble(g_ThorlabsController.device.Position) + opt/1000.0;
    MoveTo(NewPos);
    g_ThorlabsController.savedPosition = NewPos;
    Res = 1;
    return;
elseif strcmpi(strCommand,'ResetRelative')
    g_ThorlabsController.relativePos = System.Decimal.ToDouble(g_ThorlabsController.device.Position)*1000;
    Res = 1;
    return;
elseif strcmpi(strCommand,'GetRelativePosition')
    parsedResponse = System.Decimal.ToDouble(g_ThorlabsController.device.Position)*1000 - g_ThorlabsController.relativePos;
    Res = 1;
    return;
elseif strcmpi(strCommand,'SetAbsolutePositionMicrons')
    NewPos = opt/1000;
    CurrPos = System.Decimal.ToDouble(g_ThorlabsController.device.Position);
    if (CurrPos == NewPos)
        Res = 1;
        return;
    end
    MoveTo(NewPos);
    g_ThorlabsController.savedPosition = NewPos;
    Res = 1;
    return;
elseif strcmpi(strCommand,'GetPositionMicrons')
    parsedResponse = System.Decimal.ToDouble(g_ThorlabsController.device.Position)*1000;
    Res = 1;
    return;
elseif strcmpi(strCommand,'SetStepSize')
    g_ThorlabsController.StepSizeMicrons = opt;    
    Res = 1;
    return;
elseif strcmpi(strCommand,'GetSpeed')
    parsedResponse = g_ThorlabsController.Speed;
    Res = 1;
    return;
elseif strcmpi(strCommand,'SetSpeed')
    g_ThorlabsController.Speed = opt;
    Res = 1;
    return;

elseif strcmpi(strCommand,'GetStepSizeMicrons')
    parsedResponse = g_ThorlabsController.StepSizeMicrons;
    Res = 1;
    return;
elseif strcmpi(strCommand,'StepDown')
    CurrPos = System.Decimal.ToDouble(g_ThorlabsController.device.Position);
    NewPos = CurrPos + g_ThorlabsController.StepSizeMicrons/1000;
    MoveTo(NewPos);
    g_ThorlabsController.savedPosition = NewPos;
    Res = 1;
    return;
elseif strcmpi(strCommand,'StepUp')
    CurrPos = System.Decimal.ToDouble(g_ThorlabsController.device.Position);
    NewPos = CurrPos - g_ThorlabsController.StepSizeMicrons/1000;
    MoveTo(NewPos);
    g_ThorlabsController.savedPosition = NewPos;
    Res = 1;
    return;
elseif strcmpi(strCommand,'Init')
    if (isfield(g_ThorlabsController,'initialized') && g_ThorlabsController.initialized)
        return;
    end
    ThorlabsInstallationFolder = 'C:\Program Files\Thorlabs\Kinesis\';
    NET.addAssembly([ThorlabsInstallationFolder,'\Thorlabs.MotionControl.DeviceManagerCLI.dll']);
    NET.addAssembly([ThorlabsInstallationFolder,'\Thorlabs.MotionControl.GenericMotorCLI.dll']);
    NET.addAssembly([ThorlabsInstallationFolder,'Thorlabs.MotionControl.IntegratedStepperMotorsCLI.dll']);
    
    import Thorlabs.MotionControl.DeviceManagerCLI.*
    import Thorlabs.MotionControl.GenericMotorCLI.*
    import Thorlabs.MotionControl.LongTravelStage.*
    import Thorlabs.MotionControl.IntegratedStepperMotorsCLI.*
    import Thorlabs.MotionControl.GenericMotorCLI.ControlParameters.*
    import Thorlabs.MotionControl.GenericMotorCLI.AdvancedMotor.*
    import Thorlabs.MotionControl.GenericMotorCLI.Settings.*
    
    g_ThorlabsController.StoredPosition = [];
    
    DeviceManagerCLI.BuildDeviceList();
    DeviceManagerCLI.GetDeviceListSize();
    serialNumbers = DeviceManagerCLI.GetDeviceList();
    for k=0:serialNumbers.Count-1
        fprintf('Found long range device %d : serial : %s\n',k,char(serialNumbers.Item(k)));
    end
    selectedDeviceSerial =  serialNumbers.Item(0);
    device = LongTravelStage.CreateLongTravelStage(selectedDeviceSerial);
    try
        device.Connect(serialNumbers.Item(0));
    catch
            device.StopPolling();
            device.Disconnect();
            device.Connect(serialNumbers.Item(0));
    end
    device.WaitForSettingsInitialized(5000);
    
    motorSettings = device.GetMotorConfiguration(selectedDeviceSerial);
    currentDeviceSettings = device.MotorDeviceSettings;
    
    motorSettings.UpdateCurrentConfiguration();
    deviceUnitConverter = device.UnitConverter();
    
    device.StartPolling(250);
    device.EnableDevice();
    pause(1); %wait to make sure device is enabled
    g_ThorlabsController.device = device;
    g_ThorlabsController.relativePos = 0;
    g_ThorlabsController.Speed = 60;
    g_ThorlabsController.initialized = true;
    g_ThorlabsController.StepSizeMicrons  = 100;
elseif  strcmpi(strCommand,'Release')
    g_ThorlabsController.device.StopPolling();
    g_ThorlabsController.device.Disconnect();
    g_ThorlabsController.initialized = false;
elseif  strcmpi(strCommand,'GetStepSize')
    parsedResponse = g_ThorlabsController.StepSizeMicrons ;
    Res = 1;
elseif strcmpi(strCommand,'StorePosition')
    g_ThorlabsController.StoredPosition = System.Decimal.ToDouble(g_ThorlabsController.device.Position);
    parsedResponse = 1;
    Res = 1;
elseif strcmpi(strCommand,'RecallPosition')
    if (isempty(g_ThorlabsController.StoredPosition))
        return;
    end
    MoveTo(NewPos);
    NewPos = g_ThorlabsController.StoredPosition;
    g_ThorlabsController.savedPosition = NewPos;
elseif strcmpi(strCommand,'GetPositionMicronsNonBlocking')
    
    if (~isfield(g_ThorlabsController,'savedPosition'))
        parsedResponse = -1;
    else
        parsedResponse = g_ThorlabsController.savedPosition;
    end
    Res = 1;
    
else
    fprintf('Unkown command: %s\n',strCommand);
end



function MoveTo(NewPos)
global g_ThorlabsController

CurrPos = System.Decimal.ToDouble(g_ThorlabsController.device.Position)*1000;
fprintf('Currently at : %.0f, Moving to %.0f\n',CurrPos,NewPos*1000);

try
    g_ThorlabsController.device.MoveTo(NewPos, g_ThorlabsController.Speed);
catch
end
