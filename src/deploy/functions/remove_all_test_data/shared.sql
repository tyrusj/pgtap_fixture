-- Deploy dream-db-extension:functions/remove_all_test_data/create to pg

BEGIN;
--#region exclude_transaction

create function remove_all_test_data(schema name, function name)
returns void
language plpgsql
as
$$
declare count_of_test_data_deleted integer;
begin

    with deleted_test_data(id) as (
        delete from test_data
        using test_data data
        inner join test on test.id = data.test_id
        where
            test_data.id = data.id
            and test.schema = remove_all_test_data.schema
            and test.function = remove_all_test_data.function
        returning data.id
    )
    select count(*) cnt from deleted_test_data
    into count_of_test_data_deleted
    ;

    if count_of_test_data_deleted = 0 then
        if exists(
            select id from test
            where
                test.schema = remove_all_test_data.schema
                and test.function = remove_all_test_data.function
        ) then
            raise warning 'Test %.% does not have any test data. No test data was removed.', quote_ident(schema), quote_ident(function);
        else
            raise warning 'Test %.% does not exist. No test data was removed.', quote_ident(schema), quote_ident(function);
        end if;
    end if;

end;
$$;

comment on function remove_all_test_data(schema name, function name) is
    $$Removes all test data that is associated with the given test function.
    Arguments:
        schema: The schema that contains the test function.
        function: The name of the test function.$$;

--#endregion exclude_transaction
COMMIT;
