function labelMat = ww_pad_label_assign(labelMat, idx, newLabel)
% ww_pad_label_assign
%
% Assigns newLabel to rows idx of a detection table's Label column.
% Label shows up in this codebase in three different storage forms, and
% this function must handle all of them:
%
%   - numeric array (e.g. from a legacy detector that initializes Label
%     as zeros(...) rather than num2str(zeros(...))): assignment must
%     stay numeric. Feeding this case through the char-matrix logic
%     below silently produces garbage, because assigning a character
%     into a numeric array converts it to its ASCII code point instead
%     of its digit value -- e.g. a plain relabel to whale 1 comes out
%     as 49, since char('1') is ASCII 49. (Likewise whale 2 -> 50,
%     since char('2') is ASCII 50.) This is the exact mechanism behind
%     labels silently turning into 2-digit numbers on an ordinary
%     single-digit relabel.
%
%   - string array: each element holds an independent-length string, so
%     assignment is direct and no padding is needed. (Feeding this case
%     through the char-matrix logic below silently produces garbage
%     for the same underlying reason: size(labelMat,2) is always 1 for
%     a string array regardless of each element's length, so the
%     "width" bookkeeping below is meaningless for it.)
%
%   - char matrix (legacy, fixed-width, one row per detection):
%     assigning into it with plain linear indexing, e.g.
%     Label(idx) = key, only ever touches column 1, and fails outright
%     with a size mismatch once newLabel has more than one character
%     (e.g. a 2-digit whale number) while idx selects only one row. If
%     the matrix has previously been widened (e.g. by a double-digit
%     whale number elsewhere in the table), any later single-digit
%     relabel also leaves stale characters from the old value sitting
%     in the extra column(s) -- e.g. a detection labeled '4' can read
%     back as '49' if it was previously labeled '...9' in column 2.
%     This clears/pads the full row width on every assignment so
%     labels of any width can be assigned safely and no stale
%     characters can survive a relabel.

if isnumeric(labelMat)
    labelMat(idx) = str2double(string(newLabel));
    return
end

if isstring(labelMat)
    labelMat(idx) = string(newLabel);
    return
end

newLabel = char(string(newLabel)); % normalize numeric or char input to a char row, e.g. "4" or "12"
newWidth = size(newLabel, 2);
curWidth = size(labelMat, 2);
w = max(newWidth, curWidth);

if curWidth < w % widen existing rows, padding with spaces
    labelMat = [labelMat, repmat(' ', size(labelMat, 1), w - curWidth)];
end

labelMat(idx, :) = repmat([newLabel, repmat(' ', 1, w - newWidth)], numel(idx), 1);

end
