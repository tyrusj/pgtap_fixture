-- Deploy dream-db-extension:functions/add_test/create to pg

BEGIN;
--#region exclude_transaction

create function add_test(
    testSchema name,
    testFunction name,
    description text default null,
    fixturePath text default null
)
returns void
language plpgsql
as
$$
declare fixture_id integer := null;
begin

    if testSchema is null or testFunction is null then
        raise 'Schema and function cannot be null.';
    end if;

    if exists(select true from test where test.schema = testSchema and test.function = testFunction) then
        raise 'The test %.% already exists.', quote_ident(testSchema), quote_ident(testFunction);
    end if;

    if fixturePath is not null then
        -- Get the fixture ID. Create any fixtures that don't exist.
        fixture_id := _get_fixture_by_path_and_root(fixturePath, null, true);
    end if;

    insert into test ("schema", "function", "description", "parent_fixture_id")
    values (testSchema, testFunction, description, fixture_id)
    ;

end;
$$;

comment on function add_test(
    testSchema name,
    testFunction name,
    description text,
    fixturePath text
) is
    $$Specifies that the given function is a test function that can be planned and executed.
    Arguments:
        testSchema: The schema that the test function is in.
        testFunction: The name of the test function.
        description: A description of the test function.
        fixturePath: The path to the fixture that this test will be added to. The fixture will be created if it does not already exist. A fixture path is a series of fixture names separated by slash characters '/'.$$;

--#endregion exclude_transaction
COMMIT;
