% %Computes Direction Cosine Matrix from Euler angles (in radians) for
% % six basic sequence of rotations around X(Roll),Y(Pitch) and Z(Yaw) axis. 
% % Allowed rotations sequences: 
% % xyz, xzy, yxz, yzx, zxy, zyx OR rpy, ryp, pry, pyr, yrp, ypr

function DCM=dcmfromeuler(roll,pitch,yaw,order)

rM=[1    0           0;
    0    cos(roll)   sin(roll);
    0    -sin(roll)  cos(roll)];

pM=[cos(pitch)      0       -sin(pitch);
    0               1       0;
    sin(pitch)      0       cos(pitch)];

yM=[cos(yaw)        sin(yaw)        0;
    -sin(yaw)       cos(yaw)        0;
    0               0               1];

% % -------------------------------------------------------------------------
% % for Rotations if order of rotations is 'rpy' (i.e. roll-->pith-->yaw)
% % then in matrix multiplication we would multiply them in reverse order
% % i.e. first muliply yM with pM let 
% % T=yM*pM then multiply T with rM i.e
% % Ans=T*rM
% % or Ans=(yM*yM)*rM
% % where rM,yM and yM are rotation matrices
% % -------------------------------------------------------------------------
if(strcmpi(order,'xyz')==1 || strcmpi(order,'rpy')==1)
    DCM=(yM*pM)*rM;  
elseif(strcmpi(order,'xzy')==1 || strcmpi(order,'ryp')==1)
    DCM=(pM*yM)*rM;
elseif(strcmpi(order,'yxz')==1 || strcmpi(order,'pry')==1)
    DCM=(yM*rM)*pM;
elseif(strcmpi(order,'yzx')==1 || strcmpi(order,'pyr')==1)
    DCM=(rM*yM)*pM;
elseif(strcmpi(order,'zxy')==1 || strcmpi(order,'yrp')==1)
    DCM=(pM*rM)*yM;
elseif(strcmpi(order,'zyx')==1 || strcmpi(order,'ypr')==1)
    DCM=(rM*pM)*yM;
else
    error('could not recognized the sequence of rotation')
end

 
% % % --------------------------------
% % % Author: Dr. Murtaza Khan
% % % Email : drkhanmurtaza@gmail.com
% % % --------------------------------

