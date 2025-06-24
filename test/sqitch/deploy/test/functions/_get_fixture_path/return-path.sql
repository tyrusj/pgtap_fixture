-- Deploy dream-db-extension-tests:test/functions/_get_fixture_path/return-path to pg

BEGIN;

create function unit_test.test_func_get_path__return_path()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When getting a fixture path, the function shall return a slash delimited string where the last value
is the name of the given fixture, and each previous value is the name of the parent fixture of the
value that follows it.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
begin

    -- Create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_id_a) returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', fixture_id_b) returning id into fixture_id_c;

    return query select tap.is(
        _get_fixture_path(fixture_id_a),
        'fixture_a',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: fixture has no parent fixture.$scenario$)
    );

    return query select tap.is(
        _get_fixture_path(fixture_id_c),
        'fixture_a/fixture_b/fixture_c',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: fixture has parent fixtures.$scenario$)
    );

end;
$$;

COMMIT;
