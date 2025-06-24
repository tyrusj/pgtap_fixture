-- Deploy dream-db-extension-tests:functions/_remove_unused_fixtures/remove-parent-fixture to pg

BEGIN;

create function unit_test.test_func_unused_fixtures__remove_parent_fixture()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When removing unused fixtures, if a fixture record is removed from the fixture table, and if that record
had a parent fixture ID, then the function shall remove unused fixture records associated with that
fixture ID.
$test_description$;
declare unused_fixture_id integer;
declare unused_parent_fixture_id integer;
declare unused_grandparent_fixture_id integer;
begin

    -- Create fixtures
    insert into fixture ("name") values ('grandparent_fixture') returning id into unused_grandparent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('parent_fixture', unused_grandparent_fixture_id) returning id into unused_parent_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('unused_fixture', unused_parent_fixture_id) returning id into unused_fixture_id;

    perform _remove_unused_fixtures(unused_fixture_id);
    return query select tap.is_empty(
        $have$select id from fixture;$have$,
        test_description
    );

end;
$$;

COMMIT;
