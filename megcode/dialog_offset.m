function out = dialog_offset(varargin)
f = figure('Units','Normalized',...
'Position',[.4 .4 .3 .3],...
'NumberTitle','off',...
'Name','Offset Correction','MenuBar','None');
e1 = uicontrol('Style','Edit',...
'Units','Normalized',...
'Position',[.6 .6 .3 .1],...
'Tag','myedit');
e2 = uicontrol('Style','Edit',...
'Units','Normalized',...
'Position',[.6 .3 .3 .1],...
'Tag','myedit');
t1 = uicontrol('Style','Text',...
'Units','Normalized',...
'Position',[.1 .6 .3 .1],...
'Tag','myedit','String','Start offset (ms)');
t2 = uicontrol('Style','Text',...
'Units','Normalized',...
'Position',[.1 .3 .3 .1],...
'Tag','myedit','String','Stop offset (ms)');
p = uicontrol('Style','PushButton',...
'Units','Normalized',...
'Position',[.7 .1 .2 .1],...
'String','OK',...
'CallBack','uiresume(gcbf)');
if nargin ~= 0
    offsets = varargin{1};
    set(e1,'String',num2str(offsets(1)));
    set(e2,'String',num2str(offsets(2)));
end
uiwait(f)
out.baseline(1) = str2num(get(e1,'String'));
out.baseline(2) = str2num(get(e2,'String'));
close(f)