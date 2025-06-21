-- Deploy dream-db-extension-tests:functions/configure_fixture/invalid-fixture to pg

BEGIN;

create function unit_test.test_func_config_fixture__invalid_fixture()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When configuring a fixture, if the fixture path is invalid, then the function shall throw an exception.
$test_description$;
begin
    
    return query select tap.throws_ok(
        $throws$select configure_fixture('//invalid//fixture//path//');$throws$,
        null,
        test_description
    );

end;
$$;

COMMIT;
