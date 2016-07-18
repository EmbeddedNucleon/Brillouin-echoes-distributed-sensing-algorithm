%% MIT License
%
% Copyright (c) 2016 Ryan Michael Thomas
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.


function varargout = Oscilloscope(varargin)
% OSCILLOSCOPE MATLAB code for Oscilloscope.fig
%      OSCILLOSCOPE, by itself, creates a new OSCILLOSCOPE or raises the existing
%      singleton*.
%
%      H = OSCILLOSCOPE returns the handle to a new OSCILLOSCOPE or the handle to
%      the existing singleton*.
%
%      OSCILLOSCOPE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OSCILLOSCOPE.M with the given input arguments.
%
%      OSCILLOSCOPE('Property','Value',...) creates a new OSCILLOSCOPE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Oscilloscope_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Oscilloscope_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Oscilloscope

% Last Modified by GUIDE v2.5 23-May-2016 12:25:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Oscilloscope_OpeningFcn, ...
                   'gui_OutputFcn',  @Oscilloscope_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Oscilloscope is made visible.
function Oscilloscope_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Oscilloscope (see VARARGIN)

%% Connect to the signal generator

handles.visaObjSig = instrfind('Name', 'VISA-GPIB0-19');      % Check if the VISA object for the oscilloscope is already open
    if isempty(handles.visaObjSig)
        handles.visaObjSig=visa('agilent','GPIB0::19::INSTR');    % If not, create a VISA object for the oscilloscope
    else
        fclose(handles.visaObjSig);                              % If already open, close the object
        handles.visaObjSig = handles.visaObjSig(1);                               % But keep the object
    end
    handles.visaObjSig.InputBufferSize = 16000000;                   % was 100000 Input buffer size, 512: by default
    handles.visaObjSig.Timeout = 30;
    handles.visaObjSig.ByteOrder = 'littleEndian';
    fopen(handles.visaObjSig);
    
    frequencyInitialise = 1.0;                                            % GHz
    fprintf(handles.visaObjSig,'*IDN?;')                         % Get the instrument identity
    idn = fscanf(handles.visaObjSig, '%s');
    fprintf(handles.visaObjSig,'freq:mode cw')                   % Set the generator to the CW mode
    fprintf(handles.visaObjSig, ['freq ' num2str(frequencyInitialise) 'E9;'])     % Set the RF frequency
    fprintf(handles.visaObjSig, 'OUTPut ON')   % Switch on the output

%% Connect to the oscilloscope

handles.visaObj = instrfind('Name', 'VISA-GPIB0-7');
% Create the GPIB object if it does not exist
% otherwise use the object that was found.
if isempty(handles.visaObj)
    handles.visaObj=visa('agilent','GPIB0::7::INSTR');
else
    fclose(handles.visaObj);
    handles.visaObj = handles.visaObj(1);
end

handles.visaObj.InputBufferSize = 16000000;
handles.visaObj.Timeout = 30;
handles.visaObj.ByteOrder = 'littleEndian';
fopen(handles.visaObj);

%%%

%Initialise data and initialise plot
handles.current_channel = 'Channel3';

% Choose default command line output for Oscilloscope
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%% Connection to Tabor waveform generator using IVI

Channel1ns = 'channel1';
Channel50ns = 'channel2';

%       Create and connect a device object
deviceObj = icdevice('wx218x_IVI_COM.mdd', 'GPIB0::11::INSTR');
connect(deviceObj);


%% Download 1ns pulse (.wav or .cvs file) onto Tabor waveform generator

%        Execute device object function(s).
groupObj = get(deviceObj, 'Arbitrarywaveform');
groupObj = groupObj(1);
invoke(groupObj, 'Clear', -1);

%       Upload .csv file
invoke(groupObj, 'LoadCSVFile', Channel1ns,'.\1ns_pulse.csv');

%       Configure property value(s).
set(deviceObj.Output(1), 'OutputMode', 'WX218xOutputModeArbitrary');

%       Execute device object function(s).
groupObj = get(deviceObj, 'Output');
groupObj = groupObj(1);
invoke(groupObj, 'Enabled', Channel1ns,1);


%% Download 50ns pulse (.wav or .cvs file) onto Tabor waveform generator

%        Execute device object function(s).
groupObj = get(deviceObj, 'Arbitrarywaveform');
groupObj = groupObj(1);

%       Upload .csv file
invoke(groupObj, 'LoadCSVFile', Channel50ns,'.\50ns_pulse.csv');

%       Configure property value(s).
set(deviceObj.Output(1), 'OutputMode', 'WX218xOutputModeArbitrary');

%       Execute device object function(s).
groupObj = get(deviceObj, 'Output');
groupObj = groupObj(1);
invoke(groupObj, 'Enabled', Channel50ns,1);


% UIWAIT makes Oscilloscope wait for user response (see UIRESUME)
% uiwait(handles.oscilloscope);

% --- Outputs from this function are returned to the command line.
function varargout = Oscilloscope_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in channel_popupmenu.
function channel_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to channel_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = get(hObject, 'Value');
str = get(hObject, 'String');

switch str{val}
    case 'Channel 1'
        handles.current_channel = 'Channel1';
    case 'Channel 2' 
        handles.current_channel = 'Channel2';
    case 'Channel 3'
        handles.current_channel = 'Channel3';
    case 'Channel 4'
        handles.current_channel = 'Channel4';
end

% Hints: contents = cellstr(get(hObject,'String')) returns channel_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_popupmenu
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function channel_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
handles.current_channel = 'Channel3';

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in start_pushbutton.
function start_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to start_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% fopen(handles.visaObj);
% fprintf(handles.visaObjSig, ['freq ' num2str(1.0) 'E9;'])     % Set the RF frequency
handles.current_channel = 'Channel3';
handles.getTimeData = OscilloscopeData('Channel3',handles.visaObj);
frequency = 1:0.05:1.2;
[X,Y] = meshgrid(frequency',handles.getTimeData(:,1));

for n = 1:5
    fprintf(handles.visaObjSig, ['freq ' num2str(frequency(n)) 'E9;'])     % Set the RF frequency

    switch handles.current_channel
        case 'Channel1'
            handles.current_data = OscilloscopeData('Channel1',handles.visaObj);
            volts(:,n)=handles.current_data(:,2);
        case 'Channel2'
            handles.current_data = OscilloscopeData('Channel2',handles.visaObj);
            volts(:,n)=handles.current_data(:,2);
        case 'Channel3'
            handles.current_data = OscilloscopeData('Channel3',handles.visaObj);
            volts(:,n)=handles.current_data(:,2);
        case 'Channel4'
            handles.current_data = OscilloscopeData('Channel4',handles.visaObj);
            volts(:,n)=handles.current_data(:,2);
    end
end

mesh(X,Y,volts);
xlabel('Frequency (GHz)');
ylabel('Time (s)');
zlabel('Volts (V)');
title('Oscilloscope Data');


% --- Executes during object deletion, before destroying properties.
function oscilloscope_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to oscilloscope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fclose(handles.visaObjSig); delete(handles.visaObjSig); clear handles.visaObjSig;
fclose(handles.visaObj); delete(handles.visaObj); clear handles.visaObj;
disconnect(deviceObj); delete(deviceObj);


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
