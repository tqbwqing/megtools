function hnd = besa_tftplot(fullpath2tfc,chnlbl,xrange,yrange)
%PURPOSE:           plot a BESA produced Time-Frequency Transform (*.tfc file)
%REQUIRED INPUTS:   fullpath2tfc = time-frequency ascii file from besa (*.tfc)
%                   chnlbl = a channel to plot.  Can be either a label or
%                   the text 'avg' or 'std', which will produce averages or
%                   standard deviations, respectively, of the channels in
%                   the file
%OPTIONAL INPUTS:   xrange = a vector (e.g., [-5 50]) of times to plot
%                   yrange = a vector (e.g., [8 12]) of frequencies to plot
%OUTPUT:            hnd = file handle, in case you want to use it to modify the
%                   plot from the MATLAB command line
%USAGE:             (1) x=besa_tftplot('file.tfc','A001'); will plot channel A001 from
%                   file.tfc - all frequencies and times will plot
%                   (2) x=besa_tftplot('file.tfc','Cz',[-100 100],[7 80]); will plot
%                   channel Cz from file.tfc from -100 to 100 ms and 7 to 80 Hz.
%                   See note below, however!
%                   (3) x=besa_tftplot('file.tfc','avg'); will plot the
%                   mean tft from all channels in file, etc.
%NOTES:             (1) function will round up/down requested sample mins and maxs to
%                   match an actual sample point in file.  If you don't
%                   like the point chosen, choose the actual one from the
%                   file rather than guessing!
%                   (2) currently, if you want to give one of the optional args,
%                   you must give both of them
%                   (3) most properties of the resulting plot can easily be
%                   changed in the gui plot interface
%AUTHOR:            Donald C. Rojas, Ph.D., U. of Colorado Health Sciences Center
%VERSION HISTORY:   02/01/2007  v1: First working version of program
%                   02/02/2007  Fixed bug with channel label logic and
%                   added standard deviation feature.

%check and open file or simply pass structure
if ischar(fullpath2tfc)
    tft = readBESAtfc(fullpath2tfc);
elseif isstruct(fullpath2tfc)
    tft = fullpath2tfc;
end
%need to do conversions between sample points and time/frequency so it will
%be transparent to the user
xmin = min(tft.Time);
xmax = max(tft.Time);
xsize = length(tft.Time);
xint = tft.Time(2)-tft.Time(1);
ymin = min(tft.Frequency);
ymax = max(tft.Frequency);
ysize = length(tft.Frequency);
yint = tft.Frequency(2)-tft.Frequency(1);
if strcmp(chnlbl,'avg')
    stat = mean(tft.Data);
    name = 'Average TFT';
    disp('Plotting mean of channels');
    chn = 1;
elseif strcmp(chnlbl,'std')
    stat = std(tft.Data);
    name = 'Standard Deviation TFT';
    disp('Plotting standard deviation of channels');
    chn = 1;
else
    chn = strmatch(chnlbl,tft.ChannelLabels);
    if isempty(chn)
        disp('There is no channel in file by that name. Using first channel.');
        disp(tft.ChannelLabels);
        chn = 1;
    end
end

if (nargin == 4)
    %round up all requested ranges to nearest actual sample
    xminrem=mod(xrange(1),xint);
    xmaxrem=mod(xrange(2),xint);
    yminrem=mod(yrange(1),yint);
    ymaxrem=mod(yrange(2),yint);
    if (xminrem ~= 0)
        if (sign(xrange(1)) == 1)
            xrange(1) = xrange(1) - (sign(xrange(1))*mod(xrange(1),xint));
        else
            xrange(1) = xrange(1) + (sign(xrange(1))*mod(xrange(1),xint));
        end
        disp(sprintf('Requested xmin rounded to: %i', xrange(1)));
    end
    if (xmaxrem ~= 0)
        if (sign(xrange(1)) == 1)
            xrange(2) = xrange(2) - (sign(xrange(2))*mod(xrange(2),xint));
        else
            xrange(2) = xrange(2) + (sign(xrange(2))*mod(xrange(2),xint));
        end
        disp(sprintf('Requested xmax rounded to: %i', xrange(2)));
    end     
    if (yminrem ~= 0)
        if (sign(yrange(1)) == 1)
            yrange(1) = yrange(1) - (sign(yrange(1))*mod(yrange(1),yint));
        else
            yrange(1) = yrange(1) + (sign(yrange(1))*mod(yrange(1),yint));
        end
        disp(sprintf('Requested ymin rounded to: %i', yrange(1)));
    end     
    if (ymaxrem ~= 0)
        if (sign(yrange(2)) == 1)
            yrange(2) = yrange(2) - (sign(yrange(2))*mod(yrange(2),yint));
        else
            yrange(2) = yrange(2) + (sign(yrange(2))*mod(yrange(2),yint));
        end
        disp(sprintf('Requested ymax rounded to: %i', yrange(2)));
    end
    %calculate plot points
    xplotmin = round((abs(xmin - xrange(1))/xint)) + 1;
    xplotmax = round((abs(xmin - xrange(2))/xint)) + 1;
    yplotmin = round((abs(ymin - yrange(1))/yint)) + 1;
    yplotmax = round((abs(ymin - yrange(2))/yint)) + 1;
end
%do the plotting
if (nargin == 2)
    X = linspace(xmin, xmax, xsize);
    Y = linspace(ymin, ymax, ysize);
    if or(strcmp(chnlbl,'avg'), strcmp(chnlbl,'std'))
        [C, hnd] = contourf(X,Y,squeeze(stat(chn,:,:))',100);
    else
        [C, hnd] = contourf(X,Y,squeeze(tft.Data(chn,:,:))',100);
    end
elseif (nargin == 4)
    X = linspace(xrange(1), xrange(2), xplotmax-xplotmin+1);
    Y = linspace(yrange(1), yrange(2), yplotmax-yplotmin+1);
    if or(strcmp(chnlbl,'avg'), strcmp(chnlbl,'std'))
        [C, hnd] = contourf(X,Y,squeeze(stat(chn,xplotmin:xplotmax,yplotmin:yplotmax))',100);
    else
        [C, hnd] = contourf(X,Y,squeeze(tft.Data(chn,xplotmin:xplotmax,yplotmin:yplotmax))',100);
    end
end
%set(hnd,'LevelListMode','manual');
%set(hnd,'LevelStepMode','manual');
%set(hnd,'LevelStep',.05);
set(hnd,'LineColor','none');

if or(strcmp(chnlbl,'avg'), strcmp(chnlbl,'std'))
    title(name);
else
    title(tft.ChannelLabels(chn,:));
end
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
cbar=colorbar();
set(get(cbar, 'Title'), 'String', '%')