
function [] = h5plot(varargin)
% h5plot Plots an the output of a SLURM native profiling HDF5 file.
% Plots the HDF5 outputs from SLURM native profiling.
% Callum Walley 2019
% V2.2

%% Usage
% Run in directory containing .hd5 files. [h5plot()]
% Or, input path to file or containing folder.  [h5plot('data1.h5','data2.h5','all_other_data/')]

%% Settings
% Plot all on same figure?
multiplot=true;

% Plot I/O cumulatively.
cumulativeio=false;

% Whether to use exponential y-axis
% [IO, MaxRSS, CPU util]
exponent=[0,0,0];

% Do you have taste?
goodcolors=true;
   
%% Get inputs
% If no input, use this directory.
if ~nargin
    fprintf('No input given...\nLooking for .h5 files on path...\n');
    default_filelist=struct2cell(dir('*.h5'));
    varargin=default_filelist(1,:);
end

% Expand folders
for i=1:length(varargin)
    if exist(varargin{i})==7
        disp('Expanding Folder...');
        addpath(varargin{i});
        default_filelist=struct2cell(dir([varargin{i},'/*.h5']));
        varargin=[varargin, default_filelist(1,:)];
    end
end
hdat=[];
%% Validate
for i=1:length(varargin)
    if exist(varargin{i})==2
        try
            nicename=strsplit(varargin{i},'.');
            hinfo=h5info(varargin{i});
            hdat.(nicename{end-1})=h5read(varargin{i}, [hinfo.Groups(1).Groups(1).Groups(1).Groups(1).Groups(1).Name, '/0']);
        end
    end
end
if length(hdat)<1
    if ~nargin
        disp('No valid .h5 on path.');
        return
    else
        disp('No valid .h5 files specified');
        return
    end
end

index=fieldnames(hdat);

disp(['Plotting ', num2str(length(index)), ' dataset(s)...']);
    %disp('No input given, looking for .h5 files on path.');
    %return

%% Plot
if multiplot
    figure('Name',strjoin(index));
end


if goodcolors
    colorScale=rand(length(index),3);
else
    colorScale=hsv(length(index));   
end



for i=1:length(index)

if ~multiplot
    figure('Name',index{i});
end

%% I/O
subplot(3,1,1);
hold on;
x_dat1=hdat.(index{i}).WriteMB;
x_dat2=hdat.(index{i}).ReadMB;
y_dat=hdat.(index{i}).ElapsedTime;

if cumulativeio
    x_dat1=cumsum(x_dat1);
    x_dat2=cumsum(x_dat2);
    ylabel('MB');
else
    ylabel('MB/s');
end

plot(y_dat,x_dat1,y_dat,-x_dat2,'DisplayName','ReadMB','color',colorScale(i,:));
title('I/O');
if exponent(1), set(gca, 'YScale', 'log'), end

%% RSS
subplot(3,1,2);
hold on
plot(hdat.(index{i}).ElapsedTime,hdat.(index{i}).RSS/1000000,'DisplayName','hdat.RSS','color',colorScale(i,:));

title('Memory');
ylabel('GB');
if exponent(2), set(gca, 'YScale', 'log'), end

%% CPUutil
subplot(3,1,3);
hold on;
plot(hdat.(index{i}).ElapsedTime,(hdat.(index{i}).CPUUtilization/100),'DisplayName','CPUUtilization','color',colorScale(i,:));
ylabel('Logical CPUs');
title('CPU util');
if exponent(3), set(gca, 'YScale', 'log'), end

end

if multiplot
    legend(index);
end 
disp('Done!');
end
