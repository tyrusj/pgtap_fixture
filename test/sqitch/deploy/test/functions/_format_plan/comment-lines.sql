-- Deploy dream-db-extension-tests:test/functions/_format_plan/comment-lines to pg

BEGIN;

create function unit_test.test_func_format_plan__comment_lines()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a plan, the function shall comment each line in the return value after the first.
$test_description$;
begin

    return query select tap.is(
        _format_plan(
            3,
'reason line 1
reason line 2
reason line 3'
        ),
'1..3 # reason line 1
# reason line 2
# reason line 3',
        test_description
    );

end;
$$;

COMMIT;
