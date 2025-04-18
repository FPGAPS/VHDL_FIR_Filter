close all
clear all
clc
%% setup the parameters here
Sample_Rate = 100e6;
cutoff_frequency = 5e6;
number_of_filter_taps = 32; % 32 for lowpass; 31 for highpass; if you set 31 use the zero padded taps!!!! 
filter_taps_bitwidth = 11; % 11
lowpass_highpass = 'low'; % should be low or high
%% Caluculate the taps
Nyquist_frequency =Sample_Rate/2 ;
Wn = cutoff_frequency/(Nyquist_frequency);
%Generate a row vector b containing the n+1 coefficients 
filter_taps = fir1(number_of_filter_taps-1,Wn,lowpass_highpass);
%% Quantization 
% one bit for sign
filter_taps=floor(filter_taps/max(filter_taps)*(2^(filter_taps_bitwidth-1)-1));
filter_taps_zero_padded = [0,filter_taps];
%% plot the filter response
N = 1024; % Number of points for the frequency response
[H, f] = freqz(filter_taps, 1, N, Sample_Rate); % Calculate the frequency response
% Magnitude and phase response
magnitude = abs(H); % Magnitude response
taps_en = ones(size(filter_taps));
% Plot the filter response
% Magnitude response plot
figure;
plot(f, 20*log10(magnitude),'linewidth',1.3); % Plot magnitude in dB
grid on;
title('Magnitude Response (dB)',FontSize=22);
xlabel_txt = 'Frequency (Hz)';
xlabel(xlabel_txt,FontSize=22);
ylabel('Magnitude (dB)',FontSize=22);
%xlim([0 30e6])
figure
 freqz(filter_taps,1)
figure
stem(filter_taps,'linewidth', 1.3)
grid on;