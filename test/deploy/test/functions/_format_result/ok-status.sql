-- Deploy dream-db-extension-tests:test/functions/_format_result/ok-status to pg

BEGIN;

create function unit_test.test_func_format_result__ok_status()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a result, if the status is true, then the result string shall contain 'ok', otherwise
the result string shall contain 'not ok'.
$test_description$;
begin

    return query select tap.is(
        _format_result(true, 1, 'name', 'description'),
        'ok 1 - name description',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Ok status.$scenario$)
    );

    return query select tap.is(
        _format_result(false, 1, 'name', 'description'),
        'not ok 1 - name description',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Not ok status.$scenario$)
    );

end;
$$;

COMMIT;
