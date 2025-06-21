-- Deploy dream-db-extension:functions/unconfigure_fixture/create to pg

BEGIN;
--#region exclude_transaction

create function unconfigure_fixture(fixturePath text)
returns void
language plpgsql
as
$$
declare fixture_id integer;
begin

    -- Get the fixture ID for the path.
    fixture_id := _get_fixture_by_path_and_root(fixturePath, null);

    if fixture_id is null then
        raise warning 'Cannot unconfigure fixture "%". Fixture path does not exist.', fixturePath;
    else
        -- Set the fixture's values to null.
        update fixture
        set
            description = null,
            startup = null,
            shutdown = null,
            setup = null,
            teardown = null
        where id = fixture_id
        ;

        perform _remove_unused_fixtures(fixture_id);
    end if;

end;
$$;

comment on function unconfigure_fixture(fixturePath text) is
    $$Removes the startup, shutdown, setup, and teardown statements from a fixture. Also removes the description. If this causes the fixture to become unused, then it will be deleted.
    Arguments:
        fixturePath: The path to the fixture to unconfigure.$$;

--#endregion exclude_transaction
COMMIT;
