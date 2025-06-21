-- Deploy dream-db-extension-tests:test/functions/_get_fixture_path/fixture-does-not-exist to pg

BEGIN;

create function unit_test.test_func_get_path__fixture_does_not_exist()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When getting a fixture path, if the given fixture does not exist, then the function shall return null.
$test_description$;
declare fixture_id_a integer;
begin

    -- Create fixture
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;

    -- Delete the fixture to ensure that it doesn't exist.
    delete from fixture where id = fixture_id_a;

    return query select tap.is(
        _get_fixture_path(fixture_id_a),
        null::text,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: fixture does not exist.$scenario$)
    );

    return query select tap.is(
        _get_fixture_path(null),
        null::text,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: fixture is null.$scenario$)
    );

end;
$$;

COMMIT;
