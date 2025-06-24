-- Deploy dream-db-extension:functions/remove_test_data/create to pg

BEGIN;
--#region exclude_transaction

create function remove_test_data(schema name, function name, parameters text)
returns void
language plpgsql
as
$$
declare deleted_test_data_id integer;
begin

    delete from test_data
    using test_data data
    inner join test on test.id = data.test_id
    where
        test_data.id = data.id
        and test.schema = remove_test_data.schema
        and test.function = remove_test_data.function
        and data.parameters = remove_test_data.parameters
    returning data.id into deleted_test_data_id
    ;

    if deleted_test_data_id is null then
        if exists(
            select id from test
            where
                test.schema = remove_test_data.schema
                and test.function = remove_test_data.function
        ) then
            raise warning 'Test %.% does not have test data with parameters `%`. No test data was removed.', quote_ident(schema), quote_ident(function), parameters;
        else
            raise warning 'Test %.% does not exist. No test data was removed.', quote_ident(schema), quote_ident(function);
        end if;
    end if;

end;
$$;

comment on function remove_test_data(schema name, function name, parameters text) is
    $$Removes the specified test data for the given test. The parameters value must exactly match the parameters value in an existing test data record for the given test.
    Arguments:
        schema: The schema that contains the test function.
        function: The name of the test function.
        parameters: The parameters value of the test data record that should be removed.$$;

--#endregion exclude_transaction
COMMIT;
