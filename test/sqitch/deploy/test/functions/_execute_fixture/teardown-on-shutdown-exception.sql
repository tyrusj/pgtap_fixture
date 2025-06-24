-- Deploy dream-db-extension-tests:functions/_execute_fixture/teardown-on-shutdown-exception to pg

BEGIN;

create function unit_test.test_func_execute_fixture__teardown_on_shutdown_exception()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture shutdown throws an exception, then the function shall execute
the parent fixture's teardown statement.
$test_description$;
declare parent_fixture_id integer;
declare child_fixture_id integer;
declare fixture_id integer;
declare test_id integer;
begin

    -- Create a sequence and initialize it.
    create temp sequence my_seq;
    perform nextval('my_seq');

    -- Create fixtures
    insert into fixture ("name", "setup", "teardown") values (
        'my_parent_fixture',
        $setup$select setval('my_seq', 100);$setup$,
        $teardown$select setval('my_seq', 200);$teardown$
    )
    returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id", "shutdown") values (
        'my_fixture',
        parent_fixture_id,
        $shutdown$raise 'Fixture shutdown exception';$shutdown$
    )
    returning id into fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_child_fixture', fixture_id) returning id into child_fixture_id;

    -- add to plan
    insert into fixture_plan ("id") values (fixture_id), (child_fixture_id);

    -- Execute the scenarios

    perform _execute_fixture(fixture_id, 1);
    return query select tap.is(
        currval('my_seq'),
        200::bigint,
        test_description
    );


end;
$$;

COMMIT;
