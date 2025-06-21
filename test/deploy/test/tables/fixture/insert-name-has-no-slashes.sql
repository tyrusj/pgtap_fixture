-- Deploy dream-db-extension-tests:table-fixture-insert-valid-name to pg

BEGIN;

create function unit_test.test_table_fixture_insert__valid_name()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is added to the fixture table, and if that record's name contains slash characters, then the
database shall throw an exception.
$description$;
declare test_data jsonb[] := array[
    '["validname", false]',
    '["valid name !@#$%--", false]',
    '[";--", false]',
    '["\\\\\\", false]',
    '["invalidname/", true]',
    '["invalid/name", true]',
    '["/invalidname", true]',
    '["/", true]',
    '["//", true]'
];
declare test_datum jsonb;
begin
    -- Create a temporary function that will insert into the fixture table
    create function pg_temp.act_table_fixture_insert__valid_name(args jsonb)
    returns void
    language sql
    begin atomic
        insert into fixture ("name")
        values (args->>0);
    end
    ;

    -- Insert each data into the fixture table and verify that it throws an exception or lives depending on which
    -- is specified by the data.
    for test_datum in
        select d.args from unnest(test_data) d(args)
    loop
        if not (test_datum->>1)::bool then
            return query select tap.lives_ok(
                format('select pg_temp.act_table_fixture_insert__valid_name(%L)', test_datum),
				format(E'%s\ntest_data: %s', test_description, test_datum)
            );
        else
            return query select tap.throws_ok(
				format('select pg_temp.act_table_fixture_insert__valid_name(%L)', test_datum),
				null,
				format(E'%s\ntest_data: %s', test_description, test_datum)
			);
        end if;
    end loop
    ;
end;
$$;

COMMIT;
