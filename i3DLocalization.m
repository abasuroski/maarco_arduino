% Convert pixel distances to inches using known square size and distance
squareSizeInches = 2; % Size of the squares on the robot in inches
distanceBetweenSquaresInches = 0.96; % Distance between squares in inches

% Known parameters from the IMU sensor and setup
cameraHeight = 20; % Example height in inches from the pool
%load file with IMU data 
FID=fopen('textfile') ;%change to the name of the text file 
for i=1:10
    fgetl(FID);
end


% Angle vectors from the IMU (in degrees)
for i=10:4:length(FID)
    yaw = [yaw;fgetl(FID)];
    pitch = [pitch;fgetl(FID)];
    roll = [roll;fgetl(FID)];
end
 % Replace with actual yaw data
 % Replace with actual pitch data
 % Replace with actual roll data

%These should be imported 
% Positions and average distances from the initial analysis
% xPos1 = [10, 20, 30]; % Replace with actual x position data from camera 1
% yPos1 = [10, 20, 30]; % Replace with actual y position data from camera 1
% avgDist1 = [100, 105, 110]; % Replace with actual avg distance data from camera 1
% 
% zPos2 = [10, 20, 30]; % Replace with actual z position data from camera 2
% yPos2 = [10, 20, 30]; % Replace with actual y position data from camera 2
% avgDist2 = [100, 105, 110]; % Replace with actual avg distance data from camera 2

% Convert average distances to real-world distances (inches)
avgDist1_inches = avgDist1 / avgDist1(1) * distanceBetweenSquaresInches;
avgDist2_inches = avgDist2 / avgDist2(1) * distanceBetweenSquaresInches;

% Convert pixel positions to inches (assuming initial positions are at (0,0))
xPos1_inches = xPos1 / avgDist1(1) * distanceBetweenSquaresInches;
yPos1_inches = yPos1 / avgDist1(1) * distanceBetweenSquaresInches;
zPos2_inches = zPos2 / avgDist2(1) * distanceBetweenSquaresInches;
yPos2_inches = yPos2 / avgDist2(1) * distanceBetweenSquaresInches;

% Initialize final positions
X = zeros(size(xPos1));
Y = zeros(size(yPos1));
Z = zeros(size(zPos2));

% Convert camera frame coordinates to pool frame using IMU angles
for i = 1:length(xPos1)
    % Convert angles to radians
    yawRad = deg2rad(yaw(i));
    pitchRad = deg2rad(pitch(i));
    rollRad = deg2rad(roll(i));
    
    % Rotation matrix for yaw, pitch, and roll
    R = [cos(yawRad) * cos(pitchRad), cos(yawRad) * sin(pitchRad) * sin(rollRad) - sin(yawRad) * cos(rollRad), cos(yawRad) * sin(pitchRad) * cos(rollRad) + sin(yawRad) * sin(rollRad);
         sin(yawRad) * cos(pitchRad), sin(yawRad) * sin(pitchRad) * sin(rollRad) + cos(yawRad) * cos(rollRad), sin(yawRad) * sin(pitchRad) * cos(rollRad) - cos(yawRad) * sin(rollRad);
         -sin(pitchRad), cos(pitchRad) * sin(rollRad), cos(pitchRad) * cos(rollRad)];
    
    % Transform coordinates
    pos1 = R * [xPos1_inches(i); yPos1_inches(i); cameraHeight];
    pos2 = R * [zPos2_inches(i); yPos2_inches(i); cameraHeight];
    
    % Store transformed positions
    X(i) = pos1(1);
    Y(i) = pos1(2);
    Z(i) = pos2(3);
end

% Calculate overall distance traveled
distanceTraveled = sum(sqrt(diff(X).^2 + diff(Y).^2 + diff(Z).^2));

% Display results
disp(['Overall distance traveled: ', num2str(distanceTraveled), ' inches']);

% Plot positions
figure;
plot3(X, Y, Z);
xlabel('X Position (inches)');
ylabel('Y Position (inches)');
zlabel('Z Position (inches)');
title('3D Position Over Time');
grid on;

fileTitle=strcat(videoFile(1:end-4),'_3D_Data.txt');

% Save variables to a text file
fid = fopen(fileTitle, 'w');
fprintf(fid, 'distanceTraveled: %f inches\n', distanceTraveled);
fprintf(fid, 'xPos1_inches: ');
fprintf(fid, '%f ', xPos1_inches);
fprintf(fid, '\n');
fprintf(fid, 'zPos2_inches: ');
fprintf(fid, '%f ', zPos2_inches);
fprintf(fid, '\n');
fprintf(fid, 'yPos1_inches: ');
fprintf(fid, '%f ', yPos1_inches);
fclose(fid);
save(fileTitle, 'xPos1_inches', 'zPos2_inches', 'yPos1_inches','distanceTraveled');
