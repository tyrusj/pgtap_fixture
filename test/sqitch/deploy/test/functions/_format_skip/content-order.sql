-- Deploy dream-db-extension-tests:test/functions/_format_skip/content-order to pg

BEGIN;

create function unit_test.test_func_format_skip__content_order()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a skipped test, the function shall return a string containing the following in
the following order: status, number, ' - ', name, description, ' # skip ', reason.
$test_description$;
begin

    return query select tap.is(
        _format_skip(true, 1, 'name', 'description', 'reason'),
        'ok 1 - name description # skip reason',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Reason is not null$scenario$)
    );

    return query select tap.is(
        _format_skip(true, 1, 'name', 'description', null),
        'ok 1 - name description # skip',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Reason is null$scenario$)
    );

end;
$$;

COMMIT;
