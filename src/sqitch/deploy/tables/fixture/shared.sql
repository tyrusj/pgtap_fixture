-- Deploy dream-db-extension:create-fixutre-table to pg

BEGIN;
--#region exclude_transaction

create table fixture
(
    id integer primary key generated always as identity,
    name text not null
        check (name not similar to '%[/#\\\r\n\t ]%')
        check (length(name) != 0)
        ,
    description text,
    parent_fixture_id integer references fixture,
    startup text,
    shutdown text,
    setup text,
    teardown text,
    unique nulls not distinct (name, parent_fixture_id)
);

comment on table fixture is
    'A fixture contains tests and other fixtures that are intended to be executed as a group. A fixture specifies additional functions that are run before or after the tests and fixtures that it contains.';
comment on column fixture.id is
    'The ID of the fixture.';
comment on column fixture.name is
    $$The name of the fixture. The name cannot contain slash '/' characters, as these are used to define fixture paths. Other forbidden characters are '#', '\', carriage returns ('\r'), new lines ('\n'), tabs ('\n'), spaces (' ')$$;
comment on column fixture.description is
    'The description of the fixture.';
comment on column fixture.parent_fixture_id is
    'The ID of the fixture that contains this fixture.';
comment on column fixture.startup is 
    'The startup statement is executed before any tests or fixtures in the fixture are executed.';
comment on column fixture.shutdown is
    'The shutdown statement is executed after all tests and fixtures in the fixture are executed.';
comment on column fixture.setup is
    'The setup statement is executed before each test and fixture in the fixture.';
comment on column fixture.teardown is
    'The teardown statement is executed after each test and fixture in the fixture.';

--#endregion exclude_transaction
COMMIT;
