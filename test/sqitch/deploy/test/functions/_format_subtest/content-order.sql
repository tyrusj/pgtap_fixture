-- Deploy dream-db-extension-tests:test/functions/_format_subtest/content-order to pg

BEGIN;

create function unit_test.test_func_format_subtest__content_order()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a subtest, the function shall return a string containing the following in the
following order: '# Subtest: ', name, description.
$test_description$;
begin

    return query select tap.is(
        _format_subtest('name', 'description'),
        '# Subtest: name description',
        test_description
    );

end;
$$;

COMMIT;
