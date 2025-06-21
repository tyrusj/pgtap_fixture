-- Deploy dream-db-extension-tests:functions/configure_fixture/ensure-fixture-exists to pg

BEGIN;

create function unit_test.test_func_config_fixture__ensure_fixture_exists()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When configuring a fixture, if the fixture path is not null, then the function shall ensure that a
fixture exists for the given fixture path.
$test_description$;
begin
    
    -- Mock _get_fixture_by_path_and_root to verify that it is called with the option to create missing
    -- fixtures.
    alter function _get_fixture_by_path_and_root(
        fixturePath text,
        root integer,
        createMissingFixtures boolean
    )
    rename to _get_fixture_by_path_and_root___original;
    create function _get_fixture_by_path_and_root(
        fixturePath text,
        root integer,
        createMissingFixtures boolean default false
    )
    returns integer
    language plpgsql
    as
    $mock$
    begin
        insert into function_called ("fixturePath", root, "createMissingFixtures") values (fixturePath, root, createMissingFixtures);
        return _get_fixture_by_path_and_root___original(fixturePath, root, createMissingFixtures);
    end;
    $mock$;

    -- Create table to check whether _get_fixture_by_path_and_root was called with the correct arguments.
    create temp table function_called (
        "fixturePath" text,
        root integer,
        "createMissingFixtures" boolean
    );

    perform configure_fixture('path/to/fixture');
    return query select tap.results_eq(
        $have$select * from function_called$have$,
        $want$values ('path/to/fixture', null::integer, true)$want$,
        test_description
    );

end;
$$;

COMMIT;
