function varargout = waveforms(varargin)

% This script is designed for the analysis of source waveform (.swf) files 
% generated by the BESA software.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Last Modified by Karsten Hoechstetter 24 October 2005
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% External functions:
%   
% baseline.m:   used within the callback routine for the 'Baseline' button. Calculate baseline
%               of selected waveforms.
% boot.m:       used within the callback routine for the 'Boot' button. Calculate mean and 
%               confidence interval of selected waveforms.
% boot_ci_slpha: used within the boot.m function. Calculate mean and a confidence interval
%               specified by the parameter alpha.
% combine.m:    used within the callback routine for the 'Combine' button. Combine selected
%               waveforms.
% delay.m:      used within the callback routine for the 'Delay' button. Add a time delay to the 
%               selected waveforms.
% extrema.m:    used within the callback routine for the 'Extrema' button. Calculate extrema
%               of the selected waveforms.
% fileopen.m:   used within the 'File->Open' menu callback. Import new data from .swf or .uwf file
% filters.m:    used within the 'Filter' Callback. Filter selected data.
% integrate.m:  used within the 'Area' Callback. Calculate area under selected waveforms.
%               matrices. Necessary to calculate confidence intervals with the BCa method (compare
%               Efron/Tibshirani).
% NewWaveForm.m: used within several subfunctions. Add new waveform to the global variable
%               WAVEFORMS.
% options.m:    used within the callback routine of the 'Edit->Plot options'. Edit plot options.
% plot_legend.m: used within the callback routine for the 'Plot' button. Open and initialize legend
%               window.
% plotwindow.m: used within the callback routine for the 'Plot' button. Open and initialize plot
%               figure.
% ReadWF.m:     used within the fileopen.m function. Reads all information contained in a .uwf or 
%               .swf file
% rename.m:     used within the callback routine for the 'Rename' button. Rename selected waveforms.
% resampling.m: used within the callback routine for the 'Resample' button. Resample selected
%               waveforms.
% waitbar_db.m: used during bootstrapping. Display waitbar. Function taken from the MATLAB provided
%               function waitbar.m with waitbar displayed in dark blue instead of red.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WAVEFORMS: struct containing all imported waveforms with the following fields:
%       name: Name of the waveform
%       Npts: Number of points
%       TSB: "Time Sweep Begin"; start time point
%       DI: time Distance between two sample points
%       data: data points
%       type: 'single' if single waveform
%             'boot' if waveforms with confidence interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global WAVEFORMS 
global DATAWINDOW               % handle of the Main Window
global INITIALDIRECTORY         % Current directory when the script is launched
global FILEOPENDIRECTORY        % Directory to be displayed in the 'File open' dialog
global SHADED_AREA              % Set in 'Edit Plot Options'. Value 1: confidence interval displayed as shaded area; Value 2: confidence interval displayed as lines
global COLORORDER               % current color order
global DEFAULTCOLORORDER        % default color order

% Initialize parameters (if they don't exist yet)
DEFAULTCOLORORDER = [[0 0 1]; [1 0 0]; [0 0.5 0]; [1 0.75 0]; [0 0 0]; [0.75 0 0.75]; [0 0.75 1]; [1 0.5 0]; [0.5 0.5 0.5]; [0.5 0.25 0]; ...
    [0 0 1]; [1 0 0]; [0 0.5 0]; [1 0.75 0]; [0 0 0]; [0.75 0 0.75]; [0 0.75 1]; [1 0.5 0]; [0.5 0.5 0.5]; [0.5 0.25 0]];
if isempty(SHADED_AREA)
    SHADED_AREA = 1;
end
if isempty(COLORORDER)
    COLORORDER = DEFAULTCOLORORDER;
end 

if nargin == 0  % LAUNCH GUI
    INITIALDIRECTORY = pwd;
    FILEOPENDIRECTORY = pwd;
    DATAWINDOW = openfig(mfilename,'reuse');  % activate main window
    set(DATAWINDOW,'Color',get(0,'DefaultUicontrolBackgroundColor'), ...
                   'Visible','Off');   
    % Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(DATAWINDOW);
	guidata(DATAWINDOW, handles);
    
    % Set size and screen position of the main window    
    set(0,'Units','characters');
    screensize = get(0,'ScreenSize');
    set(DATAWINDOW,'Units','characters','Position',[1 1 149, round(screensize(4)/2)-3]); 
    movegui(DATAWINDOW,'northeast');
    set(DATAWINDOW,'Visible','On');

    % Populate the listbox
    update_listbox(handles);
    
    % Initialize structure WAVEFORMS
    if isempty(WAVEFORMS)
        WAVEFORMS=struct('name',{});
    end
    
    if nargout > 0
		varargout{1} = DATAWINDOW;
	end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
   
	try
        if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
            feval(varargin{:}); % FEVAL switchyard
        end
	catch
		disp(lasterr);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Callback routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --------------------------------------------------------------------
% listbox_Callback
% --------------------------------------------------------------------
function varargout = listbox_Callback(h, eventdata, handles, varargin)
set_button_enabling(handles)


% --------------------------------------------------------------------
% menu_file_Callback (empty)
% --------------------------------------------------------------------
function varargout = menu_file_Callback(h, eventdata, handles, varargin)


% --------------------------------------------------------------------
% menu_file_openwf_Callback
% --------------------------------------------------------------------
function varargout = menu_file_openwf_Callback(h, eventdata, handles, varargin)
fileopen;


% --------------------------------------------------------------------
% pushbutton_Plot_Callback: plot swf-file(s)
% --------------------------------------------------------------------
function varargout = pushbutton_Plot_Callback(h, eventdata, handles, varargin)
global PLOTFIGURE           % handle of the plot window
global PLOTAXES             % handle of the plot axes
global LEGENDWINDOW         % handle of the legend window
global COLORORDER           % current color order

% open legend window and make it invisible
try
    set(LEGENDWINDOW,'Visible','Off');
catch
end
LEGENDWINDOW = openfig('plot_legend','reuse','invisible');
legendhandles = guihandles(LEGENDWINDOW);
legendindex = 1;

% store selected data in a separate variable
selected_data = get_selected_data(handles);

% make the axes in the plotwindow the current axis
try
    axes(PLOTAXES);
catch
    plotwindow
end
%XLabel('Latency [ms]');
%YLabel('Dipole moment [nAm]');
cla
hold on; 
ColIndex=1;

% Divide data in data with and without confidence interval
bootindices = strmatch('boot',char(selected_data.type),'exact');
nonbootindices = strmatch('single',char(selected_data.type),'exact');

len = size(selected_data,2);                    % number of waveforms to be plotted
wid = 10;
for i=1:len
    if length(selected_data(i).name) > wid
        wid = length(selected_data(i).name);    % length (at least 10) of the longest name of the waveforms to be plotted
    end
end

% set screen position of the legend window
set(0,'Units','characters');
screensize = get(0,'ScreenSize');
set(LEGENDWINDOW,'Units','Characters','Position',[0 3 wid+13 len+0.5]);
movegui(LEGENDWINDOW,'southeast');
pos = get(LEGENDWINDOW,'Position');
set(LEGENDWINDOW,'Position',[pos(1) round(screensize(4)/2)-len-3.1 wid+13 len+0.5]); 

% create legend
for i=1:40
    set(eval(['legendhandles.text',num2str(i)]),'String','','Units','Characters','Position',[1 len+0.25-i wid+10 1]);
end

% plot data with confidence interval first
for i=bootindices'
    plot_boot(selected_data(i).Npts,selected_data(i).TSB,selected_data(i).DI,selected_data(i).data,ColIndex);
    set(eval(['legendhandles.text',num2str(legendindex)]),'String',selected_data(i).name,'ForegroundColor',COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:));
    ColIndex=ColIndex+1;
    legendindex = legendindex+1;
end
% then plot data without confidence interval
for i=nonbootindices'
    plot([selected_data(i).TSB:selected_data(i).DI: ...
        selected_data(i).TSB+selected_data(i).DI*(selected_data(i).Npts-1)],selected_data(i).data, ...
        'Color',COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:));
    set(eval(['legendhandles.text',num2str(legendindex)]),'String',selected_data(i).name,'ForegroundColor',COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:));
    ColIndex=ColIndex+1;
    legendindex = legendindex+1;
end

% Determine smallest time sweep begin and highest stop time of the data to be plotted
tsb = zeros(1,len);
t_end = zeros(1,len);
for i=1:len
    tsb(i)=selected_data(i).TSB;
    t_end(i)=selected_data(i).TSB+(selected_data(i).Npts-1)*selected_data(i).DI;
end
% Perform axis scaling and draw axes
axis auto;
axv=axis;
axis([min(tsb) max(t_end) axv(3) axv(4)]);
ax=axis;
line([ax(1) ax(2)],[0 0],'Color',[0 0 0]);
line([0 0],[ax(3) ax(4)],'Color',[0 0 0],'LineStyle',':');
% now show both plot and legend window
set(PLOTFIGURE,'Visible','On');
set(LEGENDWINDOW,'Visible','On');


% --------------------------------------------------------------------
% pushbutton_Bootstrap_Callback: Callback for Bootstrap-Button
% --------------------------------------------------------------------
function varargout = pushbutton_Bootstrap_Callback(h, eventdata, handles, varargin)
global BOOTSTRAP_DATA   

% Store selected data in global variable
BOOTSTRAP_DATA = get_selected_data(handles);

% Determine time sweep begin, distance and number of points of selected data
for i=1:size(BOOTSTRAP_DATA,2)
    tsb(i) = BOOTSTRAP_DATA(i).TSB;
    npts(i) = BOOTSTRAP_DATA(i).Npts;
    di(i) = BOOTSTRAP_DATA(i).DI;
end

% Display error message if selected data has different time sweep begin, distance or number of points
for i=1:size(di,2)-1
    if tsb(i)~=tsb(i+1) | npts(i)~=npts(i+1) | di(i)~=di(i+1)
       errordlg('Sampling rate and time epoch must be equal for all waveforms.','Error','modal')
       return
    end
end

% Display error message if selected data contains waveforms with confidence interval
for i=1:size(BOOTSTRAP_DATA,2)
    if strmatch(BOOTSTRAP_DATA(i).type,'boot','exact')
       errordlg('Data with confidence intervals cannot be used.','Error','modal')
       return
    end
end  

% start bootstrapping
boot;


% --------------------------------------------------------------------
% pushbutton_extrema_Callback
% --------------------------------------------------------------------
function varargout = pushbutton_Extrema_Callback(h, eventdata, handles, varargin)
global WAVEFORMS
global SELECTED_DATA_EXTREMA

% Plot selected waveforms
pushbutton_Plot_Callback(h, eventdata, handles, varargin)

% Store selected data in global variable
SELECTED_DATA_EXTREMA = get_selected_data(handles);

% start routine to calculate extrema
extrema;


% --------------------------------------------------------------------
% Callback for Delete button:
% --------------------------------------------------------------------
function varargout = pushbutton_Delete_Callback(h, eventdata, handles, varargin)
global WAVEFORMS

% get selected data
selected_data = get_selected_data(handles);

for i=1:length(selected_data)
    % find index of waveform to be deleted
    j=strmatch(char(selected_data(i).name),char(WAVEFORMS.name),'exact');
    % delete waveform
    WAVEFORMS(j)=[];
end
update_listbox(handles);

% if there are still undeleted waveforms, set the active one to be the first in the list
set(handles.listbox,'Value',length(WAVEFORMS)>0);

% Check which buttons are to be enabled
set_button_enabling(handles);


% --------------------------------------------------------------------
% Callback for Filter button
% --------------------------------------------------------------------
function varargout = pushbutton_filter_Callback(h, eventdata, handles, varargin)
global SELECTED_DATA_FILTER

% get selected data
SELECTED_DATA_FILTER = get_selected_data(handles);

% display error message if selected data contains waveforms with confidence interval
if strmatch('boot',char(SELECTED_DATA_FILTER.type),'exact')
     errordlg('Filtering of data with confidence intervals is not allowed.','Error','modal')
     return
end

% start filter routine
filters



% --------------------------------------------------------------------
% Callback for Baseline button
% --------------------------------------------------------------------
function varargout = pushbutton_baseline_Callback(h, eventdata, handles, varargin)
global SELECTED_DATA_BASELINE

% Store selected data in global variable
SELECTED_DATA_BASELINE = get_selected_data(handles);

% start routine for baseline calculation
baseline


% --------------------------------------------------------------------
function varargout = pushbutton_combine_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
global SELECTED_DATA_COMBINE
SELECTED_DATA_COMBINE = get_selected_data(handles);
% Error message if more than 30 waveforms are selected
if size(SELECTED_DATA_COMBINE,2)>30
    errordlg('The maximum number of waveforms to be combined is 30.','Error','modal')
    return   
end
% Error message if data with confidence interval is selected
if strmatch('boot',char(SELECTED_DATA_COMBINE.type),'exact')
    errordlg('Combination of data with confidence intervals is not allowed.','Error','modal')
    return
end

% Check whether time sweep begin, sampling rate and number of points are equal for all selected waveforms; if not, display error message
for i=1:size(SELECTED_DATA_COMBINE,2)
    tsb(i) = SELECTED_DATA_COMBINE(i).TSB;
    npts(i) = SELECTED_DATA_COMBINE(i).Npts;
    di(i) = SELECTED_DATA_COMBINE(i).DI;
end
for i=1:size(di,2)-1
    if tsb(i)~=tsb(i+1) | npts(i)~=npts(i+1) | di(i)~=di(i+1)
       errordlg('Sampling rate and time epoch must be equal for all waveforms.','Error','modal')
       return
    end
end

% start routine for waveform combination
combine

% --------------------------------------------------------------------
% Exit_Callback (leave the program)
% --------------------------------------------------------------------
function varargout = Exit_Callback(h, eventdata, handles, varargin)
global INITIALDIRECTORY
global WAVEFORMS
global COLORORDER
global SHADED_AREA
close all;

% reset global variable WAVEFORMS
WAVEFORMS = struct([]);

% Change back to initial directory 
cd(INITIALDIRECTORY);

COLORORDER = [];
SHADEDAREA = [];



% --------------------------------------------------------------------
% pushbutton_Save_Callback (save source waveform in .uwf file
% --------------------------------------------------------------------
function varargout = pushbutton_Save_Callback(h, eventdata, handles, varargin)

% get selected data
selected_data_save_uwf = get_selected_data(handles);

% open the MATLAB graphical user interface for choosing the path and name of the .uwf file to be saved
[filename,pathname] = uiputfile([selected_data_save_uwf.name,'.uwf'],'Save waveform');

% stop if no filename is given
if filename == 0
    return;
end

% if filename does not have the extension '.uwf' yet, add it to the filename
[pathstr,name,ext,versn] = fileparts(filename);
if isempty(strmatch(ext,'.uwf','exact'))
    filename = [filename,'.uwf'];
end

% save file if a basename was provided
if isempty(strmatch(name,'','exact'))
    fid = fopen([pathname,filename],'w');
    fprintf(fid,'Npts= %i TSB= %.2f DI= %.5f SB= %.1f SC= %.1f\r\n',selected_data_save_uwf.Npts,selected_data_save_uwf.TSB,...
        selected_data_save_uwf.DI,1,0);
    if strcmp(char(selected_data_save_uwf.type),'single')
        fprintf(fid,'Datapoints: \t');
        fprintf(fid,'%f ',selected_data_save_uwf.data);
        fprintf(fid,'\r\n');
    else
        fprintf(fid,'grand_av: \t');
        fprintf(fid,'%f ',selected_data_save_uwf.data(1,:));
        fprintf(fid,'\ntheta_lo: \t');
        fprintf(fid,'%f ',selected_data_save_uwf.data(2,:));
        fprintf(fid,'\r\ntheta_hi: \t');
        fprintf(fid,'%f ',selected_data_save_uwf.data(3,:));
        fprintf(fid,'\r\n'); 
    end
    fclose(fid);
end



% --------------------------------------------------------------------
% pushbutton_delay_Callback (shift time axis of selected waveforms)
% --------------------------------------------------------------------
function varargout = pushbutton_delay_Callback(h, eventdata, handles, varargin)
global DELAYDATA

% Store selected data in global variable
DELAYDATA = get_selected_data(handles);

% start delay routine
delay



% --------------------------------------------------------------------
% pushbutton_Rename_Callback (rename waveforms)
% --------------------------------------------------------------------
function varargout = pushbutton_Rename_Callback(h, eventdata, handles, varargin)
global OLDNAME

% get selected data
selected_data = get_selected_data(handles);

% store names of selected data in global variable
OLDNAME = selected_data.name;

% start renaming routine
rename


% --------------------------------------------------------------------
% pushbutton_resample_Callback (resample waveform data)
% --------------------------------------------------------------------
function varargout = pushbutton_resample_Callback(h, eventdata, handles, varargin)
global SELECTED_DATA_RESAMPLING

% Store selected data in global variable
SELECTED_DATA_RESAMPLING = get_selected_data(handles);

if strmatch('boot',char(SELECTED_DATA_RESAMPLING.type),'exact')
     errordlg('Resampling of data with confidence intervals is not allowed.','Error','modal')
     return
end

% start resampling routine
resampling


% --------------------------------------------------------------------
% pushbutton_integrate_Callback (calculate area under waveforms)
% --------------------------------------------------------------------
function varargout = pushbutton_integrate_Callback(h, eventdata, handles, varargin)
global SELECTED_DATA_INTEGRATE

% plot selected data
pushbutton_Plot_Callback(h, eventdata, handles, varargin)

% Store selected data in global variable
SELECTED_DATA_INTEGRATE = get_selected_data(handles);

% start routine for area calculation
integrate



% --------------------------------------------------------------------
% menu_edit_Callback (empty)
% --------------------------------------------------------------------
function varargout = menu_edit_Callback(h, eventdata, handles, varargin)


% --------------------------------------------------------------------
% menu_edit_plotoptions_Callback 
% --------------------------------------------------------------------
function varargout = menu_edit_plotoptions_Callback(h, eventdata, handles, varargin)
% start routine for editing plot options
options


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Subfunctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --------------------------------------------------------------------
% Update the listbox to match the current workspace
% --------------------------------------------------------------------
function update_listbox(handles)
global WAVEFORMS
try
    set(handles.listbox,'String',char(WAVEFORMS.name))
    set(handles.listbox,'Value',1)
catch       % if variable WAVEFORMS is empty
    set(handles.listbox,'String',[])
end

% enable the appropriate buttons
set_button_enabling(handles)


% --------------------------------------------------------------------
% Determine which buttons are to be enabled depending on the number and type of selected waveforms
% --------------------------------------------------------------------
function set_button_enabling(handles)
global WAVEFORMS
if isempty(WAVEFORMS)                                   % no waveforms imported
    set(handles.pushbutton_Save,'Enable','Off');
    set(handles.pushbutton_Bootstrap,'Enable','Off');
    set(handles.pushbutton_Delete,'Enable','Off');   
    set(handles.pushbutton_Extrema,'Enable','Off');
    set(handles.pushbutton_Plot,'Enable','Off');   
    set(handles.pushbutton_Rename,'Enable','Off'); 
    set(handles.pushbutton_resample,'Enable','Off'); 
    set(handles.pushbutton_baseline,'Enable','Off');
    set(handles.pushbutton_delay,'Enable','Off');
    set(handles.pushbutton_filter,'Enable','Off');
    set(handles.pushbutton_integrate,'Enable','Off');
    set(handles.pushbutton_combine,'Enable','Off');
elseif size(get(handles.listbox,'Value'),2)==1          % one waveform selected
    set(handles.pushbutton_Save,'Enable','On');
    set(handles.pushbutton_Bootstrap,'Enable','Off');
    set(handles.pushbutton_Delete,'Enable','On');   
    set(handles.pushbutton_Extrema,'Enable','On');
    set(handles.pushbutton_Plot,'Enable','On')
    set(handles.pushbutton_Rename,'Enable','On'); 
    set(handles.pushbutton_resample,'Enable','On'); 
    set(handles.pushbutton_baseline,'Enable','On'); 
    set(handles.pushbutton_delay,'Enable','On');
    set(handles.pushbutton_filter,'Enable','Off');
    set(handles.pushbutton_integrate,'Enable','On');
    set(handles.pushbutton_combine,'Enable','Off');
else                                                    % more than one waveform selected
    set(handles.pushbutton_Save,'Enable','Off');
    set(handles.pushbutton_Bootstrap,'Enable','On');
    set(handles.pushbutton_Delete,'Enable','On');   
    set(handles.pushbutton_Extrema,'Enable','On');
    set(handles.pushbutton_Plot,'Enable','On')
    set(handles.pushbutton_Rename,'Enable','Off'); 
    set(handles.pushbutton_resample,'Enable','On'); 
    set(handles.pushbutton_baseline,'Enable','On'); 
    set(handles.pushbutton_delay,'Enable','On');
    set(handles.pushbutton_filter,'Enable','Off');
    set(handles.pushbutton_integrate,'Enable','On');
    set(handles.pushbutton_combine,'Enable','On');
end


% --------------------------------------------------------------------
% plot_boot: Plot bootstrap data
% --------------------------------------------------------------------
function [] = plot_boot(Npts,TSB,DI,data,ColIndex)      
% Npts: Number of points
% TSB: Time Sweep begin
% DI: Distance
% data: data to be plotted (size 3 x Npts)
% ColIndex: Index of the desired color in the variable COLORORDER
global PLOTFIGURE
global SHADED_AREA
global COLORORDER
hold on;
figure(PLOTFIGURE);

if SHADED_AREA == 0         % confidence interval is plotted as lines
    plot([TSB:DI:TSB+DI*(Npts-1)],squeeze(data(1,:)),'Color',COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:),'LineWidth',1.8) % average
    plot([TSB:DI:TSB+DI*(Npts-1)],squeeze(data(2,:)),'Color',COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:),'LineWidth',1.1) % lower confidence interval limit
    plot([TSB:DI:TSB+DI*(Npts-1)],squeeze(data(3,:)),'Color',COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:),'LineWidth',1.1) % upper confidence interval limit
else                        % confidence interval is plotted as shaded area
    for i=1:Npts
        % determine edges of shaded area
        shaded_area_y(i)=squeeze(data(3,i));
        shaded_area_y(2*fix(Npts)-i+1)=squeeze(data(2,i));
        shaded_area_x(i)=TSB+DI*(i-1);
        shaded_area_x(2*fix(Npts)-i+1)=TSB+DI*(i-1);
    end
    % draw shaded area
    h=patch(shaded_area_x,shaded_area_y,0.6*COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:) + [0.4 0.4 0.4], ...
        'EdgeColor',0.6*COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:) + [0.4 0.4 0.4],'FaceAlpha',0.3,'EdgeAlpha',0.3);
    % plot average waveform
    plot([TSB:DI:TSB+DI*(Npts-1)],squeeze(data(1,:)),'Color',COLORORDER(1+mod(ColIndex-1,max(size(COLORORDER))),:),'LineWidth',1.8)
end


% --------------------------------------------------------------------
% get_selected_data: Get all information of the selected waveforms
% --------------------------------------------------------------------
function [selected_data] = get_selected_data(handles)
global WAVEFORMS

% if no waveforms are imported, no waveform can be selected
if isempty(WAVEFORMS)
    selected_data=[];
    return
end

% get names of all names displayed in the main window
list_entries = get(handles.listbox,'String');
% check which waveforms are selected (Vector with 0 [not selected] and 1 [selected])
index_selected = get(handles.listbox,'Value');
% get names of selected waveforms
var = list_entries(index_selected,:);
% get index in the variable WAVEFORMS of the selected files
index=zeros(1,size(var,1));
for i=1:size(var,1);
    index(i)=strmatch(char(cellstr(char(var(i,:)))),char(WAVEFORMS.name),'exact');
end
% pass all information of the selected waveforms 
selected_data = WAVEFORMS(index);
