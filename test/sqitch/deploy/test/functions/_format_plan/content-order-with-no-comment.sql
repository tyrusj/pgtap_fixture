-- Deploy dream-db-extension-tests:test/functions/_format_plan/content-order-with-no-comment to pg

BEGIN;

create function unit_test.test_func_format_plan__content_order_with_no_comment()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When formatting a plan, if the reason is null, then the function shall return a string containing
the following in the following order: '1..', number.
$test_description$;
begin

    return query select tap.is(
        _format_plan(3, null),
        '1..3',
        test_description
    );

end;
$$;

COMMIT;
