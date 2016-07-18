function data = OscilloscopeData(source, visaObj)

%% Example to download waveform data from an Agilent oscilloscope
% This example connects to an Agilent scope using VISA and sends SCPI
% commands to initiate acquisition and downloads the data from a specific channel
% 
% The preamble block contains all of the current WAVEFORM settings.  
% It is returned in the form <preamble_block><NL> where <preamble_block> is:
%    FORMAT        : int16 - 0 = BYTE, 1 = WORD, 2 = ASCII.
%    TYPE          : int16 - 0 = NORMAL, 1 = PEAK DETECT, 2 = AVERAGE
%    POINTS        : int32 - number of data points transferred.
%    COUNT         : int32 - 1 and is always 1.
%    XINCREMENT    : float64 - time difference between data points.
%    XORIGIN       : float64 - always the first data point in memory.
%    XREFERENCE    : int32 - specifies the data point associated with
%                            x-origin.
%    YINCREMENT    : float32 - voltage diff between data points.
%    YORIGIN       : float32 - value is the voltage at center screen.
%    YREFERENCE    : int32 - specifies the data point where y-origin
%                            occurs.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Instrument control and data retreival
% Retrieve data using SCPI commands.

% % Specify data from Channel
switch source
        case 'Channel1'
            fprintf(visaObj,':WAVEFORM:SOURCE CHAN1'); 
        case 'Channel2'
            fprintf(visaObj,':WAVEFORM:SOURCE CHAN2'); 
        case 'Channel3'
            fprintf(visaObj,':WAVEFORM:SOURCE CHAN3'); 
        case 'Channel4'
            fprintf(visaObj,':WAVEFORM:SOURCE CHAN4'); 
end
% Set timebase to main
fprintf(visaObj,':TIMEBASE:MODE MAIN');
% Set up acquisition type and count. ACQUIRE:COUNT gives number of averages 
fprintf(visaObj,':ACQuire:TYPE AVERage');
fprintf(visaObj,':ACQuire:COUNt 64');

fprintf(visaObj,':ACQuire:TYPE HRESolution');
% Specify 500 points at a time by :WAV:DATA?
fprintf(visaObj,':ACQuire:POINTS:MODE RAW');
fprintf(visaObj,':ACQuire:POINTS 20');
% Now tell the instrument to digitize the channel
switch source
        case 'Channel1'
            fprintf(visaObj,':DIGITIZE CHAN1'); 
        case 'Channel2'
            fprintf(visaObj,':DIGITIZE CHAN2'); 
        case 'Channel3'
            fprintf(visaObj,':DIGITIZE CHAN3'); 
        case 'Channel4'
            fprintf(visaObj,':DIGITIZE CHAN4'); 
end

% Wait until complete
operationComplete = str2double(query(visaObj,'*OPC?'));
while ~operationComplete
    operationComplete = str2double(query(visaObj,'*OPC?'));
end
% Get the data back as a WORD (i.e., INT16), other options are ASCII and BYTE
fprintf(visaObj,':WAVEFORM:FORMAT WORD');
% Set the byte order on the instrument as well
fprintf(visaObj,':WAVEFORM:BYTEORDER LSBFirst');
% Get the preamble block
preambleBlock = query(visaObj,':WAVEFORM:PREAMBLE?');

% Now send commmand to read data
fprintf(visaObj,':WAV:DATA?');
% fprintf(visaObj, ':WAVeform:DATA?');

% read back the BINBLOCK with the data in specified format and store it in
% the waveform structure. FREAD removes the extra terminator in the buffer
waveform.RawData = binblockread(visaObj,'int16'); fread(visaObj,1);


%% Data processing: Push data into waveform structure

% Maximum value storable in a INT16
maxVal = 2^16;

%  split the preambleBlock into individual pieces of info
preambleBlock = regexp(preambleBlock,',','split');

% store all this information into a waveform structure for later use
waveform.Format = str2double(preambleBlock{1});     % This should be 1, since we're specifying INT16 output
waveform.Type = str2double(preambleBlock{2});
waveform.Points = str2double(preambleBlock{3});
waveform.Count = str2double(preambleBlock{4});     % This is always 1
waveform.XIncrement = str2double(preambleBlock{5}); % in seconds
waveform.XOrigin = str2double(preambleBlock{6});    % in seconds
waveform.XReference = str2double(preambleBlock{7});
waveform.YIncrement = str2double(preambleBlock{8}); % V
waveform.YOrigin = str2double(preambleBlock{9});
waveform.YReference = str2double(preambleBlock{10});
waveform.VoltsPerDiv = (maxVal * waveform.YIncrement / 8);      % V
waveform.Offset = ((maxVal/2 - waveform.YReference) * waveform.YIncrement + waveform.YOrigin);         % V
waveform.SecPerDiv = waveform.Points * waveform.XIncrement/10 ; % seconds
waveform.Delay = ((waveform.Points/2 - waveform.XReference) * waveform.XIncrement + waveform.XOrigin); % seconds

% Generate X & Y Data
waveform.XData = (waveform.XIncrement.*(1:length(waveform.RawData))) - waveform.XIncrement;
waveform.YData = (waveform.YIncrement.*(waveform.RawData - waveform.YReference)) + waveform.YOrigin;
% plot(waveform.XData, waveform.YData);

% Return data
data(:,1) = waveform.XData;
data(:,2) = waveform.YData;
    
end