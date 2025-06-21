-- Deploy dream-db-extension:functions/add_test_data/create to pg

BEGIN;
--#region exclude_transaction

create function add_test_data(schema name, function name, parameters text, description text default null)
returns void
language plpgsql
as
$$
declare test_id integer;
begin

    select id
    from test
    where
        test.schema = add_test_data.schema
        and test.function = add_test_data.function
    into test_id
    ;

    if test_id is null then
        raise 'Cannot add test data for test %.%. Test does not exist.', quote_ident(schema), quote_ident(function);
    end if;

    insert into test_data ("test_id", "parameters", "description")
    values (test_id, parameters, description)
    ;

end;
$$;

comment on function add_test_data(schema name, function name, parameters text, description text) is
    $$Adds test data that the specified test should be executed with. The parameters must be a statement that returns a single jsonb value. This jsonb value can have any format that the specified test can consume. The description will be combined with the test description and passed to the specified test when it is executed. Ensure that the specified test function takes arguments (jsonb, text).
    Arguments:
        schema: The schema that contains the test function.
        function: The name of the test function.
        parameters: A statement that returns a single jsonb value that the test function can consume.
        description: A description of this test data.$$;

--#endregion exclude_transaction
COMMIT;
