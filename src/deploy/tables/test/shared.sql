-- Deploy dream-db-extension:create-test-table to pg

BEGIN;
--#region exclude_transaction

create table test
(
    id integer primary key generated always as identity,
    description text,
    parent_fixture_id integer references fixture,
    schema name not null,
    function name not null,
    unique (schema, function)
);

comment on table test is
    'Each test that can be run is listed in this table. Each test is a function, whose name is stored in this table.';
comment on column test.id is
    'The ID of the test.';
comment on column test.description is
    'The description of the test. This should be a detailed description or shall statement that describes what is being tested.';
comment on column test.parent_fixture_id is
    'The ID of the fixture that the test is included in, if any.';
comment on column test.schema is
    'The schema that the test function is found in.';
comment on column test.function is
    'The name of the test function.';


--#endregion exclude_transaction
COMMIT;
