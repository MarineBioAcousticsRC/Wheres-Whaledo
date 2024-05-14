% function wheresWhaledo
% close(mainFig)
close all force
mainFig = uifigure('Name', 'Where''s Whaledo');
mainFig.Position = [10, 125, 540, 600];
grd = uigridlayout(mainFig, [2, 1]);

pnl(1) = uipanel(grd, 'Title', 'Navigation')

%% set up element for selecting encounter start/end:
% startDay = uidatepicker(mainFig.Children.Children(1));
% startDay.DisplayFormat = 'yyyy-MM-dd';
% startDay.Position = [1,1,1,1]
lbl = uilabel(mainFig.Children.Children(1));
lbl.Text = 'Encounter period:';
lbl.Position = [10, 235, 100, 20];

encStart = uieditfield(mainFig.Children.Children(1));
encStart.Position = [110, 235, 138, 20];
encStart.Value = 'yyyy-mm-dd HH:MM:SS';

lbl = uilabel(mainFig.Children.Children(1));
lbl.Text = 'to';
lbl.Position = [262, 235, 30, 20];

encEnd = uieditfield(mainFig.Children.Children(1));
encEnd.Position = [293, 235, 138, 20];
encEnd.Value = 'yyyy-mm-dd HH:MM:SS';
%%
uipanel(grd, 'Title', 'Functions')