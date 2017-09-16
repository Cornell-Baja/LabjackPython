function varargout = StreamingGuide(varargin)


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StreamingGuide_OpeningFcn, ...
                   'gui_OutputFcn',  @StreamingGuide_OutputFcn, ...
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

% --- Executes just before StreamingGuide is made visible.
function StreamingGuide_OpeningFcn(hObject, eventdata, handles, varargin)


% Choose default command line output for StreamingGuide
handles.output = hObject;

% Update handles structure
handles.ljmAsm = NET.addAssembly('LabJack.LJM'); %Make the LJM .NET assembly visible in MATLAB

handles.t = handles.ljmAsm.AssemblyHandle.GetType('LabJack.LJM+CONSTANTS');
handles.LJM_CONSTANTS = System.Activator.CreateInstance(handles.t); %creating an object to nested class LabJack.LJM.CONSTANTS
handles.dispErr = true;
handles.handle = 0;
handles.log = true;
handles.rpm1 =0;
handles.rpm2=0;
handles.torque=0;
handles.dist1=0;
handles.dist2=0;



startIM=imread('finallogo_green_tn.jpg');
handles.start=startIM;



stopIM=imread('finallogo_tn.jpg');
handles.stop=stopIM;

axes(handles.imageAx);
imshow(startIM);

guidata(hObject, handles);




% This sets up the initial plot - only do when we are invisible
% so window can get raised using StreamingGuide.

% UIWAIT makes StreamingGuide wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = StreamingGuide_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

scanRate = double(100); %Scans per second
scansPerRead = int32(scanRate/2);
numAddresses = 10;
main_clock = 80000000;
clock_divisor = 64;
threshold = 200;
if get(hObject,'Value')
    set(handles.pushbutton1,'BackgroundColor','red');
    set(handles.pushbutton1,'String','STOP');
    axes(handles.imageAx);
    imshow(handles.stop);
    h=datestr(clock,30);
    currentPath=pwd;
    d=fileparts(which('StreamingGuide.m'));
    
    d=[d '\Data\'];
    disp(d);
    FileName=[d strcat(h(1:4),'_' ,h(5:6),'_' , h(7:8),'_' ,h(9),'_' ,h(10:11) ,'_',h(12:13),'_' ,h(13:14)),'_DynoTest.csv'];
    handles.FileName=FileName;
    
    PFile=[d 'read_dyno.csv'];
    t=fopen(PFile,'w');
    fclose(t);
    handles.PFile=PFile;
   
    header= {'Time'};
        if (handles.rpm1) 
            header= [header 'Engine RPM'];
        end
        if (handles.rpm2)
             header= [header 'Flywheel RPM'];
             header= [header 'Ratio'];
        end
        if (handles.torque)
             header= [header 'Torque'];
        end
        if (handles.dist1)
             header= [header 'Dist1'];
        end
        if (handles.dist2)
             header= [header 'Dist2'];
        end
        
     %dlmwrite(handles.PFile,header);
     
     
     fid = fopen(handles.PFile,  'a') ;
     fprintf(fid, '%s,', header{1:end}) ;
     fprintf(fid, '\n') ;

     fclose(fid) ;
    

    

    try
    %Open first found LabJack
    disp(handles.handle);
    [handles.ljmError, handles.handle] = LabJack.LJM.OpenS('ANY', 'ANY', 'ANY', handles.handle);
    %[ljmError, handle] = LabJack.LJM.Open(LJM_CONSTANTS.dtANY, LJM_CONSTANTS.ctANY, 'ANY', handle);
%     showDeviceInfo(handles.handle);
    
    
    
    %Stream Configuration
    
    aScanListNames = NET.createArray('System.String', numAddresses); %Scan list names to stream.
    aScanListNames(1) = 'AIN0';    %torque low
    aScanListNames(2) = 'AIN1';     %torque high
    aScanListNames(3) = 'CORE_TIMER';   %clock
    aScanListNames(4) = 'STREAM_DATA_CAPTURE_16';   %clock overflow
    aScanListNames(5) = 'DIO1_EF_READ_A_AND_RESET';           %Engine Rpm
    aScanListNames(6) = 'STREAM_DATA_CAPTURE_16';   %Engine RPM overflow
    aScanListNames(7) = 'DIO0_EF_READ_A_AND_RESET';           %secondary RPM
    aScanListNames(8) = 'STREAM_DATA_CAPTURE_16';   %secondary RPM overflow
    aScanListNames(9) = 'AIN2';  
    aScanListNames(10) = 'AIN3'; 
    
  
    
    logvalue=handles.log;
    aScanList = NET.createArray('System.Int32', numAddresses); %Scan list addresses to stream.
    aTypes = NET.createArray('System.Int32', numAddresses); %Dummy array for aTypes parameter
    LabJack.LJM.NamesToAddresses(numAddresses, aScanListNames, aScanList, aTypes);
   
  
    %Stream reads will be stored in aData. Needs to be at least
    %NumAddresses*ScansPerRead in size.
    aData = NET.createArray('System.Double', numAddresses*scansPerRead);
    
    %Configure the negative channels for single ended readings.
    aNames = NET.createArray('System.String', 16);
    aValues = NET.createArray('System.Double', 16);

    aNames(1) = [char(aScanListNames(1)) '_NEGATIVE_CH'];
    aValues(1) = 1;
    aNames(2) = [char(aScanListNames(2)) '_NEGATIVE_CH'];
    aValues(2) = handles.LJM_CONSTANTS.GND;
    aNames(3) = 'DIO_EF_CLOCK0_ENABLE';
    aValues(3) =0;
    aNames(4) = 'DIO0_EF_ENABLE';
    aValues(4) = 0;
    aNames(5) = 'DIO1_EF_ENABLE';
    aValues(5) = 0;
    
    aNames(6) = 'DIO_EF_CLOCK0_ENABLE';
    aValues(6) =0;
    
    aNames(7) ='DIO_EF_CLOCK0_DIVISOR';
    aValues(7)= clock_divisor;
    aNames(8) = 'DIO0_EF_INDEX';
    aValues(8) = 3;
    aNames(9) = 'DIO0_EF_ENABLE';
    aValues(9) = 1;

    aNames(10) = 'DIO1_EF_INDEX';
    aValues(10) = 3;
    aNames(11) = 'DIO1_EF_ENABLE';
    aValues(11) = 1;

    
    aNames(12) = 'DIO_EF_CLOCK0_ENABLE';
    aValues(12) =1;
    aNames(13) = [char(aScanListNames(9)) '_NEGATIVE_CH'];
    aValues(13) =handles.LJM_CONSTANTS.GND;
    aNames(14) = [char(aScanListNames(10)) '_NEGATIVE_CH'];
    aValues(14) =handles.LJM_CONSTANTS.GND;
     aNames(15) = [char(aScanListNames(1)) '_RESOLUTION_INDEX'];
    aValues(15) = 0;
    
     aNames(16) = [char(aScanListNames(1)) '_RANGE'];
    aValues(16) = 1.0;

    
    LabJack.LJM.eWriteNames(handles.handle, 16, aNames, aValues, 0);
    catch e
    if handles.dispErr
        showErrorMessage(InputNotConnected)
    end

end
else
    set(handles.pushbutton1,'String', 'START');
    set(handles.pushbutton1,'BackgroundColor','GREEN');
    axes(handles.imageAx);
    imshow(handles.start);

end


    if(get(hObject,'Value'))
        try
            %Configure and start stream
            [handles.ljmError, scanRate] = LabJack.LJM.eStreamStart(handles.handle, scansPerRead, numAddresses, aScanList, scanRate);
            disp(['Stream started with a scan rate of ' num2str(scanRate) ' Hz.'])
        catch e
            showErrorMessage(e)
        end  
    end
    
    tic   
    disp(['Performing stream reads.'])
    logvalue=handles.log;
    totalScans = 0;
    curSkippedSamples = 0;
    totalSkippedSamples = 0;
    timeStart=0.0;
    interval=double(scansPerRead/scanRate);
    
    try 
    while get(hObject,'Value')
         pause(.25);
        [ljmError, deviceScanBacklog, ljmScanBacklog] = LabJack.LJM.eStreamRead(handles.handle, aData, 0, 0);
         timeArray=linspace(double(timeStart),double(timeStart+.5),double(scansPerRead) );
%             
        timeStart=double(timeStart+.5+ double(1/scansPerRead));
        totalScans = totalScans + scansPerRead;
        %
        % 
        % <latex>
        % \begin{tabular}{|c|c|} \hline
        % $n$ & $n!$ \\ \hline
        % 1 & 1 \\
        % 2 & 2 \\
        % 3 & 6 \\ \hline
        % \end{tabular}
        % </latex>
        % 
        
%         curSkippedSamples = sum(double(aData) == -9999.0);
%         totalSkippedSamples = totalSkippedSamples + curSkippedSamples;
    
%         disp(['  eStreamRead ' num2str(i)])
        ainStr = '';
        for j=1:numAddresses,
            ainStr = [ainStr char(aScanListNames(j)) ' = ' num2str(aData(j+4)) '  '];
        end
       
        
        mlArray = aData.double;
        mlArray2 = reshape(mlArray, numAddresses,scansPerRead);
%         mlArrayt=mlArray2.';
%         timeArray= (mlArray2(3,:));
%         timeArray= ((80000000/64)./timeArray);
%         torqueLow=mlArray2(1,:);
%         torqueHigh=mlArray2(2,:);
        torque=mlArray2(1,:);
        torque=torque-(-.00176961);
        torque = smooth(torque, 0.15, 'rlowess');
        torque=torque*3941.1;
        
%         disp('streaming')
        d1=mlArray2(9,:);
        d2=mlArray2(10,:);
        rpmt2a= (mlArray2(5,:)+(mlArray2(6,:).*65536));         
        rpmt1a= (mlArray2(7,:)+bitshift(mlArray2(8,:),16));
        %disp(mlArray2(7,:)+(mlArray2(8,:)));
        %disp(rpmt2a);
        %fprintf(fileID,'%6.2f %12.8f\n',rpmt2a);
%         disp(rpmt1a) 
        rpm1 = ((80000000/64)./rpmt1a);
        rpm2 = ((80000000/64)./rpmt2a);
        %disp(rpmt1a);
        %disp(rpmt2a);
%         disp(mean(rpmt1a)); 
%         disp(mean(rpmt2a));
             %   disp(mean(rpm2));

%         disp(mean(rpm1(rpm1>800 & rpm1<3500)));
        rpm1(rpm1<500 | rpm1>4000)= mean(rpm1(rpm1>500 & rpm1<4000)); 
%        filter for flywheel:
        meanRPM = mean(rpm2(rpm2>5 & rpm2<6100));
        %disp(meanRPM);
        %rpm2(abs(rpm2 - meanRPM) > meanRPM*1.5) = meanRPM;
        rpm2(rpm2<5 | rpm2>6100)= meanRPM;
%         
        
        rpm1(isnan(rpm1))=0;
        rpm2(isnan(rpm2))=0;
       
        rpm1 = smooth(rpm1,0.15,'rlowess');
        rpm2 = smooth(rpm2,0.15,'rlowess');
        rpm1(isnan(rpm1))=0;
        rpm2(isnan(rpm2))=0;
       
        %choose the value
       
        meanRPM = mean(rpm2);
        rpm2(abs(rpm2 - meanRPM) > meanRPM/2) = meanRPM;
        ratio = rpm1./rpm2;
        ratio(isnan(ratio)) = 0;
        ratio(ratio > 10) = 10;
        mlArray3= [timeArray.' ];

%         disp(size(torque));
        if (handles.rpm1) 
            mlArray3=[mlArray3 rpm1];
        end
        if (handles.rpm2)
            mlArray3=[mlArray3 rpm2];
            mlArray3=[mlArray3 ratio];
        end
        if (handles.torque)
            mlArray3=[mlArray3 torque];
        end
        if (handles.dist1)
            mlArray3=[mlArray3 d1.'];
        end
        if (handles.dist2)
            mlArray3=[mlArray3 d2.'];
        end
     
        
        dlmwrite(handles.FileName,mlArray3,'-append');
        
        dlmwrite(handles.PFile,mlArray3,'-append');
    end
    catch e
        showErrorMessage(e)
    end
    timeElapsed = toc;
    
    disp(['Total scans = ' num2str(totalScans)])
    disp(['Skipped Scans = ' num2str(totalSkippedSamples/numAddresses)])
    disp(['Time Taken = ' num2str(timeElapsed) ' seconds'])
    disp(['LJM Scan Rate = ' num2str(scanRate) ' scans/second'])
    disp(['Timed Scan Rate = ' num2str(totalScans/timeElapsed) ' scans/second'])
    disp(['Sample Rate = ' num2str(numAddresses*totalScans/timeElapsed) ' samples/second'])
    
    if(get(hObject,'Value')~=0)
        disp('Stop Stream')
        LabJack.LJM.eStreamStop(handles.handle);
    end
    
%     try
%         % Close handle
%     %     LabJack.LJM.eStreamStop(handles.handle);
%         LabJack.LJM.Close(handles.handle);
%     catch e
%         showErrorMessage(e)
%     end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in rpm1Check.
function rpm1Check_Callback(hObject, eventdata, handles)
% hObject    handle to rpm1Check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.rpm1=get(hObject,'Value');
guidata(hObject, handles);


% Hint: get(hObject,'Value') returns toggle state of rpm1Check


% --- Executes on button press in rpm2Check.
function rpm2Check_Callback(hObject, eventdata, handles)
% hObject    handle to rpm2Check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.rpm2=get(hObject,'Value');
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of rpm2Check


% --- Executes on button press in torqueCheck.
function torqueCheck_Callback(hObject, eventdata, handles)
% hObject    handle to torqueCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.torque=get(hObject,'Value');
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of torqueCheck


% --- Executes on button press in d1Check.
function d1Check_Callback(hObject, eventdata, handles)
% hObject    handle to d1Check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.dist1=get(hObject,'Value');
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of d1Check


% --- Executes on button press in d2check.
function d2check_Callback(hObject, eventdata, handles)
% hObject    handle to d2check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.dist2=get(hObject,'Value');
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of d2check


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function pushbutton1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
