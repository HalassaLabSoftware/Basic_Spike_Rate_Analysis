%%
%Overview and Global variable set-up
%Go to the correct session directory before running the code, either before or
%or following clustering.  The full file can then be run from this point
%after setting the parameters in this section.
%close all
clear


initfileVal;% Select the correct initfile

TTLstim1 = 64;  
TTLbehave = 1;%Set the TTLstim.  TTL behave is generally the only important one.

LFPlist = [1];

%Set the session number and the tetrode numbers that were clustered.
session_num = 2;
%all_tt_nums = [1]; %Manual selection of electrode sets to plot

LFPImportSelect = 0;

pre = 0.5;
post = 1.5;

binNum = 120;
xlim_start = -0.5;
xlim_end = 1.5;

cd(Se.folder{session_num})
names = dir('*.cut');

all_tt_nums = [];

for n = 1:length(names)
    nameSU = names(n).name;
    nameSU(strfind(nameSU,'.cut'):length(nameSU)) = [];
    nameSU(1:2) = [];
    all_tt_nums = [all_tt_nums str2num(nameSU)]
end

all_tt_nums = sort(all_tt_nums); %Automatic selection of electrode sets to plot

eventData = read_cheetah_data([Se.folder{session_num} '\Events.Nev'])
i = 0;

TTLstim1 = 64;
TTLbehave = 1;

Lstim.start_time = eventData.ts(find(eventData.TTLval == TTLstim1))';
Lstim.pulse_width = diff(eventData.ts);
Lstim.pulse_width = Lstim.pulse_width(find(eventData.TTLval == TTLstim1))';
L.start_time = eventData.ts(find(eventData.TTLval == TTLbehave))';

f = 1:12:length(Lstim.start_time)%trial selection


%%
%File Name Adapter

names = dir('*.ntt')
newNames = names;

for n = 1:length(names)
    newNames(n).name(1) = 'S';
    newNames(n).name(2) = 'c';
    dos(['rename "' names(n).name '" "' newNames(n).name '"']);
end

names = dir('*.cut')
newNames = names;

for n = 1:length(names)
    newNames(n).name(1) = 'S';
    newNames(n).name(2) = 'c';
    dos(['rename "' names(n).name '" "' newNames(n).name '"']);
end


%%  Auto Import
i = 0;

for n = 1:(length(all_tt_nums))
    curr_tt_num = all_tt_nums(n);
    Sc = spikes(Se,session_num,curr_tt_num);
    is_cluster = 1;
    m = 0;
    while is_cluster == 1
        m = m+1;
        cl_holder = cluster(Sc,m);
        is_full = max(size(cl_holder.timestamp));
        if is_full > 1
            i = i+1;
            eval(sprintf('cl%d = cluster(Sc,m)', i));
            num_seq(i,1:2) = [curr_tt_num m];
        else
            m = m-1;
            is_cluster = 0;
        end
    end
    Sc_unit_count(n,1) = curr_tt_num;
    Sc_unit_count(n,2) = m;
end

clear cl_holder i curr_tt_num is_cluster is_full m n

%%
%Unit Creator

for n = 1:(length(num_seq(:,1)))
eval(['unit' num2str(n) ' = cl' num2str(n) '.timestamp;'])
eval(['unit' num2str(n) ' = unit' num2str(n) ';'])
%eval(['clear cl' num2str(n) ';'])
end

%% LFP import
if LFPImportSelect == 1
for Q = 1:length(LFPlist);
    eval(['lfp' num2str(LFPlist(Q)) ' = eeg(Se,session_num,' ...
        num2str(LFPlist(Q)) ');'])
    eval(['lfp_times = lfp' num2str(LFPlist(Q)) '.timestamp;'])
    eval(['lfp' num2str(LFPlist(Q)) 'D = lfp' num2str(LFPlist(Q)) '.data;'])
    eval(['clear lfp' num2str(LFPlist(Q)) ';'])
end
end
% 
% clear n Se Sc


%%
%psth and raster


for n = 1:length(num_seq) % list of cells included 
figure
    eval(['cl' num2str(n) '_align = align(cl' num2str(n) ',Lstim,f,pre,post);'])
    eval(['clcurr_align = cl' num2str(n) '_align;'])
    eval(['cl = cl' num2str(n) '_align;'])
    
    % Raster
    subplot(1,2,1);
    hold on
    plot(cl,'raster');
    title(['Unit ' num2str(n)]);
    set(gca,'fontsize',12)
    xlim([xlim_start xlim_end])
    ylim([0 clcurr_align.num_trials])

    eval(['cl' num2str(n) '_align = align(cl' num2str(n) ',Lstim,f,pre,post);'])
    eval(['clcurr_align = cl' num2str(n) '_align;'])
    
    % PSTH
    subplot(1,2,2);
    hold on
    
    rectangle(...
    'Position',[0 0 1 500],...
    'FaceColor',[.9 .9 .9],...
    'EdgeColor',[1 1 1])
    h=hist(clcurr_align.timestamp,binNum);
    plot(clcurr_align,'hist','k',binNum);
    xlim([xlim_start xlim_end])
    ylim([0 max(h)])
    title(['Unit ' num2str(n)]);
    set(gca,'fontsize',12)
end
