% Test Zero-MQ Matlab Wrapper and Kofiko-Intan Communication
global  g_strctDAQParams
g_strctDAQParams.m_strAcqusitionCardBoard = 'COM6';

fnAddPTBFolders('C:\Shay\Code\PublicLib\PTB\');

iPort = 4;

hPort = fndllSerialInterface('Open','COM6');
%  fnCloseSerialPortforArduino()
bError= fnInitializeSerialPortforArduino();
g_strctDAQParams.m_fJuicePort = 16;

fnDAQ('Init',0);

            fnDAQ('SetBit',g_strctDAQParams.m_fJuicePort,0);
addpath('..\..\MEX\win32');

handle = fndllZeroMQ_Wrapper('StartConnectThread','tcp://192.168.50.96:4002');
fndllZeroMQ_Wrapper('Send',handle ,'SetSessionName Test');
fndllZeroMQ_Wrapper('CloseThread',handle);

clear mex

  



WaitSecs(0.5);
afTic=zeros(1,100);
afToc=zeros(1,100);
for k=1:100

% fndllZeroMQ_Wrapper('Send',handle,'event Before');
afTic(k)=GetSecs();
%IOPort('Write',  g_strctDAQParams.m_hArduino , [sprintf('setbit %d %d',iPort, 1),10]);
fndllSerialInterface('Send',  hPort, ['setbit 4 1',10]); % Bit will be changed 2.56 ms after this command.
%fnDAQ('SetBit',g_strctDAQParams.m_fJuicePort, 1);
afToc(k)=GetSecs();
fndllZeroMQ_Wrapper('Send',handle,sprintf('event Inside %d',k));
%IOPort('Write',  g_strctDAQParams.m_hArduino , [sprintf('setbit %d %d',iPort, 0),10]);
fndllSerialInterface('Send',  hPort, ['setbit 4 0',10]);

 %fnDAQ('SetBit',g_strctDAQParams.m_fJuicePort, 0);
%  fndllZeroMQ_Wrapper('Send',handle,'event After');
 WaitSecs(0.3);
end

figure;plot((afToc-afTic)*1e3)
%IOPort('Write',  g_strctDAQParams.m_hArduino , [sprintf('setbit %d %d',iPort, 0),10],2);
WaitSecs(0.5);
 
for k=1:10
IOPort('Write',  g_strctDAQParams.m_hArduino , [sprintf('setbit %d %d',iPort, 1),10]);
tic
while toc < 0.05
end
IOPort('Write',  g_strctDAQParams.m_hArduino , [sprintf('setbit %d %d',iPort, 0),10]);
tic
while toc < 0.05
end

end




% Open Arduino-Based Communication
