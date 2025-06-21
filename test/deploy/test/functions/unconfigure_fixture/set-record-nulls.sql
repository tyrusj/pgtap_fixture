-- Deploy dream-db-extension-tests:functions/unconfigure_fixture/set-record-nulls to pg

BEGIN;

create function unit_test.test_func_unconfig_fixture__set_record_nulls()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When unconfiguring a fixture, if a fixture record corresponds with the given fixture path, then the
function shall set the following values to null: description, startup, shutdown, setup, teardown.
$test_description$;
declare fixture_id integer;
declare parent_fixture_id integer;
begin
    
    -- Create a fixture
    insert into fixture ("name") values ('my_parent_fixture') returning id into parent_fixture_id;
    insert into fixture (
        "name",
        "parent_fixture_id",
        "description",
        "startup",
        "shutdown",
        "setup",
        "teardown"
    ) values (
        'my_fixture',
        parent_fixture_id,
        'my description',
        $startup$create temp table my_startup (id integer);$startup$,
        $shutdown$drop table my_startup$shutdown$,
        $setup$create temp table my_setup (id integer);$setup$,
        $teardown$drop table my_setup$teardown$
    )
    returning id into fixture_id;

    -- Create a test, so that the fixture does not become unused after it is unconfigured.
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function', fixture_id);

    perform unconfigure_fixture('my_parent_fixture/my_fixture');
    return query select tap.results_eq(
        format($have$
            select name, description, startup, shutdown, setup, teardown
            from fixture
            where id = %s
        $have$, fixture_id),
        $want$values (
            'my_fixture',
            null::text,
            null::text,
            null::text,
            null::text,
            null::text
        )$want$,
        test_description
    );

end;
$$;

COMMIT;
