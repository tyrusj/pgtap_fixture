-- Deploy dream-db-extension:create-test-data-table to pg

BEGIN;
--#region exclude_transaction

create table test_data
(
    id integer primary key generated always as identity,
    description text,
    test_id integer not null references test on delete cascade,
    parameters text,
    unique nulls not distinct (test_id, parameters)
);

comment on table test_data is
    'Each test can be run with multiple sets of test data, which are specified in this table.';
comment on column test_data.id is
    'The ID of the test data.';
comment on column test_data.description is
    'The description of the test data. This is useful for explaining the purpose of the test data if it is not clear from the test data itself.';
comment on column test_data.test_id is
    'The ID of the test that is run with this test data.';
comment on column test_data.parameters is
    'The parameters to pass to the test. This is a statement that returns a single jsonb value. When a test is run with test data, this statement will be executed, and the jsonb value will be passed as an input to the test function.';

--#endregion exclude_transaction
COMMIT;
