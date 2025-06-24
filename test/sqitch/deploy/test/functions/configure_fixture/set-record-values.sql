-- Deploy dream-db-extension-tests:functions/configure_fixture/set-record-values to pg

BEGIN;

create function unit_test.test_func_config_fixture__set_record_values()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When configuring a fixture, set the description, startup, shutdown, setup, and teardown on the fixture
record that corresponds with the given fixture path.
$test_description$;
declare fixture_id integer;
declare parent_fixture_id integer;
begin
    
    -- Create a fixture
    insert into fixture ("name") values ('my_parent_fixture') returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture', parent_fixture_id) returning id into fixture_id;

    perform configure_fixture(
        'my_parent_fixture/my_fixture',
        'my description',
        $startup$create temp table my_startup (id integer);$startup$,
        $shutdown$drop table my_startup$shutdown$,
        $setup$create temp table my_setup (id integer);$setup$,
        $teardown$drop table my_setup$teardown$
    );
    return query select tap.results_eq(
        format($have$
            select name, description, startup, shutdown, setup, teardown
            from fixture
            where id = %s
        $have$, fixture_id),
        $want$values (
            'my_fixture',
            'my description',
            $startup$create temp table my_startup (id integer);$startup$,
            $shutdown$drop table my_startup$shutdown$,
            $setup$create temp table my_setup (id integer);$setup$,
            $teardown$drop table my_setup$teardown$
        )$want$,
        test_description
    );

end;
$$;

COMMIT;
