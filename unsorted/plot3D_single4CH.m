%% Script for 3D plotting of track
hyd=2; %Which mooring do you want to look at?

global brushing
colorNums = unique([DET{1}.color; DET{2}.color]);

for wn = 1:length(colorNums) % iterate through each whale number
 I1 = find(DET{hyd}.color==colorNums(wn));
 
 track{wn} = [DET{hyd}.TDet(I1),DET{hyd}.Ang(I1,1),DET{hyd}.Ang(I1,2)];
end
%%
whale = [2:8]; %Which whale do you want to look at?

figure; p=plot3(track{whale(1)}(:, 1), track{whale(1)}(:, 2), track{whale(1)}(:, 3), ...
                'color', brushing.params.colorMat(whale(1)+2, :))
         p.Marker = '.';
         p.MarkerSize = 10;
         xlabel('Time')
         ylabel('Azimuth')
         zlabel('Elevation')
grid on

if length(whale)>1
    for wn=2:length(whale)-1
    hold on
    q=plot3(track{whale(wn)}(:, 1), track{whale(wn)}(:, 2), track{whale(wn)}(:, 3), ...
                'color', brushing.params.colorMat(whale(wn)+2, :))
       q.Marker = '.';
         q.MarkerSize = 10;
    end
end

