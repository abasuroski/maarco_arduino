% Read video
videoFile = 'redSquaresTestVideo1.mp4';
videoReader = VideoReader(videoFile);

% Define red color range
redRange = [150, 255]; % Adjust as needed

% Parameters for square detection
minSquareArea = 100; % Minimum area of a square
maxSquareArea = 10000; % Maximum area of a square

% Create a point tracker object
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

% Initialize variables
prevFrame = [];
prevPoints = [];
xPos1 = []; % Rename positionsX to xPos1
yPos1 = []; % Rename positionsY to yPos1
avgDist1 = []; % Rename averageDistances to avgDist1

% Process each frame
while hasFrame(videoReader)
    frame = readFrame(videoReader);
    % Convert to grayscale
    grayFrame = rgb2gray(frame);
    
    % Detect red objects
    redMask = (frame(:,:,1) >= redRange(1)) & (frame(:,:,1) <= redRange(2)) & ...
              (frame(:,:,2) <= 100) & (frame(:,:,3) <= 100);
          
    % Morphological operations to clean up mask
    redMask = imfill(redMask, 'holes');
    redMask = bwareafilt(redMask, [minSquareArea, maxSquareArea]);
    redMask = imclose(redMask, strel('square', 5));
    
    % Find centroids of red squares
    stats = regionprops(redMask, 'Centroid');
    centroids = cat(1, stats.Centroid);
    
    % Calculate distances between adjacent squares (excluding diagonals)
    numSquares = size(centroids, 1);
    distances = [];
    for i = 1:numSquares
        for j = 1:numSquares
            if i ~= j
                % Check if the squares are horizontally or vertically adjacent
                if abs(centroids(i, 1) - centroids(j, 1)) < 1.5 * minSquareArea && ...
                   abs(centroids(i, 2) - centroids(j, 2)) < 1.5 * minSquareArea
                    distances = [distances; norm(centroids(i, :) - centroids(j, :))];
                end
            end
        end
    end
    
    % Calculate average distance between adjacent squares
    averageDistance = mean(distances, 'omitnan'); % Exclude NaN values from calculation
    avgDist1 = [avgDist1; averageDistance]; % Store in avgDist1
    
    % Optical flow tracking
    if ~isempty(prevFrame) && ~isempty(prevPoints)
        release(pointTracker); % Release the point tracker object
        initialize(pointTracker, prevPoints, prevFrame);
        [nextPoints, validity] = pointTracker(grayFrame);
        
        % Calculate displacements
        displacement = nextPoints(validity, :) - prevPoints(validity, :);
        
        % Update positions
        xPos1 = [xPos1; xPos1(end) + displacement(:, 1)]; % Store in xPos1
        yPos1 = [yPos1; yPos1(end) + displacement(:, 2)]; % Store in yPos1
    else
        % Initialize positions at (0,0) for the first frame
        xPos1 = zeros(size(centroids, 1), 1); % Store in xPos1
        yPos1 = zeros(size(centroids, 1), 1); % Store in yPos1
    end
    
    % Store current frame and points for next iteration
    prevFrame = grayFrame;
    prevPoints = centroids;

    % Display
    imshow(frame);
    hold on;
    if ~isempty(centroids)
        plot(centroids(:,1), centroids(:,2), 'r*');
    end
    hold off;
    title('Red Square Tracking');
    
    % Pause for visualization
    pause(0.1);
end

% Save variables to a MAT file
save('red_square_data1.mat', 'xPos1', 'yPos1', 'avgDist1','videoFile');

% Plot x position over time
figure;
plot(1:numel(xPos1), xPos1);
xlabel('Frame');
ylabel('X Position');
title('Object X Position Over Time');

% Plot y position over time
figure;
plot(1:numel(yPos1), yPos1);
xlabel('Frame');
ylabel('Y Position');
title('Object Y Position Over Time');

% Plot average distance between adjacent squares
figure;
plot(1:numel(avgDist1), avgDist1);
xlabel('Frame');
ylabel('Average Distance (pixels)');
title('Average Distance Between Adjacent Red Squares (Excluding Diagonals)');
