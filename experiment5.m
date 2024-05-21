% Load the image
I = imread('sprayPaintedSquares.jpg');

% Extract red channel
redChannel = I(:,:,1);
greenChannel = I(:,:,2);
blueChannel = I(:,:,3);

% Thresholding to detect red regions
redThreshold = redChannel > 150 & greenChannel < 100 & blueChannel < 100;

% Remove small noise
redThreshold = bwareaopen(redThreshold, 100);

% Fill holes
redThresholdFilled = imfill(redThreshold, 'holes');

% Label connected components
connectedComponents = bwlabel(redThresholdFilled);

% Get properties of connected components
stats = regionprops(connectedComponents, 'BoundingBox');

% Merge adjacent bounding boxes
mergedBoundingBoxes = mergeBoundingBoxesRed(stats);

% Filter out rectangles with aspect ratios significantly different from 1:1
aspectRatioThreshold = 2; % Adjust this threshold as needed
validIndices = abs(1 - [mergedBoundingBoxes(:,3) ./ mergedBoundingBoxes(:,4)]) < aspectRatioThreshold;
mergedBoundingBoxes = mergedBoundingBoxes(validIndices, :);

% Display original image
imshow(I); hold on;

sizes=[]
% Draw merged bounding boxes
for cnt = 1:size(mergedBoundingBoxes, 1)
    bb = mergedBoundingBoxes(cnt,:);
    r=rectangle('Position', bb, 'EdgeColor', 'b', 'LineWidth', 2);
    sizes=[sizes; r.Position(3:4)];
end

fprintf("The largest square is %d and the largest square is %d", identifySmallestLargestRectangles(sizes))
hold off;

% Define mergeBoundingBoxesRed function
function mergedBoundingBoxes = mergeBoundingBoxesRed(stats)
    numStats = numel(stats);
    boundingBoxes = cat(1, stats.BoundingBox);
    mergedBoundingBoxes = boundingBoxes(1,:);
    mergedCount = 1;
    
    for i = 2:numStats
        currentBB = stats(i).BoundingBox;
        isMerged = false;
        for j = 1:mergedCount
            mergedBB = mergedBoundingBoxes(j,:);
            if isClose(currentBB, mergedBB)
                mergedBoundingBoxes(j,:) = mergeBoundingBoxes(mergedBB, currentBB);
                isMerged = true;
                break;
            end
        end
        if ~isMerged
            mergedCount = mergedCount + 1;
            mergedBoundingBoxes(mergedCount,:) = currentBB;
        end
    end
end

% Define function to check if two bounding boxes are close
function result = isClose(bb1, bb2)
    distanceThreshold = 100; % Adjust this threshold as needed
    center1 = [bb1(1) + bb1(3)/2, bb1(2) + bb1(4)/2];
    center2 = [bb2(1) + bb2(3)/2, bb2(2) + bb2(4)/2];
    distance = norm(center1 - center2);
    result = distance < distanceThreshold;
end

% Define mergeBoundingBoxes function
function mergedBB = mergeBoundingBoxes(bb1, bb2)
    x1 = min(bb1(1), bb2(1));
    y1 = min(bb1(2), bb2(2));
    x2 = max(bb1(1) + bb1(3), bb2(1) + bb2(3));
    y2 = max(bb1(2) + bb1(4), bb2(2) + bb2(4));
    
    mergedBB = [x1, y1, x2 - x1, y2 - y1];
end

function [smallestRect, largestRect] = identifySmallestLargestRectangles(rectangles)
    % Compute the areas of all rectangles
    areas = rectangles(:, 1) .* rectangles(:, 2);
    
    % Find the index of the smallest rectangle by area
    [~, smallestIndex] = min(areas);
    
    % Find the index of the largest rectangle by area
    [~, largestIndex] = max(areas);
    
    % Retrieve the smallest and largest rectangles
    smallestRect = rectangles(smallestIndex, :);
    largestRect = rectangles(largestIndex, :);
end
