function comPort = getCOMmapping(deviceIdentified)
switch lower(deviceIdentified)
    case 'filterwheel'
        comPort = 'COM6';
    case 'agilis'
        comPort = 'COM4';
    case 'dmdoverclock'
        comPort = 'COM3';
    case 'zstage'
        if ismac
        comPort = '/dev/cu.usbserial-AI03D8LM';

        else
        comPort = 'COM7';
            
        end
    case 'pmt'
        comPort = 'COMx';
    case 'cameraoverclock'
        comPort = 'COMX';
    case 'leddriver'
        comPort = 'COM3';
    case 'temperature'
        comPort = 'COM24';
    case 'laser'
        comPort = 'COM35';
        
    otherwise
        comPort = [];
end