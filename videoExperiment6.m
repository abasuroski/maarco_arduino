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
positionsX = [];
positionsY = [];
averageDistances = [];

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
    distances = zeros(numSquares - 1, 1);
    for i = 1:numSquares - 1
        % Calculate distance only if squares are horizontally or vertically adjacent
        if abs(centroids(i, 1) - centroids(i + 1, 1)) < 1.5 * minSquareArea && ...
           abs(centroids(i, 2) - centroids(i + 1, 2)) < 1.5 * minSquareArea
            distances(i) = norm(centroids(i, :) - centroids(i + 1, :));
        else
            distances(i) = NaN; % Set distance to NaN if squares are diagonally adjacent
        end
    end
    
    % Calculate average distance between adjacent squares
    averageDistance = mean(distances, 'omitnan'); % Exclude NaN values from calculation
    averageDistances = [averageDistances; averageDistance];
    
    % Optical flow tracking
    if ~isempty(prevFrame) && ~isempty(prevPoints)
        release(pointTracker); % Release the point tracker object
        initialize(pointTracker, prevPoints, prevFrame);
        [nextPoints, validity] = pointTracker(grayFrame);
        
        % Calculate displacements
        displacement = nextPoints(validity, :) - prevPoints(validity, :);
        
        % Update positions
        positionsX = [positionsX; positionsX(end) + displacement(:, 1)];
        positionsY = [positionsY; positionsY(end) + displacement(:, 2)];
    else
        % Initialize positions at (0,0) for the first frame
        positionsX = zeros(size(centroids, 1), 1);
        positionsY = zeros(size(centroids, 1), 1);
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

% Plot x position over time
figure;
plot(1:numel(positionsX), positionsX);
xlabel('Frame');
ylabel('X Position');
title('Object X Position Over Time');

% Plot y position over time
figure;
plot(1:numel(positionsY), positionsY);
xlabel('Frame');
ylabel('Y Position');
title('Object Y Position Over Time');

% Plot average distance between adjacent squares
figure;
plot(1:numel(averageDistances), averageDistances);
xlabel('Frame');
ylabel('Average Distance (pixels)');
title('Average Distance Between Adjacent Red Squares (Excluding Diagonals)');
