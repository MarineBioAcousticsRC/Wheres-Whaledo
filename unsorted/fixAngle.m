function DET = fixAngle(DET)

for i = 1:2
    DET{i}.DOA = -DET{i}.DOA;
    DET{i}.Ang(:, 1) = atan2d(DET{i}.DOA(:,2), DET{i}.DOA(:,1));
    DET{i}.Ang(:, 2) = 180 - acosd(DET{i}.DOA(:,3)); % fix elevation
end