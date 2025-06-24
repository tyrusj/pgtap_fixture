-- Deploy dream-db-extension-tests:test/functions/_format_skip/extra-name-description-lines to pg

BEGIN;

create function unit_test.test_func_format_skip__name_description_lines()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a skipped test, if the name or description has two or more lines of text, then the
function shall return the first line of the name and description text in the first line of the result
and the remaining lines as comments, where the first comment line contains "Name and description
cont'd".
$test_description$;
begin

    return query select tap.is(
        _format_skip(
            true, 1,
'name line 1
name line 2
name line 3', 'description', 'reason'
        ),
$want$ok 1 - name line 1 # skip reason
# Name and description cont'd: name line 2
# name line 3 description$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Multi line name.$scenario$)
    );

    return query select tap.is(
        _format_skip(
            true, 1, 'name',
'description line 1
description line 2
description line 3', 'reason'
        ),
$want$ok 1 - name description line 1 # skip reason
# Name and description cont'd: description line 2
# description line 3$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Multi line description.$scenario$)
    );

    return query select tap.is(
        _format_skip(
            true, 1,
'name line 1
name line 2
name line 3',
'description line 1
description line 2
description line 3', 'reason'
        ),
$want$ok 1 - name line 1 # skip reason
# Name and description cont'd: name line 2
# name line 3 description line 1
# description line 2
# description line 3$want$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Multi line name and multi line description.$scenario$)
    );

end;
$$;

COMMIT;
