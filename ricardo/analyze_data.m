filename = 'E:\Data-lab1\12A1-Jango\CerebusData\Adaptation\2014_03_14\Jango_WF_Adapt_2014_03_14_161137_';
delimiter = ' ';
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
fileID = fopen([filename 'data.txt'],'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN, 'ReturnOnError', false);
fclose(fileID);
data = [dataArray{1:end-1}];
load([filename 'params.mat'])
clearvars filename delimiter formatSpec fileID dataArray ans;

t = data(:,1);
F = [data(:,strcmp(headers,'F_x')) data(:,strcmp(headers,'F_y'))];
X = [data(:,strcmp(headers,'pred_x')) data(:,strcmp(headers,'pred_y'))];
force_mag = sqrt(F(:,1).^2+F(:,2).^2);
displacement = sqrt(X(:,1).^2+X(:,2).^2);
speed = [0;diff(displacement)./diff(t)];

EMG_chans = ~cellfun(@isempty,cellfun(@strfind,headers,repmat({'EMG'},size(headers)),'UniformOutput',false));
EMG_data = data(:,EMG_chans);

figure; 
subplot(311)
plot(t,EMG_data)
xlim([60 120])
ylabel('EMG (norm)')
subplot(312)
plot(t,force_mag)
xlim([60 120])
ylabel('Force magnitude (N)')
subplot(313)
plot(t,displacement)
xlim([60 120])
ylabel('Displacement (cm)')
xlabel('t (s)')
