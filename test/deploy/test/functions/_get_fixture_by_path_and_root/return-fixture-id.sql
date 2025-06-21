-- Deploy dream-db-extension-tests:functions/_get_fixture_by_path_and_root/return-fixture-id to pg

BEGIN;

create function unit_test.test_func_get_fixture__return_fixture_id()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When getting a fixture by path and root, if there is a record in the fixture table whose name corresponds
with the first name in the given fixture path and whose parent fixture ID corresponds with the given root
fixture ID (null parent fixture ID and null root fixture ID count as equal), and if there are no names
after the first name in the given fixture path, then the function shall return the ID of the fixture
record.
$test_description$;
declare no_parent_fixture_id integer;
declare parent_fixture_id integer;
declare child_fixture_id integer;
begin

    -- Create the fixture
    insert into fixture ("name") values ('no_parent') returning id into no_parent_fixture_id;
    insert into fixture ("name") values ('parent') returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('child', parent_fixture_id) returning id into child_fixture_id;

    return query select tap.is(
        _get_fixture_by_path_and_root('no_parent', null),
        no_parent_fixture_id,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Return ID of a fixture with no parent fixture.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child', parent_fixture_id),
        child_fixture_id,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Return ID of a fixture with a parent fixture.$scenario$)
    );

end;
$$;

COMMIT;
