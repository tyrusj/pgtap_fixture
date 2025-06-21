-- Deploy dream-db-extension-tests:functions/_get_fixture_by_path_and_root/return-fixture-id-recursive to pg

BEGIN;

create function unit_test.test_func_get_fixture__return_fixture_id_recursive()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When getting a fixture by path and root, if there is a record in the fixture table whose name corresponds
with the first name in the given fixture path and whose parent fixture ID corresponds with the given root
fixture ID (null parent fixture ID and null root fixture ID count as equal), and if there are more names
after the first in the given fixture path, then the function shall return the ID of the fixture whose
path is the given path excluding the first name and whose root fixture ID is the fixture ID that
corresponds with the given path and fixture ID.
$test_description$;
declare no_parent_fixture_id integer;
declare parent_fixture_id integer;
declare child_fixture_id_a integer;
declare child_fixture_id_b integer;
declare child_fixture_id_c integer;
begin

    -- Create the fixture
    insert into fixture ("name") values ('parent') returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('child_a', parent_fixture_id) returning id into child_fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('child_b', child_fixture_id_a) returning id into child_fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('child_c', child_fixture_id_b) returning id into child_fixture_id_c;

    return query select tap.is(
        _get_fixture_by_path_and_root('parent/child_a/child_b/child_c', null),
        child_fixture_id_c,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Return ID of a fixture given a null root.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child_a/child_b/child_c', parent_fixture_id),
        child_fixture_id_c,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Return ID of a fixture given a non-null root$scenario$)
    );

end;
$$;

COMMIT;
