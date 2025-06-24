-- Deploy dream-db-extension:functions/_remove_unused_fixtures/create to pg

BEGIN;
--#region exclude_transaction

create function _remove_unused_fixtures(fixtureId integer)
returns void
language plpgsql
as
$$
declare next_fixture_id integer := null;
begin

    -- Delete the given fixture if it has no child tests, no child fixtures, and no startup, shutdown
    -- setup, or teardown statement.
    delete from fixture
    using fixture fix
    left outer join fixture child on fix.id = child.parent_fixture_id
    left outer join test on fix.id = test.parent_fixture_id
    where
        fixture.id = fix.id
        and fix.id = fixtureId
        and fix.startup is null
        and fix.shutdown is null
        and fix.setup is null
        and fix.teardown is null
        and child.id is null
        and test.id is null
    returning fix.parent_fixture_id into next_fixture_id
    ;

    if next_fixture_id is not null then
        -- Since the given fixture was deleted, check if its parent fixture is now unused, and if so
        -- delete it to.
        perform _remove_unused_fixtures(next_fixture_id);
    end if;

end;
$$;

comment on function _remove_unused_fixtures(fixtureId integer) is
    $$Deletes the given fixture if it is unused. This function also recursivly deletes parent fixtures of the given fixture that are unused. An unused fixture is one that has no child fixtures or tests and has null startup, shutdown, setup, and teardown statements.
    Arguments:
        fixtureId: The id of the fixture in the fixture table that should be removed if it is unused.$$;

--#endregion exclude_transaction
COMMIT;
