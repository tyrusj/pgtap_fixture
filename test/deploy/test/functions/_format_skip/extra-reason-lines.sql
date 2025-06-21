-- Deploy dream-db-extension-tests:test/functions/_format_skip/extra-reason-lines to pg

BEGIN;

create function unit_test.test_func_format_skip__reason_lines()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a skipped test, if the reason has two or more lines of text, then the function
shall return the first line of the reason in the first line of the result and the remaining lines
as comments, where the first comment line contains "Reason cont'd".
$test_description$;
begin

    return query select tap.is(
        _format_skip(
            true, 1, 'name', 'description',
'reason line 1
reason line 2
reason line 3'
        ),
$want$ok 1 - name description # skip reason line 1
# Reason cont'd: reason line 2
# reason line 3$want$,
        test_description
    );

end;
$$;

COMMIT;
