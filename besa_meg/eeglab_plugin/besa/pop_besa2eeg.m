function [EEG, command] = pop_besa2eeg(filename);

command = '';
EEG=[];

if nargin < 1
    [filename, filepath] = uigetfile('*.dat;*.DAT', 'Select a BESA generic export file');
    drawnow;
    if filename == 0
        return;
    end
end

[pth,nam,ext,ver] = fileparts(fullfile(filepath,filename));
dat = besa_readdat(fullfile(filepath,[nam '.generic']));
%write this:
%pos = besa_readpos(fullfile(filepath,[nam '.pos']));
%also need to add code for epochs/etc.
EEG = eeg_emptyset;
EEG.comments    = ['Original file: ' filename];
EEG.setname     = 'BESA generic binary export data';
EEG.nbchan      = dat.nChannels;
EEG.srate       = dat.sRate;
EEG.pnts        = dat.nSamples;
EEG.filename    = filename;
%EEG.xmin       = 
%EEG.xmax
%EEG.chanlocs   =
EEG.data        = dat.Data;
%if dat.epochs ~= ''
%    epoch.event         = [];
%    epoch.eventlatency  = {};
%    epoch.eventposition = {};
%    epoch.eventtype     = {};
%    epoch.eventurevent  = {};
%    for i=1:data.epochs
%        EEG.epoch(i)    = epoch;
%    end
%end

% Read events file, if it exists
evt = [nam '.evt'];
fp = fopen(evt,'r');
if fp < 0
   disp(['Could not open ',evt,' for input']);
else
    fclose(fp);
    EEG.event = besa_readevt(evt);
    % Convert seconds to sample points
    for i=1:length(EEG.event)
        EEG.event(i).latency = EEG.srate * EEG.event(i).latency + 1;
    end
end

EEG = eeg_checkset(EEG);
return;