-- Deploy dream-db-extension-tests:functions/_get_fixture_by_path_and_root/create-missing-fixtures to pg

BEGIN;

create function unit_test.test_func_get_fixture__create_missing_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When getting a fixture by path and root, if there is no record in the fixture table whose name corresponds
with the first name in the given fixture path and whose parent fixture ID corresponds with the given root
fixture ID (null parent fixture ID and null root fixture ID count as equal), and if the function has been
instructed to create missing fixtures, then the function shall create a fixture having the first name in
the given fixture path with the root fixture ID as its parent and return the ID of the newly created
fixture.
$test_description$;
declare existing_fixture_id integer;
declare new_fixture_a_id integer;
declare new_fixture_c_id integer;
declare new_fixture_d_id integer;
declare new_fixture_f_id integer;
declare found_existing_fixture_id integer;
begin

    -- Create fixtures
    insert into fixture ("name") values ('existing_fixture') returning id into existing_fixture_id;

    select _get_fixture_by_path_and_root('child_fixture_a', existing_fixture_id, true) into new_fixture_a_id;
    return query select tap.set_has(
        'select id, name, parent_fixture_id from fixture',
        format($has$values (%s, 'child_fixture_a', %s)$has$, coalesce(new_fixture_a_id, -1), existing_fixture_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: From an existing fixture, create one child fixture.$scenario$)
    );

    select _get_fixture_by_path_and_root('child_fixture_b/child_fixture_c', existing_fixture_id, true) into new_fixture_c_id;
    return query select tap.set_has(
        'select id, name from fixture',
        format($has$values (%s, 'child_fixture_c')$has$, coalesce(new_fixture_c_id, -1)),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2a: From an existing fixture, create a tree of two fixtures.$scenario$)
    );
    return query select tap.set_has(
        'select name, parent_fixture_id from fixture',
        format($has$values ('child_fixture_b', %s)$has$, existing_fixture_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2b: From an existing fixture, create a tree of two fixtures.$scenario$)
    );

    select _get_fixture_by_path_and_root('root_fixture_d', null, true) into new_fixture_d_id;
    return query select tap.set_has(
        'select id, name, parent_fixture_id from fixture',
        format($has$values (%s, 'root_fixture_d', null::integer)$has$, coalesce(new_fixture_d_id, -1)),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Create one root fixture.$scenario$)
    );

    select _get_fixture_by_path_and_root('root_fixture_e/child_fixture_f', null, true) into new_fixture_f_id;
    return query select tap.set_has(
        'select id, name from fixture',
        format($has$values (%s, 'child_fixture_f')$has$, coalesce(new_fixture_f_id, -1)),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4a: Create a root fixture and a child of that fixture.$scenario$)
    );
    return query select tap.set_has(
        'select name, parent_fixture_id from fixture',
        $has$values ('root_fixture_e', null::integer)$has$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4b: Create a root fixture and a child of that fixture.$scenario$)
    );

    select _get_fixture_by_path_and_root('existing_fixture', null, true) into found_existing_fixture_id;
    return query select tap.is(
        found_existing_fixture_id,
        existing_fixture_id,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Fixture already exists.$scenario$)
    );

end;
$$;

COMMIT;
