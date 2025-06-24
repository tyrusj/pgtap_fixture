-- Deploy dream-db-extension-tests:test/functions/_format_result/comment-lines to pg

BEGIN;

create function unit_test.test_func_format_result__comment_lines()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a result, the function shall comment each line in the return value after the first.
$test_description$;
begin

    return query select tap.is(
        _format_result(
            true, 1,
'name line 1
name line 2
name line 3', 'description'
        ),
'ok 1 - name line 1
# name line 2
# name line 3 description',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Multi line name.$scenario$)
    );

    return query select tap.is(
        _format_result(
            true, 1, 'name',
'description line 1
description line 2
description line 3'
        ),
'ok 1 - name description line 1
# description line 2
# description line 3',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Multi line description.$scenario$)
    );

    return query select tap.is(
        _format_result(
            true, 1,
'name line 1
name line 2
name line 3',
'description line 1
description line 2
description line 3'
        ),
'ok 1 - name line 1
# name line 2
# name line 3 description line 1
# description line 2
# description line 3',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Multi line name and multi line description.$scenario$)
    );

end;
$$;

COMMIT;
