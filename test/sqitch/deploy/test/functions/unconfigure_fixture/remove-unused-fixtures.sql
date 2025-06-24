-- Deploy dream-db-extension-tests:functions/unconfigure_fixture/remove-unused-fixtures to pg

BEGIN;

create function unit_test.test_func_unconfig_fixture__remove_unused_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When unconfiguring a fixture, if that fixture becomes unused after unconfiguring, then the function
shall remove unused fixtures beginning with the given fixture.
$test_description$;
declare parent_fixture_id integer;
declare fixture_id integer;
begin

    -- Add fixtures
    insert into fixture ("name") values ('parent_fixture') returning id into parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture', parent_fixture_id) returning id into fixture_id;

    perform unconfigure_fixture('parent_fixture/my_fixture');
    return query select tap.is_empty(
        'select id from fixture',
        test_description
    );

end;
$$;

COMMIT;
