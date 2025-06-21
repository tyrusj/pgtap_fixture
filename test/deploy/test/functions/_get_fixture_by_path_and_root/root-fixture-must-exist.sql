-- Deploy dream-db-extension-tests:functions/_get_fixture_by_path_and_root/root-fixture-must-exist to pg

BEGIN;

create function unit_test.test_func_get_fixture__root_fixture_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When getting a fixture by path and root, if there is no record in the fixture table whose name corresponds
with the first name in the given fixture path and whose parent fixture ID corresponds with the given root
fixture ID (null parent fixture ID and null root fixture ID count as equal), then the function shall
return null.
$test_description$;
declare parent_fixture_id integer;
declare no_parent_fixture_id integer;
declare child_fixture_id integer;
declare fixture_a_id integer;
declare fixture_b_id integer;
declare fixture_c_id integer;
declare fixture_d_id integer;
begin

    -- Create the fixtures
    insert into fixture ("name") values ('no_parent') returning id into no_parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_a', no_parent_fixture_id) returning id into fixture_a_id;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_a_id) returning id into fixture_b_id;
    insert into fixture ("name") values ('parent') returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('child', parent_fixture_id) returning id into child_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', child_fixture_id) returning id into fixture_c_id;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_d', fixture_c_id) returning id into fixture_d_id;

    return query select tap.is(
        _get_fixture_by_path_and_root('no_parent', null),
        no_parent_fixture_id,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute with a fixture name that exists with a null parent. Given a null root. Expect fixture ID.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('no_parent', 1),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Execute with a fixture name that exists with a null parent. Given a non-null root. Expect null.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child', parent_fixture_id),
        child_fixture_id,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Execute with a fixture name that exists with a non-null parent. Given a non-null root that matches the parent. Expect fixture ID.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child', parent_fixture_id + 1),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Execute with a fixture name that exists with a non-null parent. Given a non-null root that does not match the parent. Expect null.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child', null),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Execute with a fixture name that exists with a non-null parent. Given a null root. Expect null.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('i_dont_exist', null),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$6: Execute with a fixture name that doesn't exist. Expect null.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('no_parent/fixture_a/fixture_b', null),
        fixture_b_id,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$7: Execute with a fixture path whose first name exists with a null parent. Given a null root. Expect fixture ID.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('no_parent/fixture_a/fixture_b', 1),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$8: Execute with a fixture path whose first name exists with a null parent. Given a non-null root. Expect null.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child/fixture_c/fixture_d', parent_fixture_id),
        fixture_d_id,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$9: Execute with a fixture path whose first name exists with a non-null parent. Given a non-null root that matches the parent. Expect fixture ID.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child/fixture_c/fixture_d', parent_fixture_id + 1),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$10: Execute with a fixture path whose first name exists with a non-null parent. Given a non-null root that does not match the parent. Expect null.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('child/fixture_c/fixture_d', null),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$11: Execute with a fixture path whose first name exists with a non-null parent. Given a null root. Expect null.$scenario$)
    );

    return query select tap.is(
        _get_fixture_by_path_and_root('i_dont_exist/fixture_a/fixture_b', null),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$12: Execute with a fixture path whose first name doesn't exist. Expect null.$scenario$)
    );

end;
$$;

COMMIT;
