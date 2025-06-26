-- Deploy dream-db-extension-tests:table-fixture-update-valid-name to pg

BEGIN;

create function unit_test.test_table_fixture_update__valid_name()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is modified in the fixture table, and if that record's name contains any of the following
characters, then the database shall throw an exception: '/', '#', '\', carriage return, new line, tab, space.
$description$; /*'*/
declare test_data jsonb[] := array[
    '["existing_name_1", "validname", false]',
    '["existing_name_2", "valid_name_!@$%--", false]',
    '["existing_name_3", ";--", false]',
    '["existing_name_4", "invalidname/", true]',
    '["existing_name_5", "invalid/name", true]',
    '["existing_name_6", "/invalidname", true]',
    '["existing_name_7", "/", true]',
    '["existing_name_8", "//", true]',
    '["existing_name_9", "invalidname with spaces", true]',
    '["existing_name_10", "invalid  name with    tabs", true]',
    '["existing_name_11", "invalid\name", true]',
    '["existing_name_12", "invalid#name", true]',
    E'["existing_name_13", "invalid\\nname", true]',
    E'["existing_name_14", "invalid\\rname", true]'
];
declare test_datum jsonb;
begin
    -- Create a temporary function that will insert a record into the fixture table and then update its name.
    create function pg_temp.act_table_fixture_update__valid_name(args jsonb)
    returns void
    language sql
    begin atomic
        insert into fixture ("name")
        values (args->>0)
        ;
        update fixture set ("name")
        = row(args->>1)
        where "name" = args->>0
        ;
    end
    ;

    -- Update each data into the fixture table and verify that it throws an exception or lives depending on which
    -- is specified by the data.
    for test_datum in
        select d.args from unnest(test_data) d(args)
    loop
        if not (test_datum->>2)::bool then
            return query select tap.lives_ok(
                format('select pg_temp.act_table_fixture_update__valid_name(%L)', test_datum),
				format(E'%s\ntest_data: %s', test_description, test_datum)
            );
        else
            return query select tap.throws_ok(
				format('select pg_temp.act_table_fixture_update__valid_name(%L)', test_datum),
				null,
				format(E'%s\ntest_data: %s', test_description, test_datum)
			);
        end if;
    end loop
    ;
end;
$$;

COMMIT;
