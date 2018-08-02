clear;

addpath('H:\');
addpath('H:\prog\');
addpath('H:\data\');
addpath('H:\log\');

delete 'H:\log\log_master_matlab.txt'  %delete old diary/output file

diary 'H:\log\log_master_matlab.txt' %open new diary/output file
diary_status=get(0,'Diary') %Is Diary running?

e=clock;
fprintf('Starting time:   %2.0fh%2.0fm \r\n', e(1,4),e(1,5));

%% Import Data from Stata (convert .csv to .mat format)
importdata

clear;

%% Data Preparation
dprep

%% Maximizing Liklihood Function
dpmaxll
%% Output; Reform Simulation
%sim
sim_short

%% again estimate setting frictions to zero BEFORE estimation


% clear;
% 
% level_fric_new=0;
% fprintf('++++ \r\n');
% fprintf('For comparison: estimate model parameters while setting frictions to %2.2f Percent of previous level. \r\n', level_fric_new.*100);
% fprintf('++++ \r\n');
% 
% load('H:\data\prepdata3.mat');
% for p=1:5
% darr{1,p}.prob_fric=level_fric_new.*darr{1,p}.prob_fric;
% end
% save('H:\data\prepdata3.mat');
% 
% dpmaxll

%% ending time

e=clock;
fprintf('Ending time:   %2.0fh%2.0fm \r\n', e(1,4),e(1,5));


diary off %turn off diary/output-log.

exit;