-- Deploy dream-db-extension:functions/remove_test/create to pg

BEGIN;
--#region exclude_transaction

create function remove_test(testSchema name, testFunction name)
returns void
language plpgsql
as
$$
declare deleted_test_id integer;
declare fixture_id integer;
begin

    -- Delete the test record
    delete from test
    where
        test.schema = testSchema
        and test.function = testFunction
    returning id, parent_fixture_id
    into deleted_test_id, fixture_id
    ;

    if deleted_test_id is null then
        raise warning 'The test %.% did not exist. No test was removed.', quote_ident(testSchema), quote_ident(testFunction);
    end if;

    -- If the test's parent fixture is now unused, then remove it.
    perform _remove_unused_fixtures(fixture_id);

end;
$$;

comment on function remove_test(testSchema name, testFunction name) is
    $$Removes the given test.
    Arguments:
        testSchema: The schema that contains the test to remove.
        testFunction: The name of the test function to remove.$$;

--#endregion exclude_transaction
COMMIT;
