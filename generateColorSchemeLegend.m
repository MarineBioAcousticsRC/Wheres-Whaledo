function generateColorSchemeLegend(brushing)

M = (1:length(brushing.params.colorMat)-2).'; % color box position vector

fig = findall(0, 'Type', 'figure', 'name', 'Legend of Label Colors');

if isempty(fig)
    fig = figure('Name', 'Legend of Label Colors', 'Position', brushing.params.colorLegendPos);
end
set(fig, 'MenuBar', 'None'); % Hide Menu bar
set(fig, 'NumberTitle', 'off')
colormap(fig, brushing.params.colorMat(2:end-1,:))

colIm = imagesc(M);

ax = gca;
ax.XTick = [];
ax.YTick = [];

fontSize = 13;

% text(1, M(1), '(Acoustic Data)', 'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', fontSize)
text(1, M(1), 'Unlabeled', 'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', fontSize)

for i = 2:(length(M))
    text(1, M(i), ['Whale #', num2str(i-1)], 'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', fontSize)
end

% text(1, M(end), 'Buzzes', 'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', fontSize)

title('Label Color Scheme')