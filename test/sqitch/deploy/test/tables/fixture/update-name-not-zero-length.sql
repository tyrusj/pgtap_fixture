-- Deploy dream-db-extension-tests:table-fixture-update-name-not-zero-length to pg

BEGIN;

create function unit_test.test_table_fixture_update__name_not_zero_length()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
If a record is modified in the fixture table, and if that record's name's length is zero characters, then
the database shall throw an exception.
$description$;
declare id_to_update integer;
begin
    -- Insert a record to update
    insert into fixture ("name")
    values ('my_name')
    returning id into id_to_update
    ;

    return query select tap.throws_ok
    (
        format($throws$update fixture set ("name") = row('') where id = %s$throws$, id_to_update),
        null,
        test_description
    )
    ;
end;
$$;

COMMIT;
