-- Deploy dream-db-extension:functions/configure_fixture/create to pg

BEGIN;
--#region exclude_transaction

create function configure_fixture(
    fixturePath text,
    description text default null,
    startup text default null,
    shutdown text default null,
    setup text default null,
    teardown text default null
)
returns void
language plpgsql
as
$$
declare fixture_id integer;
begin

    if fixturePath is null then
        raise 'Fixture path cannot be null.';
    end if;

    if not _is_fixture_path_valid(fixturePath) then
        raise 'Fixture path "%" is invalid.', fixturePath;
    end if;

    -- Create the fixture path if it doesn't exist.
    fixture_id := _get_fixture_by_path_and_root(fixturePath, null, true);
    
    -- Set the values on the fixture
    update fixture
    set
        description = configure_fixture.description,
        startup = configure_fixture.startup,
        shutdown = configure_fixture.shutdown,
        setup = configure_fixture.setup,
        teardown = configure_fixture.teardown
    where id = fixture_id
    ;

end;
$$;

comment on function configure_fixture(
    fixturePath text,
    description text,
    startup text,
    shutdown text,
    setup text,
    teardown text
) is
    $$Creates a fixture if it does not exist and adds a description and startup, shutdown, setup, and teardown statements. Each statement should not return any values.
    Arguments:
        fixturePath: The path to the fixture to configure. It will be created if it does not exist.
        description: The description of the fixture.
        startup: A statement that will be executed once at the beginning of the fixture's execution.
        shutdown: A statement that will be executed once at the end of the fixture's execution.
        setup: A statement that will be executed before each child fixture and test is executed.
        teardown: A statement that will be executed after each child fixture and test is executed.$$;

--#endregion exclude_transaction
COMMIT;
