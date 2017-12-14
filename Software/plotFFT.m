function plotFFT(y, Fs,col)
% y is the data
% Fs is sampling rate (Hz)
%

T = 1/Fs;                     % Sample time
L = length(y);                  % Length of signal
t = (0:L-1)*T;                % Time vector

NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);

% Plot single-sided amplitude spectrum.
plot(log10(f),2*abs(Y(1:NFFT/2+1)),col) 
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')

