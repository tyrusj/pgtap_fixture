-- Deploy dream-db-extension-tests:test/functions/execute_tests/missing-function-bail-out to pg

BEGIN;

create function unit_test.test_func_execute_tests__missing_function_bail_out()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if a given test function is not present in the test table, then the function shall
return 'Bail Out! ' followed by a message.
$test_description$;
begin

    return query select tap.set_has(
        $have$
            select
                true
            from execute_tests(null, 'pg_temp', array['my_missing_function']) t(x)
            where t.x like 'Bail Out! %'
        $have$,
        $want$values (true)$want$,
        test_description
    );

end;
$$;

COMMIT;
