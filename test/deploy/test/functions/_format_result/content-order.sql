-- Deploy dream-db-extension-tests:text/functions/_format_result/content-order to pg

BEGIN;

create function unit_test.test_func_format_result__content_order()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a result, the function shall return a string containing the following in the
following order: status, number, ' - ', name, description.
$test_description$;
begin

    return query select tap.is(
        _format_result(true, 1, 'name', 'description'),
        'ok 1 - name description',
        test_description
    );

end;
$$;

COMMIT;
