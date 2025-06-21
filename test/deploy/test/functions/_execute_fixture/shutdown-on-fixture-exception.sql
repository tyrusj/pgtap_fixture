-- Deploy dream-db-extension-tests:functions/_execute_fixture/shutdown-on-fixture-exception to pg

BEGIN;

create function unit_test.test_func_execute_fixture__shutdown_on_fixture_exception()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if a child fixture throws an exception, then the function shall execute the
fixture's shutdown statement.
$test_description$;
declare child_fixture_id integer;
declare fixture_id integer;
declare test_id integer;
begin

    -- Create a sequence and initialize it.
    create temp sequence my_seq;
    perform nextval('my_seq');

    -- Create fixtures
    insert into fixture ("name", "startup", "shutdown") values (
        'my_fixture',
        $startup$select setval('my_seq', 100);$startup$,
        $shutdown$select setval('my_seq', 200);$shutdown$
    )
    returning id into fixture_id;
    insert into fixture ("name", "parent_fixture_id", "startup") values (
        'my_child_fixture',
        fixture_id,
        $startup$raise 'Child fixture exception.';$startup$
    ) returning id into child_fixture_id;

    -- Add the fixtures to the plan
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
