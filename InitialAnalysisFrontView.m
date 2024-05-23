% Read video
videoFile = 'redSquaresTestVideo1.mp4';
videoReader = VideoReader(videoFile);

% Define yellow/green color range
yellowGreenRange = [100, 200]; % Adjust as needed

% Parameters for square detection
minSquareArea = 100; % Minimum area of a square
maxSquareArea = 10000; % Maximum area of a square

% Create a point tracker object
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

% Initialize variables
prevFrame = [];
prevPoints = [];
zPos2 = []; % Rename positionsX to zPos2
yPos2 = []; % Rename positionsY to yPos2
avgDist2 = []; % Rename averageDistances to avgDist2

% Process each frame
while hasFrame(videoReader)
    frame = readFrame(videoReader);
    % Convert to grayscale
    grayFrame = rgb2gray(frame);
    
    % Detect yellow/green objects
    yellowGreenMask = (frame(:,:,1) >= yellowGreenRange(1)) & (frame(:,:,1) <= yellowGreenRange(2)) & ...
                      (frame(:,:,2) >= yellowGreenRange(1)) & (frame(:,:,2) <= yellowGreenRange(2)) & ...
                      (frame(:,:,3) <= 100); % Assuming low blue component for yellow/green
              
    % Morphological operations to clean up mask
    yellowGreenMask = imfill(yellowGreenMask, 'holes');
    yellowGreenMask = bwareafilt(yellowGreenMask, [minSquareArea, maxSquareArea]);
    yellowGreenMask = imclose(yellowGreenMask, strel('square', 5));
    
    % Find centroids of yellow/green squares
    stats = regionprops(yellowGreenMask, 'Centroid');
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
    avgDist2 = [avgDist2; averageDistance]; % Store in avgDist2
    
    % Optical flow tracking
    if ~isempty(prevFrame) && ~isempty(prevPoints)
        release(pointTracker); % Release the point tracker object
        initialize(pointTracker, prevPoints, prevFrame);
        [nextPoints, validity] = pointTracker(grayFrame);
        
        % Calculate displacements
        displacement = nextPoints(validity, :) - prevPoints(validity, :);
        
        % Update positions
        zPos2 = [zPos2; zPos2(end) + displacement(:, 1)]; % Store in zPos2
        yPos2 = [yPos2; yPos2(end) + displacement(:, 2)]; % Store in yPos2
    else
        % Initialize positions at (0,0) for the first frame
        zPos2 = zeros(size(centroids, 1), 1); % Store in zPos2
        yPos2 = zeros(size(centroids, 1), 1); % Store in yPos2
    end
    
    % Store current frame and points for next iteration
    prevFrame = grayFrame;
    prevPoints = centroids;

    % Display
    imshow(frame);
    hold on;
    if ~isempty(centroids)
        plot(centroids(:,1), centroids(:,2), 'g*'); % Use green '*' for visualization
    end
    hold off;
    title('Yellow/Green Square Tracking');
    
    % Pause for visualization
    pause(0.1);
end

% Save variables to a MAT file
save('yellow_square_data2.mat', 'zPos2', 'yPos2', 'avgDist2');
