function AccelRead(FileName,threshold,plotson)
% % AccelRead(FileName,{plotson})
% ----Accelerometer Reader----
% Reads in data from the biostamp reader, and does a whole bunch of stuff
% to it, including transforming all of the movement and acceleration to a
% fixed extrinsic frame.x
% 
% ---Inputs---
%   FileName = file with all of the biostamp data
%   plotson = optional variable that tells the function whether or not to
%       plot everything


% sets plotson to 1 if no input is given
switch nargin
    case 1
        threshold = .001;
        plotson = 1;
    case 2
        plotson = 1;
end


% Setting up all of the labels for biostamp data in
labels(1,:) = {'Time','X Axis Acceleration','Y Axis Acceleration',...
    'Z Axis Acceleration','Roll Velocity','Pitch Velocity','Yaw Velocity'};
labels(2,:) = {'seconds' 'g' 'g' 'g' 'deg/s' 'deg/s' 'deg/s'};

% Read in all of the data, set up some data structures - Biostamp is
% everything read out, without any coordinate changes, Location is
% everything in terms of a space frame -> that's basically just the first
% point where accel = gravity;
data.num = xlsread(FileName,'','','basic');
Biostamp = struct('time',data.num(:,1),'accel',[],'gyro',[],'roll',[],'pitch',[],'yaw',[]);
Location = struct('xyz',[],'vel',[],'ang',[]);



% 2^16 -> 2000 deg/sec and 4G, correcting labels
Biostamp.accel = 4*(data.num(:,2:4))/2^15;
Biostamp.gyro = 2000*(data.num(:,5:7))/2^15;



% Finding all doz arithmatic means
len = length(Biostamp.time);
len_el = len - 10; %Get rid of first 10 points
AccelMean = sqrt(Biostamp.accel(11:end,1).^2 + ...
    Biostamp.accel(11:end,2).^2 + Biostamp.accel(11:end,3).^2);
RollVelMean = sum(Biostamp.gyro(11:end,1))/len_el
PitchVelMean = sum(Biostamp.gyro(11:end,2))/len_el
YawVelMean = sum(Biostamp.gyro(11:end,3))/len_el



% Finding the roll, pitch, and yaw; without drift
Biostamp.roll(1) = 0; Biostamp.pitch(1) = 0; Biostamp.yaw(1) = 0;
for i=1:len_el-1
    Biostamp.roll(i+1) = (Biostamp.gyro(i+10,1)-RollVelMean)*.004 + Biostamp.roll(i);
    Biostamp.pitch(i+1) = (Biostamp.gyro(i+10,2)-PitchVelMean)*.004 + Biostamp.pitch(i);
    Biostamp.yaw(i+1) = (Biostamp.gyro(i+10,3)-YawVelMean)*.004 + Biostamp.yaw(i);
end


% Finding indices of locations where magnitude of acceleration is under a
% certain threshold and ang vel is ~ 0
AMinInd = find(abs(AccelMean-1) < threshold);
WMinInd = find((Biostamp.gyro(:,1)-RollVelMean).^2 + (Biostamp.gyro(:,2)-PitchVelMean).^2 ...
    + (Biostamp.gyro(:,3)-YawVelMean).^2);
AnotherIndVector = [];

for i=AMinInd
    if any(WMinInd==i)
        AnotherIndVector = [AnotherIndVector,i];
    end
end

[~,StartInd] = min(AnotherIndVector);
        





% Plotting the current roll, pitch and yaw from the body frame, and all of
% the initial plots of accel and gyros
if plotson == 1
    PlotRollPitchYaw(Biostamp)
    PlotInitData(Biostamp,labels)
end

end


function PlotRollPitchYaw(Biostamp)
% does exactly what it says - plots the roll, pitch and yaw of the
% biostamp. Since it's just the first integral of the gyro, it doesn't
% really matter what frame it's in.
    figure
    subplot(1,3,1)
    plot(Biostamp.time(11:end,1),Biostamp.roll)
    title('corrected roll')
    xlabel('time (s)')
    ylabel('roll (deg)')
    axis([0 250 -90 90])
    axis square
    subplot(1,3,2)
    plot(Biostamp.time(11:end,1),Biostamp.pitch)
    title('corrected pitch')
    xlabel('time (s)')
    ylabel('pitch (deg)')
    axis([0 250 -90 90])
    axis square
    subplot(1,3,3)
    plot(Biostamp.time(11:end,1),Biostamp.yaw)
    title('corrected yaw')
    xlabel('time (s)')
    ylabel('yaw (deg)')
    axis([0 250 -90 90])
    axis square

end

function PlotInitData(Biostamp,labels)
% Quick function to plot all of the initial data from the inputs - linear
% acceleration and rotational velocity in terms of time.

figure

for i = 1:3
    subplot(2,3,i)
    plot(Biostamp.time,Biostamp.accel(:,i))
    title(labels(1,i+1))
    xlabel('time (s)')
    ylabel(labels(2,i+1))
    axis([0 250 -2 2])
    axis square
end

for i = 1:3
    subplot(2,3,i+3)
    plot(Biostamp.time,Biostamp.gyro(:,i))
    title(labels(1,i+4))
    xlabel('time (s)')
    ylabel(labels(2,i+4))
    axis([0 250 -400 400])
    axis square
end



end