function ret=SessionWrapper(strCommand,varargin)
global g_sessionModule

ret = [];

if isempty(g_sessionModule)
    g_sessionModule.rootFolder = 'G:/Sessions/';
    InitSessionWrapper();
end

g_sessionModule.rootFolder = 'G:/Sessions/';

if strcmpi(strCommand,'NewSession')
    ret = StartNewSession(varargin);
elseif strcmpi(strCommand,'Init')    
    InitSessionWrapper();
    
elseif strcmpi(strCommand,'SetActiveSession')    
    SetActiveSession(varargin);
elseif strcmpi(strCommand,'ListSessions')
    tmp= dir([g_sessionModule.rootFolder,'/*hdf5']);
    [~,ind]=sort(datenum({tmp.date}));
    ret ={tmp(ind).name};
elseif strcmpi(strCommand,'LoadSession')
    sessionModule.activeSessionFileName= sprintf('%s%s',g_sessionModule.rootFolder, varargin{1});
    try
        sessionModule.sessionID = h5readatt(sessionModule.activeSessionFileName,'/','sessionID');
        sessionModule.subject = h5readatt(sessionModule.activeSessionFileName,'/','subject');
        g_sessionModule = sessionModule;
        
        hdf5FileInfo = h5info(sessionModule.activeSessionFileName);
        numCalibrations = length(hdf5FileInfo.Groups(1).Groups);
        
        Depthstr = cell(1,numCalibrations );
        for k=1:numCalibrations 
            
            depthUm = h5read(sessionModule.activeSessionFileName,sprintf('/calibrations/calibration%d/relativeDepth',k));
            try
                finedepthUm = h5read(sessionModule.activeSessionFileName,sprintf('/calibrations/calibration%d/fineEncoderLocation',k));
            catch
                finedepthUm = 0;
            end
            
            try
                colorChannelName = char(h5read(sessionModule.activeSessionFileName,sprintf('/calibrations/calibration%d/colorChannelName',k)));
            catch
                colorChannelName = '';
            end
            
            
            if (depthUm < 0)
                depthUm = -depthUm;
            end
            Depthstr{k}=sprintf('%s %.0f + %.2f um',colorChannelName,depthUm,finedepthUm);
        end
        ret = Depthstr;
       
        
        
        
        
    catch
    end
    
elseif strcmpi(strCommand,'GetSessionDescription')
    sessionFileName= sprintf('%s%s',g_sessionModule.rootFolder, varargin{1});
    hdf5FileInfo = h5info(sessionFileName);
    if isempty(hdf5FileInfo.Groups)
        ret = [];
        return;
    end
    numCalibrations = length(hdf5FileInfo.Groups(1).Groups);
        
    depthUm = zeros(1,numCalibrations );
    finedepthUm = zeros(1,numCalibrations );
    relativedepthUm = zeros(1,numCalibrations );
    color = cell(1, numCalibrations );
    for k=1:numCalibrations 
       depthUm(k) = h5read(sessionFileName,sprintf('/calibrations/calibration%d/actualEncoderLocation',k));
       relativedepthUm(k) = h5read(sessionFileName,sprintf('/calibrations/calibration%d/relativeDepth',k));
       finedepthUm(k) = h5read(sessionFileName,sprintf('/calibrations/calibration%d/fineEncoderLocation',k));
       
       color{k} = char( h5read(sessionFileName,sprintf('/calibrations/calibration%d/colorChannelName',k)));
    end
   ret = {depthUm, relativedepthUm, finedepthUm,color};
 
elseif strcmpi(strCommand,'GetSession')
    if isempty(g_sessionModule.activeSessionFileName)
        fprintf('Automatically creating new session!\n');
        StartNewSession();
    end
    ret = g_sessionModule.activeSessionFileName;
elseif strcmpi(strCommand,'GetSessionID')
    if isempty(g_sessionModule.activeSessionFileName)
        fprintf('Automatically creating new session!\n');
        StartNewSession();
    end
    ret = g_sessionModule.sessionID;
end

function ret = StartNewSession(varargin)
global g_sessionModule
if isempty(varargin) || isempty(varargin{1})
    subject = 'unknown';
else
    subject = varargin{1};
end
sessions = dir([g_sessionModule.rootFolder,'session*hdf5']);
ret = [];
try
    numbers = zeros(1,length(sessions));
    for k=1:length(sessions)
        [~,tmp]=fileparts(sessions(k).name);
        numbers(k)=str2num(tmp(8:end));
    end
numExistingSessionFiles = max(numbers);
g_sessionModule.sessionID = numExistingSessionFiles+1;
g_sessionModule.activeSessionFileName = sprintf('%ssession%d.hdf5',g_sessionModule.rootFolder, g_sessionModule.sessionID);
g_sessionModule.subject = subject;
h5create(g_sessionModule.activeSessionFileName,'/dummy',[1 1]); % create a dummy dataset to create the file.
h5writeatt(g_sessionModule.activeSessionFileName,'/','sessionID',g_sessionModule.sessionID);
h5writeatt(g_sessionModule.activeSessionFileName,'/','creation_date',datestr(now));
h5writeatt(g_sessionModule.activeSessionFileName,'/','subject',subject);
fprintf('Started new session %s\n',g_sessionModule.activeSessionFileName);
catch
    fprintf('Failed to create a new session!\n');
    ret = [];
end
ret = g_sessionModule.activeSessionFileName;
return;

function InitSessionWrapper()
global g_sessionModule
if ~exist(g_sessionModule.rootFolder,'dir')
    mkdir(g_sessionModule.rootFolder);
end
g_sessionModule.activeSessionFileName = [];





function ret = SetActiveSession(  varargin)
global g_sessionModule
subject='unknown';
[~,sessionFileName]=fileparts(varargin{1}{1});
g_sessionModule.sessionID = str2num(sessionFileName(8:end));
g_sessionModule.activeSessionFileName = sprintf('%ssession%d.hdf5',g_sessionModule.rootFolder, g_sessionModule.sessionID);
g_sessionModule.subject = subject;
fprintf('Loaded saved session %s\n',g_sessionModule.activeSessionFileName);

return;
