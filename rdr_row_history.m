function rows=rdr_row_history(out)
% Require measured work aligned with errors; rejected work cannot be guessed.
if ~isfield(out,'rowActionsHistory')
    error('rdr:MissingRowHistory','No row-action history. Rerun the revised solver in a new output folder.');
end
rows=out.rowActionsHistory(:);
if numel(rows)~=numel(out.error) || any(diff(rows)<0) || rows(end)~=out.rowActions
    error('rdr:RowHistory','Invalid or misaligned row-action history.');
end
end
