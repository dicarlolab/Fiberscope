function Y=fnNotch(X, Fs, f0, bw)
% notch filter signal X, taken at sampling frequency Fs
% at frequency f0 with bandwidth of bw
wo = f0/(Fs/2);  
bw = bw/(Fs/2);%wo/35;
[b,a] = iirnotch(wo,bw);
Y=filtfilt(b,a,X);