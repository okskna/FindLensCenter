clear
MAG = 1; % 5M * MAG = image size -> MAG는 5M 이미지의 배율을 의미, 원본 그대로 할 경우 1
         % MAG를 바꿀 경우 edge 검출 함수에서의 parameter를 실험을 통해 바꿔주는것을 추천함
PARA_ravg_gap = 15; % 원의 반지름 절대값 차이 parameter
save_lens_centers = [];
save_xcyc = [];
save_r = [];
for imgcnt = 1:7 % 1.jpeg ~ 7.jpeg
    tic
    %% 이미지 불러오기
    mystring = "5M Image\" + imgcnt + '.jpeg';
    img = imread(char(mystring));
    img = rgb2gray(img);

%     [BW,threshOut] = edge(img, 'Roberts', 0.003); %%%%%%%% -> MAG = 4 
    [BW,threshOut] = edge(img, 'Roberts', 0.04); %%%%%%%% -> MAG = 1 
    [sizeY, sizeX] = size(BW);
    
    %% 인식원 좌표 찾기, 인식원 좌표를 이용하여 대략적인 렌즈 중심 찾기
    rateX1 = (sizeX * 0.25);
    rateX2 = (sizeX * 0.775);
    rateY1 = (sizeY * 0.39375);
    rateY2 = (sizeY * 0.60625);
    
    tempBW = BW(:, 1:int16(rateX1));
    tempBW = tempBW(int16(rateY1):int16(rateY2), :);

    [centers1,radii1] = imfindcircles(tempBW, [25*MAG, 35*MAG],'ObjectPolarity', 'dark', ...
        'Sensitivity', 0.955);  %0.98

    tempBW = BW(:, int16(rateX2):int16(sizeX));
    tempBW = tempBW(int16(rateY1):int16(rateY2), :);

    [centers2,radii2] = imfindcircles(tempBW, [25*MAG, 35*MAG],'ObjectPolarity', 'dark', ...
        'Sensitivity', 0.955);  %0.98

    centers1 = centers1 + [0, rateY1];
    centers2 = centers2 + [rateX2, rateY1];
    % viscircles(centers1, radii1);
%     viscircles(centers2, radii2);

    lens_center = abs(centers1 + centers2) ./ 2;
    save_lens_centers = [save_lens_centers; lens_center];
    
    %% 렌즈 중심 영역 삭제
    range1 = 500^2;
    range2 = 800^2;
    for i=1:sizeY
        for j=1:sizeX
            if (i-lens_center(1, 2))^2 + (j-lens_center(1, 1))^2 < (range1 * MAG^2)
                BW(i, j) = 0;
            end
            if (i-lens_center(1, 2))^2 + (j-lens_center(1, 1))^2 > (range2 * MAG^2)
                BW(i, j) = 0;
            end
        end
    end
%     
%     figure();
%     imshow(BW);
    
    %% 연결된 pixel의 개수를 통해 경계면 pixel만을 남김
    BWcpy1 = int8(BW);
    BWcpy2 = int8(BW);
    BWline = int8(BW);

    for i = 1:sizeY
        for j = 1:sizeX
            if BW(i, j) == 1 && BWcpy1(i, j) == 1
                [BWcpy1, BWline, pixcnt] = dir4Recursive(BWcpy1, BWline, j, i, sizeX, sizeY, 0, 0);
                if pixcnt > 20
                    [BWcpy2, BWline, ~] = dir4Recursive(BWcpy2, BWline, j, i, sizeX, sizeY, 0, 1);
                end
            end
        end
    end
    
    for i = 1:sizeY
        for j = 1:sizeX
            if BWline(i, j) < 100
                BWline(i, j) = 0;
            else
                BWline(i, j) = 1;
            end
        end
    end
    BWline = logical(BWline);
    figure();
%    imshow(BWline);
    cd AfterPreprocessing
    mystring2 = "AfterPreprocessing" + imgcnt + '.jpeg';
    saveas(imshow(BWline),char(mystring2));
    cd ..

    curCenter = lens_center;
    for EMcnt = 1:3
        %% 방사형 그래프와 edge와의 접점 계산
        r=650;                            %%%%%%%%  Radius of the circle
        N=200;                            %%%%%%%%  Number of dividing
        save_xcycr = [];
        save_abs = [];
        save_pop = [];

        hold on
        for k = 1:N
            theta = (2*pi/N) * (k-1);
            x=r*cos(theta)+curCenter(1);   %  x coordinate
            y=r*sin(theta)+curCenter(2);   %  y coordinate
            if EMcnt == 3
                plot([curCenter(1, 1) x], [curCenter(1, 2) y], 'w')
            end

            for j = 570:0.5:650
                xc=j*cos(theta)+curCenter(1);   %  x coordinate
                yc=j*sin(theta)+curCenter(2);   %  y coordinate
                if BWline(round(yc), round(xc)) == 1
                    if EMcnt == 3
                        scatter(xc, yc, 'r', 'LineWidth',1.5);
                    end
                    save_xcycr = [save_xcycr;[xc yc j]];
                    break;
                end
            end
        end
        save_xcycr_cpy = save_xcycr;
        S = sum(save_xcycr);
        rsum = S(1, 3);
        [size_data, ~] = size(save_xcycr);
        ravg = rsum / size_data;
        for k = 1:size_data
            if EMcnt == 1
                abs1 = abs(save_xcycr(k, 3) - ravg);
                if abs1 > PARA_ravg_gap
                    save_pop = [save_pop; [k save_xcycr(k, 3) ravg]];
                end
            else
                abs1 = abs(save_xcycr(k, 3) - R);
                if abs1 > 9 - EMcnt * 2
                    save_pop = [save_pop; [k save_xcycr(k, 3) R]];
                end
            end
        end
        save_pop = sort(save_pop, 'descend');
        [size_pop, ~] = size(save_pop);
        for k = 1:size_pop
            save_xcycr(save_pop(k, 1), :) = [];
        end


        [size_data, ~] = size(save_xcycr);
        if EMcnt == 3
            for k = 1:size_data
                scatter(save_xcycr(k, 1), save_xcycr(k, 2), 'g', 'LineWidth',1.5);
            end
        end
%         if EMcnt == 3
%             viscircles(curCenter, R, 'Color', 'b');
%         else
%             viscircles(curCenter, ravg, 'Color', 'r');
%         end
        %% 회귀분석을 통한 원 중심 및 반지름 계산
        [circle_datasize, ~] = size(save_xcycr);
        W = zeros(circle_datasize, 3);
        W(:, 1) = save_xcycr(:, 1);
        W(:, 2) = save_xcycr(:, 2);
        W(:, 3) = 1;

        X = zeros(1, 3);
        b = zeros(1, circle_datasize);

        for i = 1:circle_datasize
            b(i) = -(W(i, 1)^2) -(W(i, 2)^2);
        end

        X = pinv(W.' * W) * W.' * b.';

        A = X(1) * (-1/2);
        B = X(2) * (-1/2);
        C = X(3);
        rSquare = (A^2 + B^2) -C;
        R = sqrt(rSquare);
        curCenter(1, 1) = A;
        curCenter(1, 2) = B;

        % figure();
        % imshow(img);
%         if EMcnt == 2
%             viscircles(curCenter, R, 'Color', 'c');
%         else
%             viscircles(curCenter, R, 'Color', 'r');
%         end
    end
    viscircles(curCenter, R, 'Color', 'c');
    scatter(lens_center(1, 1), lens_center(1, 2), 'm', 'LineWidth',1.5);
    scatter(curCenter(1, 1), curCenter(1, 2), 'c', 'LineWidth',1.5);
    text(curCenter(1, 1), curCenter(1, 2), '\leftarrow center', 'Color', 'c');
    text(20,50,'Incorrect Data','Color','r','FontSize',14);
    text(20,150,'correct Data','Color','g','FontSize',14);
    text(20,250,'Temporary center','Color','m','FontSize',14);
    text(20,350,'The Final center','Color','c','FontSize',14);
    cd result
    mystring3 = "result" + imgcnt + '.jpeg';
    saveas(figure(imgcnt),char(mystring3));
    cd ..
    save_xcyc = [save_xcyc; [curCenter(1, 1), curCenter(1, 2)]];
    save_r = [save_r; R];
    hold off
    toc
end
save_delt_ycxc2lenscenter = save_xcyc - save_lens_centers;
save_delt_ycxc2lenscenter(:, 3) = ...
    sqrt(save_delt_ycxc2lenscenter(:, 1).^2 + save_delt_ycxc2lenscenter(:, 2).^2);