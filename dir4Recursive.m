function [BWcpy, BWline, cnt] = dir4Recursive(BWcpy, BWline, x, y, sizeX, sizeY, cnt, mode)
% mode = 0 -> count
% mode = 1 -> paint
if x < 1 || x > sizeX || y < 1 || y > sizeY
elseif BWline(y, x) == 0
elseif BWcpy(y, x) == 0
else
    if mode == 0
        BWcpy(y, x) = 0;
        cnt = cnt + 1;
    else
        BWcpy(y, x) = 0;
        BWline(y, x) = cnt + 100;       
    end
    [BWcpy, BWline, cnt] = dir4Recursive(BWcpy, BWline, x, y-1, sizeX, sizeY, cnt, mode);
    [BWcpy, BWline, cnt] = dir4Recursive(BWcpy, BWline, x-1, y, sizeX, sizeY, cnt, mode);
    [BWcpy, BWline, cnt] = dir4Recursive(BWcpy, BWline, x+1, y, sizeX, sizeY, cnt, mode);
    [BWcpy, BWline, cnt] = dir4Recursive(BWcpy, BWline, x, y+1, sizeX, sizeY, cnt, mode); 
end
